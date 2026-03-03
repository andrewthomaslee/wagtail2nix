# wagtail2nix template
This is a template for creating a [`Wagtail CMS`](https://github.com/wagtail/wagtail) + `PostgreSQL` project using `Nix` for CI/CD.


# Development
## Requirements
* [Docker](https://docs.docker.com/engine/install/)


This devcontainer uses `Docker outside of Docker` which assumes you have Docker installed and running on your host machine with the Docker Daemon accessible at `/var/run/docker.sock`.


### One of the following
* [VSCode devcontainers extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-containers)  ( recommended )


or


* [devcontainer CLI](https://github.com/devcontainers/cli)  ( for CLI power users )


or


* [Nix](https://nixos.org/download/) package manager + [Flakes](https://nix.dev/concepts/flakes.html) enabled ( for Nix power users )


### VSCode Usage
1. Clone this repo
2. Open the repo in VSCode
3. Open the Command Palette (Ctrl+Shift+P)
4. Select `Reopen in Container`


### devcontainer CLI Usage
Start the Container:
```bash
devcontainer up --workspace-folder .
```

Execute a Command in the Container:
```bash
devcontainer exec --workspace-folder . nix develop
```

### Nix Usage
```bash
nix develop .#pure
```

## Docker Compose
To start wagtail and postgres containers for local development:

```bash
docker compose -f compose.yaml -f compose.dev.yaml up
```

# Deployment
This template uses `Docker Compose` for deployment and or `Kubernetes` for production.

## Docker Compose
To start wagtail and postgres containers for production:

```bash
docker compose -f compose.yaml -f compose.override.yaml up -d
```

## Kubernetes (WORK IN PROGRESS)
To start wagtail and postgres containers for production:

```bash
kubectl apply -f ./manifests
```
