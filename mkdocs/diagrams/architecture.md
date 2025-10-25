# System Architecture Diagram

This diagram shows the overall system architecture for Brothaman's socket-activated container services.

```mermaid
graph LR
Client((Client)) -->|TCP| NAME_socket[NAME.socket]
NAME_socket --> NAME_proxy[NAME-proxy.service (systemd-socket-proxyd)]
NAME_proxy -->|forward to 127.0.0.1:INTERNAL_PORT| NAME_container[NAME.container (Quadlet)]
```

## Architecture Components

- **Client**: External client connecting to the service
- **NAME.socket**: systemd socket unit that listens for incoming connections
- **NAME-proxy.service**: systemd-socket-proxyd service that forwards connections
- **NAME.container**: Podman Quadlet container running the actual service

## Flow Description

1. Client connects to the external port managed by the socket unit
2. systemd activates the proxy service when a connection is received
3. The proxy forwards the connection to the container's internal port
4. The container handles the actual service logic

This architecture enables:
- **Socket activation**: Services start only when needed
- **Resource efficiency**: Containers don't run when idle
- **Security**: Internal ports are not directly exposed
- **Systemd integration**: Full lifecycle management through systemd