{
  description = "hello world application using uv2nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    pyproject-nix,
    uv2nix,
    pyproject-build-systems,
    ...
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    inherit (nixpkgs) lib;
    forAllSystems = lib.genAttrs systems;

    # Parse pyproject.toml
    projectName = (builtins.fromTOML (builtins.readFile ./pyproject.toml)).project.name;

    workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

    overlay = workspace.mkPyprojectOverlay {
      sourcePreference = "wheel";
    };

    editableOverlay = workspace.mkEditablePyprojectOverlay {
      root = "$REPO_ROOT";
    };

    pythonSets = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python314;
      in
        (pkgs.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope
        (
          lib.composeManyExtensions [
            pyproject-build-systems.overlays.wheel
            overlay
          ]
        )
    );
  in {
    devShells = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonSet = pythonSets.${system}.overrideScope editableOverlay;
        virtualenv = pythonSet.mkVirtualEnv "${projectName}-dev-env" workspace.deps.all;
      in {
        default = pkgs.mkShell {
          packages = [
            virtualenv
            pkgs.uv
          ];
          env = {
            UV_NO_SYNC = "1";
            UV_PYTHON = pythonSet.python.interpreter;
            UV_PYTHON_DOWNLOADS = "never";
          };
          shellHook = ''
            unset PYTHONPATH
            export REPO_ROOT=$(git rev-parse --show-toplevel)
          '';
        };
      }
    );

    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      virtualenv = pythonSets.${system}.mkVirtualEnv "${projectName}-env" workspace.deps.default;

      src = pkgs.stdenv.mkDerivation {
        name = "manage";
        src = ./src;
        buildInputs = [virtualenv];
        installPhase = ''
          mkdir -p $out/app
          cp -r $src/* $out/app/
          chmod +x $out/app/manage.py
        '';
      };
      entrypoint = pkgs.writeShellApplication {
        name = "entrypoint";
        runtimeInputs = [virtualenv];
        text = ''
          echo "Collecting static files..."
          python manage.py collectstatic --noinput --clear

          echo "Applying database migrations..."
          python manage.py migrate --noinput

          echo "Starting Gunicorn..."
          gunicorn main.wsgi:application \
              --bind 0.0.0.0:8000 \
              --workers 3 \
              --log-level=info
        '';
      };
    in {
      inherit virtualenv;
      default = pkgs.dockerTools.buildLayeredImage {
        name = "wagtail-container";
        contents = [pkgs.curl pkgs.busybox src];
        enableFakechroot = true;
        fakeRootCommands = ''
          #!${pkgs.runtimeShell}
          ${pkgs.dockerTools.shadowSetup}
          groupadd -r wagtail
          useradd -r -g wagtail wagtail
          mkdir -p /app
          mkdir -p /data/static
          mkdir -p /data/media
          chown -R wagtail:wagtail /app
          chown -R wagtail:wagtail /data
        '';
        config = {
          Entrypoint = ["${entrypoint}/bin/entrypoint"];
          WorkingDir = "/app";
          Volumes = {"/data" = {};};
          User = "wagtail";
          ExposedPorts = {"8000/tcp" = {};};
          Env = [
            "PORT=8000"
            "PYTHONUNBUFFERED=1"
            "PYTHONDONTWRITEBYTECODE=1"
            "DATA_DIR=/data"
          ];
          Healthcheck = {
            Test = ["CMD-SHELL" "curl -f http://localhost:8000/ || exit 1"];
          };
        };
      };
    });
  };
}
