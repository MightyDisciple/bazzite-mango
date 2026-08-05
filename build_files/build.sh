#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/44/x86_64/repoview/index.html&protocol=https&redirect=1

# Keep the custom image deliberately small. Noctalia v5 is packaged in the
# official Fedora repositories from Fedora 44 onward, so Terra is neither
# needed nor enabled in the resulting image.
dnf5 -y copr enable jdxcode/mise

# Unity distributes Unity Hub through its own signed RPM repository. Keep the
# repository available only while building the image.
install -Dm644 /ctx/repos/unityhub.repo \
  /etc/yum.repos.d/unityhub.repo

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
  pipewire-libs \
  unityhub

# Keep third-party repositories disabled in the resulting system image.
dnf5 -y copr disable jdxcode/mise
rm -f /etc/yum.repos.d/unityhub.repo

# Fail the image build early if either application is missing.
test -x /usr/bin/blender
test -x /usr/bin/unityhub

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
