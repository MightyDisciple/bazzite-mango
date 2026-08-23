#!/bin/bash

set -ouex pipefail

# Keep optional repositories scoped to the transactions that require them.
dnf5 -y copr enable jdxcode/mise

# Zed replaces Code. Mango provides its own XWayland integration, so the old
# Niri session and xwayland-satellite must not remain in the image.
dnf5 remove -y \
  code \
  niri \
  xwayland-satellite

dnf5 install -y \
  blender \
  borgbackup \
  fontconfig \
  fuse-sshfs \
  glib2 \
  jq \
  kde-connect \
  libdecor \
  libglvnd-egl \
  libsamplerate \
  libxkbcommon \
  mise \
  nettle \
  noctalia \
  pipewire-libs \
  vorta \
  xorg-x11-server-Xwayland

# Terra is enabled only for packages not supplied by the base repositories.
dnf5 install -y --enable-repo=terra \
  coolercontrol \
  liquidctl \
  mangowm \
  xdg-desktop-portal-wlr \
  zed

# The repository definition and key are supplied through system_files/.
dnf5 install -y chatgpt

dnf5 -y copr disable jdxcode/mise
