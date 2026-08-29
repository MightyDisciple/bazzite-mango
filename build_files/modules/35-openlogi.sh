#!/bin/bash

set -ouex pipefail

readonly openlogi_version='0.8.1'
readonly openlogi_rpm="openlogi-v${openlogi_version}-linux-amd64.rpm"
readonly openlogi_url="https://github.com/AprilNEA/OpenLogi/releases/download/v${openlogi_version}/${openlogi_rpm}"
readonly openlogi_sha256='23aff73ee8ab6a2f9d340ad259ea3935177ee81fcd6596b231288027098f2d09'
readonly openlogi_download="/tmp/${openlogi_rpm}"
readonly -a curl_options=(
  --fail
  --http1.1
  --location
  --retry 5
  --retry-all-errors
  --retry-delay 2
)

curl "${curl_options[@]}" --output "${openlogi_download}" "${openlogi_url}"
printf '%s  %s\n' "${openlogi_sha256}" "${openlogi_download}" \
  | sha256sum --check --strict

# The upstream scriptlet reloads the live host's udev daemon, which is not
# available while building a bootc image. All persistent payload files are in
# the RPM, so skip scriptlets and let udev load the rules after deployment.
dnf5 install -y --setopt=tsflags=noscripts "${openlogi_download}"
rm -f "${openlogi_download}"

rpm -q openlogi
for executable in openlogi openlogi-agent openlogi-desktop openlogi-overlay; do
  test -x "/usr/bin/${executable}"
done
test -f /etc/udev/rules.d/70-openlogi.rules
test -f /usr/lib/systemd/user/openlogi-agent.service
test -f /usr/share/applications/openlogi.desktop
