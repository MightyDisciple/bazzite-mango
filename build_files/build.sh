#!/bin/bash

set -ouex pipefail

# Overlay repository-owned files before modules enable their systemd units.
cp -avf /ctx/system_files/. /

for module in /ctx/build_files/modules/*.sh; do
  echo "Running image build module: ${module##*/}"
  bash "${module}"
done
