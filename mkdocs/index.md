# Brothaman Overview

Tools and scripts (so far) that help manage unprivileged rootless Podman containers:

* [x] `bro-user` — create/remove rootless users (lingering, subuid/gid, per-user storage).
* [x] `bro-volume` — create/remove/manage rootless ZFS-backed Podman volumes for unprivileged containers.
* [x] `bro-activate` — create/remove/manage Podman container systemd socket activation.
* [x] `bro-install-podman` — installs or upgrades podman to latest from Alvistack.
* [ ] `bro-decompose` - decomposes a compose file to many quadlets and bro commands with the help of podlet.

Brothaman is a work in progress. More utilities to come!

**Principles**: small scripts, idempotency, rootless-first, ZFS-backed, socket-activated composition,
cross-user/host by on demand *using* sockets instead of orchestrating services.

>**DISCLAIMER**: Brothaman is a personal project and is not affiliated with or endorsed by the Podman project or its maintainers. The code and labs were enhanced using AI. Use at your own risk.

## Why brothaman?

Honestly, I never intended to create a project like this. I started writing up a lab series to teach people how to use Podman quadlets securely with systemd for unprivileged rootless containers. But as I wrote the labs, I realized there were a lot of repetitive tasks and boilerplate configurations that could be automated. So I created some scripts to help with that, and before I knew it, I had a whole suite of tools that could make managing rootless containers much easier and more securely without all the rote manual labor and human error.

>And because sometimes everyone needs a good brothaman to help carry the burden.

I truly hope that brothaman can helps others save time and avoid the pitfalls and challenges I faced when learning to use Podman Quadlets with systemd and my own personal system security patterns. By providing a set of scripts that automate common tasks and enforce best practices, I believe we can make rootless container management more accessible and secure for everyone.

In the end, I would love for brothaman to go away, and become obsolete because Podman natively supports all these utilities out of the box. But until then, I hope brothaman can serve as a useful tool for anyone looking to run rootless containers securely and efficiently.
