# proxyd testing

Awesome, everything is working now with the simple straight forward service.

NOTE: Need to stop the service when container stops?


```bash
lingeruser@debian12:~$ cat .config/systemd/user/nginx8080.service 
[Unit]
Description=Proxy host:8080 -> 127.0.0.1:80 inside nginx-proxyd netns
After=default.target
Requires=nginx8080.socket

[Service]
Type=simple
EnvironmentFile=-%t/nginx-proxyd.env
ExecStartPre=/usr/bin/env sh -c "/usr/bin/podman inspect -f 'TARGET_PID={{.State.Pid}}' nginx-proxyd > %t/nginx-proxyd.env"

ExecStartPre=/usr/local/bin/fd-setns-exec --pid ${TARGET_PID} -- ip -o addr
ExecStartPre=/usr/local/bin/fd-setns-exec --pid ${TARGET_PID} -- netstat -tlpn 
ExecStart=/usr/local/bin/fd-setns-exec --pid ${TARGET_PID} -- /lib/systemd/systemd-socket-proxyd 127.0.0.1:80

NoNewPrivileges=no
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full

Restart=on-failure
RestartSec=0.5s

[Install]
WantedBy=default.target

```

```bash
lingeruser@debian12:~$ cat .config/systemd/user/nginx8080.socket 
[Unit]
Description=Socket for nginx in container netns (host:8080)

[Socket]
# Listen on all interfaces; adjust as needed (0.0.0.0 or 127.0.0.1)
ListenStream=0.0.0.0:8080
NoDelay=true
ReusePort=true
Backlog=128

[Install]
WantedBy=default.target
```

## 1. Set up the container

```bash
sudo su - lingeruser
```

Fire up nginx to listen on default port 80 inside the non-networked container on the localhost / loopback and confirm it is working.

```bash
podman rm -f nginx-proxyd 2>/dev/null || true
podman run -d --name nginx-proxyd --network=none --restart=no docker.io/library/nginx:alpine 
podman exec nginx-proxyd netstat -tlnp | grep ":80"
podman exec nginx-proxyd curl localhost
```

Capture the netns path for the container process

```bash
NETNS_PATH="$(podman inspect -f '{{ .NetworkSettings.SandboxKey }}' nginx-proxyd)"
echo "NETNS_PATH=${NETNS_PATH}"
# Example: 
#   for pasta /run/user/1001/netns/netns-0f518fa4-fc9a-b4e3-5f0c-cd7286004f80
#   for others /proc/20173/ns/net

# Confirm it’s a file we (the same user) can open
ls -l "${NETNS_PATH}"
```

## 2 Create **user** systemd units (socket + service)

We'll bind **host:8080** in a **user** socket unit (no root needed since >1024), and on first connection systemd will spawn `systemd-socket-proxyd` **inside the container’s netns**, dialing `127.0.0.1:80`.

### 2.1 The socket unit

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/nginx8080.socket <<'EOF'
[Unit]
Description=Socket for nginx in container netns (host:8080)

[Socket]
# Listen on all interfaces; adjust as needed (0.0.0.0 or 127.0.0.1)
ListenStream=0.0.0.0:8080
NoDelay=true
ReusePort=true
Backlog=128

[Install]
WantedBy=default.target
EOF
```

## 2.2 The service unit

Paste the **exact** netns path you captured into `NetworkNamespacePath=...` below.

```bash
cat > ~/.config/systemd/user/nginx8080.service <<EOF
[Unit]
Description=Proxy host:8080 -> 127.0.0.1:80 inside nginx-proxyd netns

# Make sure container exists before we try to connect (best-effort)
After=default.target

[Service]
# CRITICAL: join the container's network namespace so 127.0.0.1 is *inside* the container
NetworkNamespacePath=/run/user/1001/netns/netns-0f518fa4-fc9a-b4e3-5f0c-cd7286004f80

# Socket-activated; systemd passes the accepted client socket(s) via LISTEN_FDS
ExecStart=/usr/lib/systemd/systemd-socket-proxyd 127.0.0.1:80

# Reasonable hardening/defaults for a tiny proxy hop
DynamicUser=no
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=true
LockPersonality=true
RestrictRealtime=true
RestrictSUIDSGID=true
CapabilityBoundingSet=
SystemCallArchitectures=native

# Restart on occasional failures
Restart=on-failure
RestartSec=0.5s
# Inherit our user's env
Environment=LANG=C.UTF-8

[Install]
WantedBy=default.target
EOF
```

> `NetworkNamespacePath=` is the magic: it makes the proxyd’s **client side** (the “dial to 127.0.0.1:80”) happen **inside** the container’s netns.
