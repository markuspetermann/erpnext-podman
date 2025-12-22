# ERPNext Build and Deployment Toolkit

The tools in this repo can be used to build and deploy a custom Frappe/ERPNext image. This setup has been tailored for Debian Trixie and runs using a rootless Podman pod. The ERPNext image is based on the v15 Containerfile found in the [official ERPNext Docker image repository](https://github.com/frappe/erpnext-docker). The pod will be accessible via HTTP; if it is exposed to the network, use a reverse proxy with TLS termination (or similar) to secure the connection.

## Create ERPNext User

* The scripts currently assume the system user `erpnext`. The home directory can be chosen freely; this documentation suggests `/srv/erpnext`

```bash
$ sudo adduser --system --group --home /srv/erpnext erpnext
$ sudo loginctl enable-linger erpnext
```

## Clone Deployment Toolkit

```bash
# Clone this repository
$ cd /srv/erpnext && sudo -u erpnext git clone https://github.com/markuspetermann/erpnext-podman.git

# Ensure the deployment scripts are executable
$ chmod ug+x /srv/erpnext/erpnext-podman/deploy/*.sh
```

## Install ERPNext

* Copy `/srv/erpnext/erpnext-podman/deploy/.env.erpnext.example` to `/srv/erpnext/.env.erpnext` and edit as needed
* Edit `/srv/erpnext/erpnext-podman/deploy/apps.json` to include the apps you want to install

```bash
$ cd /srv/erpnext/erpnext-podman/deploy
$ sudo -u erpnext ./build.sh
$ sudo -u erpnext ./install.sh
```

## Backups

* Backups run automatically daily at 2:00 AM
* Backups are stored in `/srv/erpnext/data/sites/{FRAPPE_SITE_NAME_HEADER}/private/backups`
* By default, Frappe keeps the three most recent backups and removes older ones automatically. This can be changed in the System Configuration UI
* Use `backup.sh` to create a backup manually

## Notes

* Automatic updates are not configured. The MariaDB and Valkey images need to be pulled manually. The ERPNext image needs to be rebuilt manually using `build.sh`
* After re-running `build.sh`, the new image will be used after the next restart of `erpnext-pod.service`
* `bench.sh` is a convenience wrapper for `bench` inside the backend container
* `systemctl.sh` is a convenience wrapper for `systemctl --user` that sets the required environment variables

## TODO

* Add Apache 2 reverse proxy example config with TLS?
* Add auto-update?
