# Isolate build inputs from the final image.
FROM scratch AS looking-glass-ctx
COPY build_files/install_looking_glass.sh /

FROM scratch AS image-ctx
COPY build_files/build.sh /
COPY system_files /system_files

FROM ghcr.io/ublue-os/bazzite-dx-nvidia-gnome:stable AS base

FROM base AS looking-glass-builder
RUN --mount=type=bind,from=looking-glass-ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/install_looking_glass.sh

FROM base
COPY --from=looking-glass-builder /out/ /

RUN --mount=type=bind,from=image-ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN bootc container lint
