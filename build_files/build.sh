#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Keep the custom image deliberately small. Noctalia v5 and OpenRGB are
# packaged in Fedora 44. CoolerControl comes from Terra; keep that repository
# disabled in the deployed image and enable it only for this image build.
dnf5 -y copr enable jdxcode/mise

# The Bazzite DX base image includes Visual Studio Code. Replace it with Zed
# so the remote editor is managed as part of the image instead of as a local
# rpm-ostree override. Zed is provided by Bazzite's existing Terra repository.
dnf5 remove -y code

dnf5 install -y \
  blender \
  borgbackup \
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

# Vorta provides the desktop interface for configuring, scheduling, browsing,
# and restoring Borg backups. Keep Borg itself installed for recovery use.
dnf5 install -y vorta

# Keep Fedora's rules package for package integration, but replace its RC2 rule
# with the matching upstream RC3 release below. The similarly named "openrgb"
# package in ublue-os/akmods pulls in a stale akmod-openrgb and must not be
# installed in this bootc stage. Our USB controllers do not need that module.
dnf5 install -y \
  --disable-repo='copr:copr.fedorainfracloud.org:ublue-os:akmods' \
  openrgb-udev-rules

# Pin the current upstream userspace release. This keeps the image
# reproducible while providing newer MSI X870 support than Bazzite's ujust
# OpenRGB AppImage. Updating requires changing both URL and SHA-256.
openrgb_url='https://codeberg.org/OpenRGB/OpenRGB/releases/download/release_candidate_1.0rc3/OpenRGB_1.0rc3_x86_64_6fbcf62.AppImage'
openrgb_sha256='37f25ecb9c0f52cd3b916d760c1df61a8b372c8b124115555200fe6dfe56f2a0'
openrgb_rules_url='https://codeberg.org/OpenRGB/OpenRGB/releases/download/release_candidate_1.0rc3/60-openrgb.rules'
openrgb_rules_sha256='cae379493ba85f69f864d5699f320f7db0546b733c4410a0aab7040b97b55bbf'
openrgb_effects_url='https://codeberg.org/OpenRGB/OpenRGBEffectsPlugin/releases/download/release_candidate_1.0rc2/OpenRGBEffectsPlugin_1.0rc2_Linux_amd64_415dc20.so'
openrgb_effects_sha256='2f3c2b3c2c850e7148b4aa459bd41ccf9c56bd26fd00809fa19126ac5ad8dbc0'
install -d /usr/libexec/openrgb/plugins
curl_options=(
  --fail
  --http1.1
  --location
  --retry 5
  --retry-all-errors
  --retry-delay 2
)
curl "${curl_options[@]}" --output /usr/libexec/openrgb/OpenRGB.AppImage "${openrgb_url}"
echo "${openrgb_sha256}  /usr/libexec/openrgb/OpenRGB.AppImage" | sha256sum --check --strict
chmod 0755 /usr/libexec/openrgb/OpenRGB.AppImage
curl "${curl_options[@]}" --output /usr/lib/udev/rules.d/60-openrgb.rules "${openrgb_rules_url}"
echo "${openrgb_rules_sha256}  /usr/lib/udev/rules.d/60-openrgb.rules" | sha256sum --check --strict
curl "${curl_options[@]}" --output /usr/libexec/openrgb/plugins/OpenRGBEffectsPlugin.so "${openrgb_effects_url}"
echo "${openrgb_effects_sha256}  /usr/libexec/openrgb/plugins/OpenRGBEffectsPlugin.so" | sha256sum --check --strict

dnf5 install -y --enable-repo=terra \
  coolercontrol \
  liquidctl \
  zed

dnf5 -y copr disable jdxcode/mise

# Fail the image build early when a requested component is missing.
rpm -q \
  blender \
  borgbackup \
  coolercontrol \
  liquidctl \
  mise \
  niri \
  noctalia \
  openrgb-udev-rules \
  vorta \
  zed
! rpm -q code
test -x /usr/bin/blender
test -x /usr/bin/coolercontrol
test -x /usr/bin/openrgb

test -x /usr/libexec/mightydisciple-flatpaks
command -v zed
command -v borg
command -v vorta

# Looking Glass is built in a separate Containerfile stage. Verify that its
# client and all runtime libraries made it into the final image.
test -x /usr/bin/looking-glass-client
! ldd /usr/bin/looking-glass-client | grep -q 'not found'

systemctl enable podman.socket
systemctl enable coolercontrold.service
systemctl enable mightydisciple-flatpaks.service
systemctl is-enabled mightydisciple-flatpaks.service
