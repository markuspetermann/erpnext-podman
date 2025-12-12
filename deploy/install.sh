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

echo "Creating data directories..."
mkdir -p ~/data/mariadb
mkdir -p ~/data/valkey
mkdir -p ~/data/sites
mkdir -p ~/data/logs

echo "Installing Systemd Units..."
mkdir -p ~/.config/containers/systemd/
mkdir -p ~/.config/systemd/user/

cp $(pwd)/systemd/*.pod ~/.config/containers/systemd/
cp $(pwd)/systemd/*.container ~/.config/containers/systemd/
cp $(pwd)/systemd/*.service ~/.config/systemd/user/
cp $(pwd)/systemd/*.timer ~/.config/systemd/user/

echo "Reloading Systemd..."
systemctl --user daemon-reload

echo "Starting ERPNext Pod..."
systemctl --user start erpnext-pod.service

echo "Status:"
systemctl --user status erpnext-pod.service --no-pager

echo "Waiting 30 seconds for services to stabilize..."
sleep 30

SITE_DIR=~/data/sites/$FRAPPE_SITE_NAME_HEADER

if [ ! -d "$SITE_DIR" ]; then
	echo "Site '$FRAPPE_SITE_NAME_HEADER' not found. Creating new site..."
	
	if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
		echo "Error: MYSQL_ROOT_PASSWORD is not set in .env.erpnext"
		exit 1
	fi

	podman exec systemd-erpnext-backend bench new-site $FRAPPE_SITE_NAME_HEADER \
		--mariadb-user-host-login-scope='%' \
		--db-root-username "root" \
		--db-root-password "$MYSQL_ROOT_PASSWORD" \
		--admin-password "admin" \
		--install-app erpnext \
		--install-app hrms \
		--install-app erpnext_germany \
		--install-app eu_einvoice \
		--install-app pdf_on_submit \
		--verbose
	
	echo "----------------------------------------------------------------"
	echo "Site '$FRAPPE_SITE_NAME_HEADER' created successfully!"
	echo "URL: http://localhost:${FRONTEND_PORT}"
	echo "Login: Administrator"
	echo "Password: admin"
	echo "----------------------------------------------------------------"
else
	echo "Site '$FRAPPE_SITE_NAME_HEADER' already exists. Skipping creation..."
fi

echo "Enabling automatic backups..."
systemctl --user enable --now erpnext-backup.timer

echo "Status:"
systemctl --user status erpnext-backup.timer --no-pager

echo "Done!"
