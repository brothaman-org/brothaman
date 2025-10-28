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
