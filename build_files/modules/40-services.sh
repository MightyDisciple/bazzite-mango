#!/bin/bash

set -ouex pipefail

systemctl enable podman.socket
systemctl enable docker.socket
systemctl enable bazzite-dx-groups.service
systemctl enable coolercontrold.service
systemctl enable mightydisciple-flatpaks.service
