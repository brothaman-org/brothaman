# Brothaman Overview

- [ ] `bro-volume` — create/remove/manage rootless Podman volumes (ZFS-optional).
- [ ] `bro-network` — create/remove/manage rootless Podman networks (CNI + systemd-networkd).
- [v] `bro-user` — create/remove rootless users (lingering, subuid/gid, per-user storage).
- [ ] `bro-service` — create socket-activated services (Quadlet + systemd-socket-proxyd).
- [ ] `bro-compose` — convert docker-compose.yml into `bro-service` calls (no `-p` publishes).
- [ ] `bro-doctor` — optional diagnostics.
- [ ] `bro-install-podman` — installs or upgrades podman to latest from Alvistack.

**Principles**: small scripts, idempotency, rootless-first, ZFS-optional, socket-activated composition,
cross-user/host by on demand *using* sockets instead of orchestrating services.
