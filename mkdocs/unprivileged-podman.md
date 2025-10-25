# Unprivileged Podman

Unprivileged Podman refers to the use of Podman by restricted non-root OS accounts rather than the privileged root user. Podman commands and containers run as non-root system account processes while using bounded resources with quota restricted limits specifically assigned to the unprivileged account; i.e. cpu, memory and disk quotas.

>Brothaman creates Podman containers and composable container applications on isolated unprivileged OS accounts.

## Security Pattern

Running applications and services pulled from repositories on the Internet in restricted jails is a sensible security pattern right? You don't want to run other people's shit on your shit as root. Each container adds to the overall attack surface in their own \[un]predictable ways.

Running containers (or applications composed of containers) in restricted environments minimizes the blast radius on compromise. Even without compromise, noisy neighbors or renegade containers **MUST BE** limited and throttled to functionally protect system resources. With compromise, the account, its processes, and resources need to be frozen and quarantined. Perhaps snapshotted and archived before being immediately destroyed for post-mortem forensic analysis.

See [zfs](./zfs.md)

## Storage Concerns

Unprivileged means much more than just jailed service and application processes with their CPU and memory quotas. It includes all resources with storage being the most critical of them all. After all, the most constraining resources on most systems is almost always storage. Even older CPU's with slower clocks and memory buses can almost always saturate storage I/O even with storage technologies 10-years into the future.

Storage is the key resource needing the most protection, yet we often protect it least of all. Brothaman forces the use of ZFS and cgroup v2 blkio limits to cover your back. ZFS as a copy-on-write (CoW) filesystem with capacity quotas makes snapshotting, capacity limiting, and quarantining of containerized services and applications a cake walk.
