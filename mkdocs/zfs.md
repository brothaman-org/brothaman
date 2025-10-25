# ZFS

Brothaman uses ZFS to implement storage I/O throttling of unprivileged container services. As the premier copy-on-write (CoW) file system with rapid low cost snapshotting and rollback ZFS is also ideal for snapshotting, quarantining and archiving compromised containers for forensic analysis.

## Unprivileged with ZFS

Podman's ZFS driver uses ZFS snapshots and mountpoints for container layering, but it is not stable and only supports privileged Podman. ZFS delegation just does not provide unprivileged users with the key mounting privileges needed. Once it does Brothaman can reconsider using it as the main driver. Don't hold your breath on it though; Linux might never let ZFS do this as long as it keeps one global mount space.

### FUSE Overlayfs on ZFS

Brothaman **DOES NOT** use ZFS for image layer management but it does use it as the underlying backing store for unprivileged users. Brothaman uses the Overlayfs driver instead of the default vfs driver to greatly improve performance and reduce the overhead of layer storage. To do this in unprivileged environments requires the use of the `fuse-overlayfs` program as the `mount_program` (and `mountopt = 'nodev'`) within the unprivileged account's storage configuration file at `${USER_HOME}/.config/containers/storage.conf`.

### ZFS Dataset Settings

Each unprivileged user's home directory is mounted using a new dedicated ZFS data set. That dataset is configured with the following attributed values:

* `xattr=sa`
* `acltype=posixacl`
* `aclinherit=passthrough`
* `aclmode=passthrough`
* `mountpoint="${USER_HOME}"`
* `compression=zstd`
* `atime=off`
* `recordsize=128`

<!-- TODO: document some where that we want to put these settings into a [zfs] section in an ini file -->

## Brothaman Tools

* `bro-install-zfs` installs ZFS on Debian 12 (no pools).
* `bro-test-zpool` creates a **file-backed** pool for development (default name `brotest`).

Recommended dataset for per-user graphroots:
* `POOL/containers/USER` mounted at `/var/lib/containers/unprivileged/USER`
* Suggested props: `compression=zstd`, `atime=off`
