# Project Plan

## Goals
- Modularize rootless Podman + ZFS workflow into small, idempotent tools.
- Prefer systemd primitives (socket activation + proxyd) over container port publishing.
- Ensure each script maps 1:1 to an Ansible role (default mode), with a fallback shell mode via `--script`.

## Work Breakdown Structure
1. **ZFS Installation** — `bro-install-zfs`
2. **Test Zpool** — `bro-test-zpool`
3. **Dependencies** — `bro-install-deps`
4. **User Management** — `bro-user`
5. **Service Generator** — `bro-service`
6. **Compose Converter** — `bro-compose`
7. **Doctor** — `bro-doctor`
8. **Documentation & Diagrams** — mkdocs site, mermaid diagrams

## Deliverables
- Executable `bro-*` wrappers (bimodal: Ansible default, `--script` for shell fallback).
- Ansible collection skeleton: `akarasulu.brothaman` with roles matching each script.
- MkDocs site: this plan, architecture, how-tos, and a project dictionary.
- Example Vagrant environment for Debian 12 smoke testing.

## Acceptance Criteria
- All scripts are idempotent and safe to re-run.
- Socket-activated services start on demand via `systemd-socket-proxyd`.
- `bro-compose` generates deterministic plans and compatible service units.
- Documentation is sufficient to onboard a new operator using only this site.

## Future Extensions
- Cross-host activation cookbook.
- Secrets and TLS patterns.
- CI smoke tests for Vagrant-based runs.
