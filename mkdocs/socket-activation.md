# Socket Activation

- `NAME.socket`: Listens on `IP:PORT` in the **user** systemd scope.
- `NAME-proxy.service`: Runs `systemd-socket-proxyd`, forwarding accepted fds to `127.0.0.1:INTERNAL_PORT`.
- `NAME.container`: Quadlet container that binds only to loopback on the internal port.

**Flow**: Client → `NAME.socket` → `NAME-proxy.service` → container `127.0.0.1:INTERNAL_PORT`.
