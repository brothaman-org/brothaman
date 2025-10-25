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

The `bro-helper` is a tiny c-program with slightly augmented capabilities allowing it to set the netns and spawns commands within it. It can exec `systemd-socket-proxyd`, `ip`, and `netstat` commands only. Furthermore, it only works on containers running as the invoking user.

Least privilege is achieved by using a very narrow capability addition while using that capability in highly specific situations. Meanwhile we do not fork and honor the passed host file descriptors (listener socket) so are handed off to `systemd-socket-proxyd` running in the container.

* Find the netns you want (e.g., /proc/${PID}/ns/net),
* Join it with setns(fd, CLONE_NEWNET),
* Drop any capabilities it no longer needs,
* Exec the target process.

That's it—no daemons, no forking trees, just a short, auditable path.

Two layers work together to maintain least privilege:

### 1. The **unit file** constrains what the process can ever have

* `CapabilityBoundingSet=CAP_SYS_ADMIN CAP_NET_ADMIN`  
    → _Even if_ the binary tried, it **cannot** gain caps outside this set.
* `AmbientCapabilities=CAP_SYS_ADMIN CAP_NET_ADMIN` (or file caps on the binary)  
    → Ensures the helper **starts** with just the tiny set it needs.
* `NoNewPrivileges=no`  
    → Required if you rely on ambient caps or file caps across `execve()`.

### 2. The **program drops capabilities** as soon as it’s done with `setns()`

Right after `setns()`, it **clears its capability sets** so the final `exec()`ed program runs unprivileged (or with only what you explicitly keep). Concretely:

* Use **libcap** to set **effective+permitted+inheritable = empty** before `execvp()`.
* Optionally lock things down further by dropping from the **bounding set** via `prctl(PR_CAPBSET_DROP, ...)` (irreversible for the lifetime of the process).
* Optionally set `PR_SET_NO_NEW_PRIVS` to 1 after dropping caps.

Result: the helper temporarily uses `CAP_SYS_ADMIN` to perform **one** privileged kernel call, then throws away the keys.

## What it does (conceptually)

* **Inputs:** `--pid <PID>` (or sometimes `--netns-path <path>`), `-- <cmd> [args…]`
* **Open the namespace:** `fd = open("/proc/PID/ns/net", O_RDONLY|O_CLOEXEC)`
* **Join it:** `setns(fd, CLONE_NEWNET)`
* **Harden & de-priv:**
  * Clear dangerous env (PATH, IFS if you're paranoid), set `umask(077)`
  * **Drop capabilities** (details below)
  * Optionally set `prctl(PR_SET_NO_NEW_PRIVS, 1)` after dropping caps      
* **Hand off:** `execvp("systemd-socket-proxyd", argv)`  
    From here, _proxyd_ runs **inside** that netns, inheriting only the minimal privileges you allow.

## Why it needs (some) capabilities

* To call `setns(CLONE_NEWNET)` into a netns you don't “own”, the kernel requires **`CAP_SYS_ADMIN` in the owning user namespace** of that netns. We own it but are still required to have the permission.
* You **don’t** need `CAP_NET_ADMIN` to _enter_ the netns, but tools you run **inside** (like `ip addr`) may need it to mutate interfaces. `systemd-socket-proxyd` typically doesn't need `CAP_NET_ADMIN`; it just opens sockets.
* So: **minimum to enter** is `CAP_SYS_ADMIN`. If you _also_ run diagnostics like `ip` inside the netns, give `CAP_NET_ADMIN` too (and then drop it before you `exec proxyd` if proxyd doesn’t need it).

## More security options for the next iteration

* **Validate the target**: ensure the PID exists and (optionally) matches the expected user/UID for your trust model.
* **Avoid TOCTOU**: once you open the netns fd, you're safe; don't re-resolve paths again.
* **Logging**: on failure, log `errno` and the exact syscall (helps when seccomp/LSM interferes).
* **Interface**: support `--netns-path` as an alternative to `--pid`, so you can bind a stable symlink like `/run/netns/nginx-proxyd`.

This is why the approach is safe and composable: **short-lived privilege**, **immediate drop**, **tight unit caps**, and the actual worker (`systemd-socket-proxyd`) runs with **regular user privileges** in the desired netns.
