#!/bin/bash

set -ouex pipefail

systemctl enable podman.socket
systemctl enable docker.socket
systemctl enable bazzite-mango-groups.service
systemctl enable coolercontrold.service
systemctl enable mightydisciple-flatpaks.service
