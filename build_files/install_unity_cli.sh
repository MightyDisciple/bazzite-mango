#!/bin/bash

set -ouex pipefail

INSTALLER="$(mktemp)"
trap 'rm -f "$INSTALLER"' EXIT

curl -fsSL \
  "https://public-cdn.cloud.unity3d.com/hub/prod/cli/install.sh" \
  -o "$INSTALLER"

# Keep the vendor binary separate from the wrapper that applies Bazzite's
# composefs disk-space compatibility fix.
UNITY_CLI_CHANNEL=beta \
UNITY_CLI_HOME=/usr/libexec/unity-cli \
SHELL=/bin/false \
  bash "$INSTALLER"

rm -f \
  /usr/libexec/unity-cli/env \
  /usr/libexec/unity-cli/env.fish

chmod 755 /usr/libexec/unity-cli/bin/unity
install -Dm755 /ctx/unity-wrapper.sh /usr/bin/unity

test -x /usr/bin/unity
