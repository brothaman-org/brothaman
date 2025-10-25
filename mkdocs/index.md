# Brothaman Overview

**Brothaman** splits a previously monolithic rootless-Podman setup into small, composable units:

- `bro-install-zfs` — install ZFS (no pools are created).
- `bro-test-zpool` — create a disposable, file-backed test zpool (Vagrant/dev).
- `bro-install-deps` — install Podman, Quadlet, socket proxy, and helpers.
- `bro-user` — create/remove rootless users (lingering, subuid/gid, per-user storage).
- `bro-service` — create socket-activated services (Quadlet + systemd-socket-proxyd).
- `bro-compose` — convert docker-compose.yml into `bro-service` calls (no `-p` publishes).
- `bro-doctor` — optional diagnostics.

**Principles**: small scripts, idempotency, rootless-first, ZFS-optional, socket-activated composition,
cross-user/host by *using* services instead of orchestrating them.
