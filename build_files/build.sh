#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/44/x86_64/repoview/index.html&protocol=https&redirect=1

# Keep the custom image deliberately small. Noctalia v5 and OpenRGB are
# packaged in Fedora 44. CoolerControl comes from Terra; keep that repository
# disabled in the deployed image and enable it only for this image build.
dnf5 -y copr enable jdxcode/mise

dnf5 install -y \
  blender \
  fontconfig \
  libdecor \
  libglvnd-egl \
  libsamplerate \
  libxkbcommon \
  mise \
  nettle \
  niri \
  noctalia \
  pipewire-libs

# Install only OpenRGB's device permissions from Fedora. The similarly named
# package in ublue-os/akmods pulls in a stale akmod-openrgb and tries to compile
# a kernel module inside the bootc build. Our USB controllers do not need it.
dnf5 install -y \
  --disable-repo='copr:copr.fedorainfracloud.org:ublue-os:akmods' \
  openrgb-udev-rules

# Pin the current upstream userspace release. This keeps the image
# reproducible while providing newer MSI X870 support than Bazzite's ujust
# OpenRGB AppImage. Updating requires changing both URL and SHA-256.
openrgb_url='https://codeberg.org/OpenRGB/OpenRGB/releases/download/release_candidate_1.0rc3/OpenRGB_1.0rc3_x86_64_6fbcf62.AppImage'
openrgb_sha256='37f25ecb9c0f52cd3b916d760c1df61a8b372c8b124115555200fe6dfe56f2a0'
install -d /usr/libexec/openrgb
curl --fail --location --retry 3 --output /usr/libexec/openrgb/OpenRGB.AppImage "${openrgb_url}"
echo "${openrgb_sha256}  /usr/libexec/openrgb/OpenRGB.AppImage" | sha256sum --check --strict
chmod 0755 /usr/libexec/openrgb/OpenRGB.AppImage

dnf5 install -y --enable-repo=terra \
  coolercontrol \
  liquidctl

dnf5 -y copr disable jdxcode/mise

# Fail the image build early if Blender is missing.
test -x /usr/bin/blender

# Keep cooling and RGB control part of the image instead of rpm-ostree layers.
rpm -q coolercontrol liquidctl openrgb-udev-rules
test -x /usr/bin/coolercontrol
test -x /usr/bin/openrgb

# Looking Glass is built in a separate Containerfile stage. Verify that its
# client and all runtime libraries made it into the final image.
test -x /usr/bin/looking-glass-client
! ldd /usr/bin/looking-glass-client | grep -q 'not found'

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
systemctl enable coolercontrold.service
