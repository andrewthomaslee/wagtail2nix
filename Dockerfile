FROM nixos/nix:latest AS builder

COPY . /tmp/build
WORKDIR /tmp/build

RUN nix \
    --extra-experimental-features "nix-command flakes" \
    --option filter-syscalls false \
    build .#package

RUN mkdir /tmp/nix-store-closure
RUN cp -R $(nix-store -qR result/) /tmp/nix-store-closure


# Build the final image
FROM alpine:latest

RUN addgroup -S wagtail && \
    adduser -S -G wagtail wagtail && \
    mkdir -p /app && \
    mkdir -p /data/static && \
    mkdir -p /data/media && \
    chown -R wagtail:wagtail /app && \
    chown -R wagtail:wagtail /data

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000 \
    DATA_DIR=/data
    DJANGO_SETTINGS_MODULE=main.settings.production

RUN apk add --no-cache curl

EXPOSE 8000

WORKDIR /app

# Copy Nix Closure
COPY --from=builder /tmp/nix-store-closure /nix/store
COPY --from=builder /tmp/build/result /

HEALTHCHECK --interval=60s --timeout=5s --start-period=20s --retries=5 CMD curl -f http://0.0.0.0:8000/ || exit 1
ENTRYPOINT ["/bin/entrypoint"]