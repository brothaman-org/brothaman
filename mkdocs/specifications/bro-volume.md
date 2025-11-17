# Specification: `bro-volume` CLI Program

The `bro-volume` CLI program, as a bash script, is part of the Brothaman scripts package which creates ZFS backed volumes for unprivileged containers. It is installed using the `bro-install` script or the `brothaman-scripts` Debian package.

>**ATTENTION**: The brothaman-scripts package is has a hard dependency on ZFS and zfs-utils being installed on the host system. It also has a hard dependency on the `zfs-helper` debian package to allow unprivileged users to run delegated zfs commands without root privileges.

* The `bro-volume` script requires root privileges to run.
* The `bro-volume` script creates a ZFS dataset for use as a Podman volume for unprivileged rootless containers. When container UID/GID overrides are provided it also applies POSIX ACLs (via `setfacl`) so the unprivileged owner retains access to the mountpoint even though ownership is shifted to the container user.
* The created ZFS dataset is owned by the specified unprivileged user account that will run the container using the volume.
* The created ZFS dataset has appropriate ZFS properties set for use as a Podman volume, including compression and atime settings.
* The created ZFS dataset is mounted at the specified mount point for use as a Podman volume quadlet.
* The `bro-volume` script supports the following command line options:
  * `--name NAME`: The name of the volume (ZFS dataset name) required.
  * `--mount-point PATH`: The mount point for the volume defaults to `/var/lib/containers/unprivileged/USERNAME/volumes/NAME` where USERNAME is the owner user.
  * `--container CONTAINER_NAME`: The name of the container quadlet that will use this volume (optional), adds a PartOf= directive to the volume quadlet and integrates the volume into the container quadlet.
  * `--container-path PATH`: The container mount path where the volume will be mounted inside the container (required when `--container` is used).
  * `--container-user VALUE`: Username/UID or `internal:<uid>` identifier to own the dataset contents (defaults to the owner's UID). Usernames are resolved with `getent passwd`.
  * `--container-group VALUE`: Group name/GID or `internal:<gid>` identifier to own the dataset contents (defaults to the owner's GID). Group names are resolved with `getent group`.
  * `--pre_snapshots RETENTION`: The number of ZFS 'pre_' start snapshots to retrain for the volume (ZFS dataset), default is 5, set to 0 to disable.
  * `--owner USERNAME`: The owner of the volume (unprivileged user account required).
  * `--remove`: Remove the specified volume, including its ZFS dataset, quadlet file, zfs-helper policy entries, and dependencies from container quadlets.
  * `--help`: Display help information about the script usage.
  * `--version`: Display the version of the `bro-volume` script.
* The `bro-volume` creates a `<NAME>.volume` quadlet for the specified unprivileged user in the appropriate XDG path: `~/.config/containers/systemd/<NAME>.volume`. The created volume quadlet contains the necessary configuration to use the created and prepared ZFS dataset as a Podman volume.
* The created volume quadlet includes the following directives:
  * `Description=`: A brief description of the volume.
  * `VolumeName=`: The name of the volume (ZFS dataset name).
  * `Environment=`: Sets environment variables for the volume, including the mount point, the ZFS dataset (same as volume) name, and the owner user as well as things like the RETENTION for pre_snapshots.
    * When `--container-user`/`--container-group` are used, additional `Environment=` entries store the requested UID/GID and a flag the unit uses to reapply ownership on each start.
  * `Wants=`: Specifies that ZFS mounter is ready.
  * `PartOf=`: Associates the volume with the Podman user service instance working in conjunction with a --container option to link the volume to a container.
  * `ExecStartPre=`: Multiple used to prepare the volume for use by ensuring the mount point data set exists, creates it if necessary, and sets the correct ownership and permissions all using zfs-helperctl. Even takes the pre_snapshots argument into account, generating snapshot names with `date +%s%N` timestamps so back-to-back starts never collide. When custom container UIDs/GIDs are supplied, bro-volume applies that ownership during dataset creation (where it still has root privileges) and layers ACLs for the unprivileged owner, so the runtime unit does not need additional chown steps. See how all this is done in the `3. volumes.md` lab. Must make sure to take specifier expansion and special characters into account. Look at examples in the lab where we escaped the `%` with `%%` and the `$` with `$$`.
  * `ExecStart=`: Mounts the ZFS dataset at the specified mount point.
  * `ExecStop=`: Unmounts the ZFS dataset when the volume is no longer needed.
* When the `--container` and `--container-path` options are provided, the `bro-volume` script automatically modifies the existing container quadlet to integrate the volume:
  * Adds systemd service dependencies (`PropagatesStopTo=`, `BindsTo=`, and `After=`) in the `[Unit]` section to properly link the volume service lifecycle with the container service.
  * Adds a `Volume=` directive in the `[Container]` section with the format `MOUNT_POINT:CONTAINER_PATH` to bind mount the ZFS dataset into the container at the specified path.
  * The bind mount always targets the `<mount point>/data` subdirectory, never the dataset root, and `bro-volume` forces `snapdir=hidden` on the dataset so the `.zfs` control tree never shows up inside the container. Without that combination, images like PostgreSQL would see `.zfs` inside `PGDATA` and skip their initialization logic; the same isolation keeps future images happy by guaranteeing a truly empty directory on first start.
  * Detects when the quadlet already declares the volume (either by referencing the generated `<NAME>.volume` quadlet, a shorthand `<NAME>` reference, or by using the same bind mount path) and reuses the existing directive instead of inserting a duplicate entry.
  * Removes any existing volume-related dependencies and volume mounts to the same container path to prevent conflicts.
  * Uses the correct systemd service naming convention where a volume quadlet named `NAME.volume` becomes the service `NAME-volume.service`.
* If the path `/var/lib/containers/unprivileged` exists, the `bro-volume` script creates a new user account under this base directory for unprivileged Podman containers by delegating user creation to the `bro-user` script if the specified owner user does not already exist.
  * If the path does not exist, it fails with an error.
* The `bro-volume` script can be extended in the future to support additional features as needed.
* The `bro-volume` script is intended to be used by system administrators to create and manage ZFS backed volumes for running rootless Podman containers in a secure and isolated manner.
* The `bro-volume` script is part of the Brothaman project and is licensed under the ASL 2.0 License.
* The `bro-volume` script is maintained as part of the Brothaman scripts package and should be kept up to date with the latest features and security patches.
* The `bro-volume` script ensures that the created ZFS dataset has delegated permissions for the specified unprivileged user to manage the dataset without requiring root privileges. This is done by setting the appropriate unit.list and operational allow list files with entries for the zfs-helper in the /etc/zfs-helper/policy.d/<username> directories.
* The `bro-volume` script verifies that the specified unprivileged user has the necessary permissions to use the created ZFS dataset as a Podman volume.
* The `bro-volume` script provides error handling and validation for the command line arguments to ensure that the specified parameters are valid and that the ZFS dataset can be created successfully. This includes:
  * Requiring `--container-path` when `--container` is specified to ensure explicit container mount path specification.
  * Preventing use of `--container-path` without `--container` to maintain logical argument relationships.
  * Validating format and characters in volume names, owner usernames, and container names using regular expressions.
  * Ensuring retention values are non-negative integers.
  * Checking for existing volumes (ZFS dataset or quadlet file) and requiring explicit removal with `--remove` before recreating.
  * Restricting `--remove` mode to only accept `--name` and `--owner` parameters for safety.
  * Allowing container ownership overrides to be specified as usernames, groups, numeric IDs, or `internal:` prefixed IDs. Internal IDs are translated using the owner's `/etc/subuid` and `/etc/subgid` entries (with 0 mapping to the owner's real UID/GID) unless the referenced container explicitly sets `UserNS`, in which case the command aborts.
* The `bro-volume` script supports any type of container by requiring explicit specification of the container mount path via `--container-path`, removing previous hardcoded assumptions about specific container types (e.g., PostgreSQL).
* When using `--remove`, the script performs comprehensive cleanup including:
  * Stopping the volume systemd service if running.
  * Removing the volume quadlet file.
  * Surgically removing only the specific volume's dependencies from all container quadlets that reference it, preserving other volumes.
  * Destroying the ZFS dataset and all its snapshots.
  * Cleaning up zfs-helper policy entries for the volume service and dataset (only if no other volumes use the same dataset).
* The removal process is designed to be safe and only affect the specified volume, leaving other volumes and their dependencies intact.
* The `bro-volume` script is intended to be used in conjunction with the `bro-user` script to create a complete environment for running unprivileged rootless Podman containers with ZFS backed volumes.
