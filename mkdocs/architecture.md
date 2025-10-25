# Architecture Overview

Administration best practices + systemd primitives + podman features

* secure container services and applications
* one minimal authoritative configuration
* fine control over noisy neighbors, renegades, and compromised containers
* elegantly managed cross-over container dependencies
* higher performance and more capabilities

Brothaman uses a combination of system administration best practices with systemd primitives and Podman features to elegantly simplify, secure, and manage containerized services and compositions of dependent containers via docker-compose descriptor files.

---

* [unprivileged podman](./unprivileged-podman.md)
* [quadlet-patterns](./quadlet-patterns.md)

* Quadlet based authoritative service configuration in systemd --user scopes
* ZFS using fuse-overlayfs
* Systemd proxyd
* Systemd socket
* Fast networking with Pasta

The best aspect differentiating Podman is its relentless pursuit to work harmoniously with systemd at the operating system level. Podman users easily hook containers into systemd as services using its `generate systemd` sub-command. Now there are even more powerful Quadlets.

The plethora of systemd features makes it hard to notice glorious ways to make amazing things happen.

>Thankfully, systemd harmony is even better after this command was deprecated in favor of [Quadlet](https://docs.podman.io/en/latest/markdown/podman-quadlet.1.html). Unfortunately, many are reluctant to upgrade.

Brothaman builds on systemd and Quadlet to run rootless containers that are **activated by traffic**.

1. A `.socket` unit listens on a host port (or specific interfaces).
2. When a client connects, `systemd-socket-proxyd` (`-Service`) forwards to a **loopback internal port**.
3. The proxied connection activates the **container** via a Quadlet `.container` unit.
4. No `-p` port mapping is used; the proxy handles external exposure.

This pattern composes across users and hosts: a client of a service **uses** it and activation follows demand.
