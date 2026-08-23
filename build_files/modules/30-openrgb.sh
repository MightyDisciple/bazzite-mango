#!/bin/bash

set -ouex pipefail

# Keep Fedora's rules integration, but replace its RC2 rule with the matching
# upstream RC3 file. Avoid ublue-os/akmods' stale akmod-openrgb dependency.
dnf5 install -y \
  --disable-repo='copr:copr.fedorainfracloud.org:ublue-os:akmods' \
  openrgb-udev-rules

readonly openrgb_url='https://codeberg.org/OpenRGB/OpenRGB/releases/download/release_candidate_1.0rc3/OpenRGB_1.0rc3_x86_64_6fbcf62.AppImage'
readonly openrgb_sha256='37f25ecb9c0f52cd3b916d760c1df61a8b372c8b124115555200fe6dfe56f2a0'
readonly openrgb_rules_url='https://codeberg.org/OpenRGB/OpenRGB/releases/download/release_candidate_1.0rc3/60-openrgb.rules'
readonly openrgb_rules_sha256='cae379493ba85f69f864d5699f320f7db0546b733c4410a0aab7040b97b55bbf'
readonly openrgb_effects_url='https://codeberg.org/OpenRGB/OpenRGBEffectsPlugin/releases/download/release_candidate_1.0rc2/OpenRGBEffectsPlugin_1.0rc2_Linux_amd64_415dc20.so'
readonly openrgb_effects_sha256='2f3c2b3c2c850e7148b4aa459bd41ccf9c56bd26fd00809fa19126ac5ad8dbc0'
readonly -a curl_options=(
  --fail
  --http1.1
  --location
  --retry 5
  --retry-all-errors
  --retry-delay 2
)

download_verified() {
  local url=$1 sha256=$2 destination=$3

  curl "${curl_options[@]}" --output "${destination}" "${url}"
  printf '%s  %s\n' "${sha256}" "${destination}" | sha256sum --check --strict
}

install -d /usr/libexec/openrgb/plugins
download_verified "${openrgb_url}" "${openrgb_sha256}" \
  /usr/libexec/openrgb/OpenRGB.AppImage
chmod 0755 /usr/libexec/openrgb/OpenRGB.AppImage
download_verified "${openrgb_rules_url}" "${openrgb_rules_sha256}" \
  /usr/lib/udev/rules.d/60-openrgb.rules
download_verified "${openrgb_effects_url}" "${openrgb_effects_sha256}" \
  /usr/libexec/openrgb/plugins/OpenRGBEffectsPlugin.so
