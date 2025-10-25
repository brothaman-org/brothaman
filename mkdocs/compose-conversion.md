# Compose Conversion

>WIP: Need to look at how we will deal with all aspects of docker-compose files. We need to look at how various entities in the compose file are best converted into Quadlet files (i.e. volumes).

`bro-compose` reads `docker-compose.yml` and synthesizes per-service calls to `bro-service` and potentially other new Brothaman commands:

- Each published port becomes a `.socket` + proxyd pair
- Containers bind to container interface ports accessible to the host and proxyd
- Dependencies prefer **usage** (client connects to server socket) rather than orchestration
- Optional service→user mapping allows separation of privileges
