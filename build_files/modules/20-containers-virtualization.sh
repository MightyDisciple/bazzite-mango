#!/bin/bash

set -ouex pipefail

# Recreate Bazzite DX's development and virtualization tooling on top of the
# regular Bazzite GNOME NVIDIA image.
dnf5 config-manager addrepo \
  --from-repofile='https://download.docker.com/linux/fedora/docker-ce.repo'
dnf5 config-manager setopt docker-ce-stable.enabled=0

dnf5 --setopt=install_weak_deps=False install -y \
  edk2-ovmf \
  guestfs-tools \
  libvirt \
  qemu \
  qemu-kvm \
  virt-manager

dnf5 install -y --enable-repo=docker-ce-stable \
  containerd.io \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin

# Required for Docker-in-Docker and devcontainer networking.
install -d /etc/modules-load.d
printf 'iptable_nat\n' > /etc/modules-load.d/ip_tables.conf
