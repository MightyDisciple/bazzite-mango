#!/bin/bash

# Unity CLI beta checks free space on composefs / instead of the configured
# Editor path. Report the writable home filesystem for that specific query.
export LD_PRELOAD="/usr/lib64/unity-cli-statfs-compat.so${LD_PRELOAD:+:$LD_PRELOAD}"

exec /usr/libexec/unity-cli/bin/unity "$@"
