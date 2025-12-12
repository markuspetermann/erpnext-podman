#!/bin/bash

set -euo pipefail

[ "$(id -un)" = "erpnext" ] || {
	echo "This script must be run as 'erpnext'" >&2
	exit 1
}

USERID=$(id -u $USER)

export XDG_RUNTIME_DIR=/run/user/$USERID
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

podman build \
	--build-arg APPS_JSON_BASE64=$(base64 -w 0 apps.json) \
	-t erpnext-custom:version-15 \
	-f Containerfile ..

podman image prune --build-cache -f
