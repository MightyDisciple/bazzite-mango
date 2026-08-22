# Looking Glass is compiled daily in its dedicated repository. This image only
# imports the small, prebuilt Fedora 44 artifact.
FROM ghcr.io/mightydisciple/looking-glass-client-artifact:b7-fedora44 AS looking-glass-artifact

FROM scratch AS image-ctx
COPY build_files/build.sh /
COPY system_files /system_files

FROM ghcr.io/ublue-os/bazzite-gnome-nvidia:stable AS base

FROM base
COPY --from=looking-glass-artifact /usr/ /usr/

RUN --mount=type=bind,from=image-ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN bootc container lint
