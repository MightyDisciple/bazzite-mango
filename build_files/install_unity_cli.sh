#!/bin/bash

set -ouex pipefail

INSTALLER="$(mktemp)"
trap 'rm -f "$INSTALLER"' EXIT

curl -fsSL \
  "https://public-cdn.cloud.unity3d.com/hub/prod/cli/install.sh" \
  -o "$INSTALLER"

# Unity CLI is currently distributed through the beta channel. Install it in
# /usr/bin as part of the immutable image. /usr/local is a symlink to mutable
# storage on Bazzite and its target is unavailable during the image build.
UNITY_CLI_CHANNEL=beta \
UNITY_CLI_HOME=/usr \
SHELL=/bin/false \
  bash "$INSTALLER"

# The installer creates shell environment helpers for custom install roots.
# They are unnecessary because /usr/bin is already on every user's PATH.
rm -f /usr/env /usr/env.fish

test -x /usr/bin/unity
