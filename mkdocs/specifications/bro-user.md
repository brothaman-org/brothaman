# Specification: `bro-user` CLI Program

The `bro-user` CLI program, as a bash script, is part of the Brothaman scripts package which creates new system accounts for unprivileged containers to run under. It is installed using the `bro-install` script or the `brothaman-scripts` Debian package.

>**ATTENTION**: The brothaman-scripts package is has a hard dependency on ZFS and zfs-utils being installed on the host system. It also has a hard dependency on the `zfs-helper` debian package to allow unprivileged users to run delegated zfs commands without root privileges.

* If the path `/var/lib/containers/unprivileged` exists, the `bro-user` script creates a new user account under this base directory for unprivileged Podman containers.
  * If the path does not exist, it fails with an error.
  * Installation of the `brothaman-scripts` Debian package MUST create this base unprivileged user directory directory at `/var/lib/containers/unprivileged` backed by a ZFS dataset with appropriate properties and permissions.
* The created user account is in /etc/subuid and /etc/subgid with an exclusive (non-overlapping) range allocation of 65536 UIDs and GIDs assigned for rootless Podman containers.
* The created user account's home directory will be `/var/lib/containers/unprivileged/${USERNAME}`, where `USERNAME` is the first argument passed to the `bro-user` script. It too is backed by a ZFS dataset with appropriate properties and permissions assigned to the new user.
* Note that the home directory path may already be created as a ZFS dataset so the `bro-user` script will use the existing dataset as the home directory for the created user account without creating a new home directory.
* If the user account already exists, the `bro-user` script does nothing and exits with an error.
* The created user account is added to the `zfshelper` group to allow the zfs-helper to run delegated commands without root privileges for this user. The `zfs-helper` package is a hard dependency for the brothaman scripts.
* The created user account is configured for systemd user lingering to allow user services to run even when the user is not logged in.
* The created user account is configured with a default umask of `0027` to provide secure file permissions by default.
* The created user account is configured with a default shell of `/bin/bash`.
* The `bro-user` script requires root privileges to run.
* The created user account is intended to be used as the owner of rootless Podman containers managed via systemd user services and quadlets and should have the basic XDG directories created in its home directory for this purpose: `~/.config`, `~/.config/containers`, `~/.config/containers/systemd`, `~/.config/systemd`, `~/.config/systemd/user`, `~/.local/share/containers`, `~/.local/share/containers/storage` (the graphroot), and `~/.local/share/systemd`.
* The `bro-user` script does not set a password for the created user account. Password management is left to the system administrator.
* The `bro-user` script does not configure SSH access for the created user account. SSH configuration is left to the system administrator.
* The `bro-user` script forbids sudo access for the created user account. The whole point is to run unprivileged containers without elevated privileges and protect against privilege escalation.
* The skeleton files for the created user account are copied from `/etc/skel` as usual.
* The `bro-user` script does not configure any additional user account settings beyond those listed here.
* The `bro-user` script supports the following command line options:
  * `--system-user`: Create the user account as a system user with no login shell (`/usr/sbin/nologin`).
  * `--network-cmd VALUE`: Override the default Podman `network_cmd`. Defaults to `none`, but you can set it to any supported backend (e.g., `slirp4netns`, `pasta --config …`, `none`).
  * `--help`: Display help information about the script usage.
  * `--version`: Display the version of the `bro-user` script.
  * `USERNAME`: The username of the user account to create (positional argument).
  * `--remove`: Remove the specified user account and its home directory while stopping any running user services and containers for that account.
* The `bro-user` script can be extended in the future to support additional features as needed.
* The `bro-user` script is intended to be used by system administrators to create and manage unprivileged user accounts for running rootless Podman containers in a secure and isolated manner.
* The `bro-user` script is part of the Brothaman project and is licensed under the ASL 2.0 License.
* The `bro-user` script is maintained as part of the Brothaman scripts package and should be kept up to date with the latest features and security patches.
* The proper podman configurations are created in the appropriate files under XDG paths. By default container networking is disabled (`network_cmd = "none"`), keeping new users isolated unless they opt into a specific backend.
* The `bro-user` script creates a per-user `containers.conf` file under `~/.config/containers/containers.conf`. It contains the following settings by default to optimize for unprivileged rootless containers:
  * `network_cmd = "none"`: Configures the default networking backend to `none`, keeping containers isolated unless explicitly overridden (e.g., by `--network-cmd` or quadlet `Network=` directives).
  * `storage_driver = "overlay"`: Sets the storage driver for containers to `overlay`, which is suitable for most use cases and provides good performance.
  * `storage_options = ["overlay.mountopt=nodev"]`: Adds the `nodev` mount option to the overlay storage driver to enhance security by preventing device files from being created within container filesystems.
