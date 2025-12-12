#!/bin/bash

set -euo pipefail

[ "$(id -un)" = "erpnext" ] || {
	echo "This script must be run as 'erpnext'" >&2
	exit 1
}

USERID=$(id -u $USER)

export XDG_RUNTIME_DIR=/run/user/$USERID
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

source ~/.env.erpnext

SITE_DIR=~/data/sites/$FRAPPE_SITE_NAME_HEADER

if [ ! -d "$SITE_DIR" ]; then
	echo "Error: Site '$FRAPPE_SITE_NAME_HEADER' not found."
	exit 1
else
    podman exec systemd-erpnext-backend bench --site $FRAPPE_SITE_NAME_HEADER \
        backup --with-files --compress

    echo "Backup done"
fi
