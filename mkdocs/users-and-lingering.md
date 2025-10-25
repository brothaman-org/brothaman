# Users & Lingering

Rootless services run in **user** systemd scope. To run without an active login:
- Enable lingering: `loginctl enable-linger USER`

Per-user containers config (`~/.config/containers/storage.conf`):
```
[storage]
driver = "overlay"
runroot = "/run/user/UID"
graphroot = "/var/lib/containers/unprivileged/USER"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
```

Subuid/subgid mappings must be present for rootless Podman.
