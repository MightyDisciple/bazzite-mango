#!/bin/bash

set -ouex pipefail

INSTALLER="$(mktemp)"
trap 'rm -f "$INSTALLER"' EXIT

curl -fsSL \
  "https://public-cdn.cloud.unity3d.com/hub/prod/cli/install.sh" \
  -o "$INSTALLER"

# Unity CLI is currently distributed through the beta channel. Install it
# system-wide so every user can run `unity`, while Editors and user data stay
# in the user's writable home directory.
UNITY_CLI_CHANNEL=beta \
UNITY_CLI_HOME=/usr/local \
  bash "$INSTALLER"

test -x /usr/local/bin/unity

