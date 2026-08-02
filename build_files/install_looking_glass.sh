#!/bin/bash

set -ouex pipefail

# Pin the stable B7 release so image builds remain reproducible.
readonly LOOKING_GLASS_COMMIT="27fe47cbe2a3a8da986d310ab866f0b646ed68f5"
readonly SOURCE_DIR="/tmp/looking-glass"
readonly BUILD_DIR="${SOURCE_DIR}/client/build"

readonly BUILD_PACKAGES=(
  binutils-devel
  cmake
  fontconfig-devel
  gcc
  gcc-c++
  git-core
  libdecor-devel
  libglvnd-devel
  libsamplerate-devel
  libxkbcommon-devel
  make
  nettle-devel
  pipewire-devel
  pkgconf-pkg-config
  spice-protocol
  wayland-devel
  wayland-protocols-devel
)

dnf5 install -y "${BUILD_PACKAGES[@]}"

git clone --filter=blob:none --no-checkout \
  https://github.com/gnif/LookingGlass.git "${SOURCE_DIR}"
git -C "${SOURCE_DIR}" checkout --detach "${LOOKING_GLASS_COMMIT}"
git -C "${SOURCE_DIR}" submodule update --init --recursive --depth 1

cmake \
  -S "${SOURCE_DIR}/client" \
  -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-Wno-error=maybe-uninitialized" \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DENABLE_WAYLAND=1 \
  -DENABLE_X11=0 \
  -DENABLE_PULSEAUDIO=0 \
  -DENABLE_PIPEWIRE=1

cmake --build "${BUILD_DIR}" --parallel "$(nproc)"
DESTDIR=/out cmake --install "${BUILD_DIR}"

test -x /out/usr/bin/looking-glass-client
