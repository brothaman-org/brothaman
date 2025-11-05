# Brothaman Overview

* [x] `bro-user` — create/remove rootless users (lingering, subuid/gid, per-user storage).
* [x] `bro-volume` — create/remove/manage rootless ZFS-backed Podman volumes for unprivileged containers.
* [x] `bro-activate` — create/remove/manage Podman container systemd socket activation.
* [x] `bro-install-podman` — installs or upgrades podman to latest from Alvistack.
* [ ] `bro-decompose` - decomposes a compose file to many quadlets and bro commands with the help of podlet.

# TODO: Do these things when driven by a kubernetes-style declarative spec

**Principles**: small scripts, idempotency, rootless-first, ZFS-backed, socket-activated composition,
cross-user/host by on demand *using* sockets instead of orchestrating services.
