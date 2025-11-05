# Brothaman's Proxyd Helper

The **`bro-helper`** enables **`systemd-socket-proxyd`** instances to be exec'd inside the network namespace of containers. By doing so it allows it to proxy traffic from a systemd.socket's file descriptor to container ports that network services bind to on container interfaces.

1. Allows for `--network=none` for toighter security
2. Proxied network services can bind to loopback interfaces
3. Single hop proxy (one less without podman's -p mappings)
4. Enables traffic triggering and on-demand container start
5. Primitive used to enable cross over dependencies between unprivileged containers

## So what? Why do we need this?

Unprivileged containers using **`slirp4netns`** or **`pasta`** (or `--network=none` for that matter) have no IP addresses exposed to the host, and hence no ports to proxy traffic to the container with `systemd-socket-proxyd`. So why do we even bother using `systemd-socket-proxyd` when the -p switch could be used to proxy traffic from the host to the container: i.e. `-p 8080:80`?

>**ROOT CAUSE**: Podman's proxy mechanism does not work with systemd.socket traffic triggering nor does it support server socket (listener) file descriptor passing while `systemd-socket-proxyd` does.

### Using both together sucks

You could make them both work together. Presume an NGINX container with the daemon running on its default port 80. Unprivileged containers cannot map container ports to host ports below 1024 so we make podman proxy host port 8080 to container port 80.

Yet we still want to trigger containers to start when traffic appears using systemd sockets. Say we use a port for it at 8081. Then the `systemd-socket-proxyd` daemon proxies traffic to and from port 8080 to 8081.

Using them together now doubles the proxied traffic overhead which adds latency and you have an extra bogus port sitting out there. With `bro-helper` one host port and one container port is needed. Most importantly, there's no additional stream copy and transfer across ports for absolutely no reason.

## Security Restrictions

The `bro-helper` is a tiny c-program that uses file capabilities to enter network namespaces. It takes a container PID, joins its network namespace, and executes any command within that namespace. It works with containers running as the invoking user and preserves socket file descriptors for systemd socket activation.

Least privilege is achieved by using a very narrow capability addition while using that capability in highly specific situations. Meanwhile we do not fork and honor the passed host file descriptors (listener socket) so are handed off to `systemd-socket-proxyd` running in the container.

* Find the netns you want (e.g., /proc/${PID}/ns/net),
* Join it with setns(fd, CLONE_NEWNET),
* Exec the target process.

That's it—no daemons, no forking trees, just a short, auditable path.

The security model is simple and effective:

### File-based capability assignment

The `bro-helper` binary uses file capabilities to obtain the minimal permission needed:

* Installation sets `cap_sys_admin+ep` on the binary via `setcap`
* This allows **any user** to run bro-helper and enter network namespaces they own
* The capability is **effective** and **permitted**, but not **inheritable**

### What this means for security

* **Limited scope**: Only `CAP_SYS_ADMIN` is granted, only for network namespace entry
* **No privilege escalation**: The executed command (like `systemd-socket-proxyd`) inherits **no special capabilities**
* **Process isolation**: Each execution is independent with no persistent privileged daemon

## What it does (conceptually)

* **Inputs:** `--pid <PID>`, `-- <cmd> [args…]`
* **Open the namespace:** `fd = open("/proc/PID/ns/net", O_RDONLY|O_CLOEXEC)`
* **Join it:** `setns(fd, CLONE_NEWNET)`
* **Update environment:** Set `LISTEN_PID` for socket activation if needed
* **Hand off:** `execvp(target_command, argv)`  
    From here, the target runs **inside** that netns with normal user privileges.

## Why it needs CAP_SYS_ADMIN

* To call `setns(CLONE_NEWNET)` into a network namespace, the kernel requires **`CAP_SYS_ADMIN`**
* The capability is set via file capabilities: `setcap cap_sys_admin+ep /usr/local/bin/bro-helper`
* This is the **only** capability needed for network namespace entry
* The executed program inherits **no special capabilities** - it runs with normal user privileges

## More security options for the next iteration

* **Validate the target**: ensure the PID exists and (optionally) matches the expected user/UID for your trust model.
* **Avoid TOCTOU**: once you open the netns fd, you're safe; don't re-resolve paths again.
* **Logging**: on failure, log `errno` and the exact syscall (helps when seccomp/LSM interferes).
* **Interface**: support `--netns-path` as an alternative to `--pid`, so you can bind a stable symlink like `/run/netns/nginx-proxyd`.

This is why the approach is safe and composable: **minimal capability scope**, **file-based permissions**, **no persistent privileges**, and the actual worker (`systemd-socket-proxyd`) runs with **regular user privileges** in the desired netns.
