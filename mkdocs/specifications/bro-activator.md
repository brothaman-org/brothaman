# Specification: `bro-activator` CLI Program

>Previously referred to as `bro-socket-proxyd`.

The `bro-activator` CLI program, as a bash script, is part of the Brothaman scripts package which creates systemd socket activator infrastructure for unprivileged containers. It is installed using the `bro-install` script or the `brothaman-scripts` Debian package.

* The `bro-activator` script DOES NOT require root privileges to run, and can be executed by unprivileged users.
* The `bro-activator` script creates a per container quadlet service pattern consisting of three components for socket-activated container services (two are created for a container quadlet):
  1. A systemd socket unit (`${CONTAINER_NAME}-activator.socket`) that listens for incoming connections on a specified external network interface and port.
  2. An activator service unit (`${CONTAINER_NAME}-activator.service`) that forwards incoming connections from the socket unit to the container's internal port using an instance of systemd-socket-proxyd running inside CONTAINER_NAME's network namespace.
  3. A Podman Quadlet container descriptor unit (`CONTAINER_NAME.container`) that defines the container to be run.
* The `bro-activator` script supports the following command line options:
  * `--name CONTAINER_NAME`: The base name for the service components (socket, proxy, container). With the CONTAINER_NAME the script generates a `${CONTAINER_NAME}-activator.socket` and a `${CONTAINER_NAME}-activator.service` for the `${CONTAINER_NAME}.container` quadlet which Podman happens to automatically generate a `${CONTAINER_NAME}.service` for the quadlet.
  * `--service-name VALUE`: Optional suffix to distinguish multiple activators for the same container. When provided, the generated units become `${CONTAINER_NAME}-${VALUE}-activator.{socket,service}` and their helper artifacts also pick up the suffix, preventing file collisions when exposing multiple ports.
  * `--remove`: Deletes the socket, service, and helper script for the specified container name, optionally scoped to `--service-name`. This allows users to cleanly remove activators that are no longer needed without editing the quadlet or other options.
  * `--external-port ADDR:PORT`: The external interface address and port on which the socket unit will listen for incoming connections (0.0.0.0 for all interfaces). If address is omitted, defaults to all interfaces.
  * `--internal-port ADDR:PORT`: The internal port on which the container will listen for connections. The proxy service unit will forward connections to this port inside the container. If address is omitted, defaults to 127.0.0.1 (localhost).
  * `--network VALUE`: Override the target container quadlet's `Network=` directive. When omitted the existing network configuration is left untouched.
  * `--help`: Display help information about the script usage.
  * `--version`: Display the version of the `bro-activator` script.

* The `bro-activator` script generates the necessary systemd unit files for the socket unit, proxy and service unit, corresponding to the container quadlet unit based on the provided command line options. Use the lab `4. networking.md` as good guide / reference for how this is done since it provides examples perhaps not exactly following conventions (it's container name is test-postgresql but the activators use postgresql-activator as the base name) but its close. To avoid fragile inline heredocs, `bro-activator` now also writes a helper script `~/.config/systemd/user/${CONTAINER_NAME}-activator-helper.sh` that the generated service uses for all `ExecStart{Pre}` actions.
  * The helper script has three subcommands:
    * `capture` - loops until it can `podman inspect -f '{{.State.Pid}}'` the target container and writes `%t/${CONTAINER_NAME}-activator.env` (containing `TARGET_PID`, `TARGET_HOST`, `TARGET_PORT`).
    * `wait` - sources the env file and uses `podman unshare nsenter -t "${TARGET_PID}" -n …` to probe the internal port (currently via `nc -z`), retrying until it succeeds or times out.
    * `run` - sources the env file and launches `podman unshare bro-helper --pid "${TARGET_PID}" -- /lib/systemd/systemd-socket-proxyd …`.
  * The generated service now references this helper script instead of embedding bash loops directly in systemd unit properties. This keeps the unit readable, eliminates quoting pitfalls, and makes it easier to evolve the orchestration logic.
* The created systemd units are placed in the appropriate XDG paths for systemd user services and quadlets under `~/.config/systemd/user/`.
* When executing `--remove`, the script simply deletes the activator socket/service/helper paths (matching any provided `--service-name`) and skips quadlet validation or modification so that clean-up works even if the container has already been removed.
* Before writing any activator units, the script checks if the target socket or service files already exist (after factoring in `--service-name`, when provided). It aborts with an error when collisions are detected so that existing activators are not silently overwritten.
* The `bro-activator` script can be extended in the future to support additional features as needed.
* The `bro-activator` script is intended to be used by system administrators and unprivileged users to create socket-activated container services in a standardized and efficient manner.
* The `bro-activator` script is part of the Brothaman project and is licensed under the ASL 2.0 License.
* The `bro-activator` script is maintained as part of the Brothaman scripts package and should be kept up to date with the latest features and security patches.
* The `bro-activator` script ensures that the created systemd units follow best practices for security, resource management, and systemd integration.
* The `bro-activator` script provides error handling and validation for the command line arguments to ensure that the specified parameters are valid and that the systemd units can be created successfully.
* The `bro-activator` script is intended to be used in conjunction with other Brothaman scripts, such as `bro-user` and `bro-volume`, to create a complete environment for running unprivileged rootless Podman containers with socket activation capabilities.
* The `bro-activator` script updates the container quadlet unit surgically: it removes only the `PublishPort=` entries that would otherwise collide with the activator's requested `--external-port/--internal-port` combination, leaves other published ports alone, and preserves the existing `Network=` directive unless `--network` is explicitly supplied (in which case the new value replaces the old one).
* The `bro-activator` script provides documentation and usage examples to assist users in creating socket-activated container services using the man page facilities. Make sure a man page is created for it and installed properly along side the script.
* The `bro-activator` script verifies that the specified external and internal ports are available and not already in use by other services.
* The `bro-activator` script allows for customization of the created systemd units through additional command line options or configuration files in the future.
* The `bro-activator` script provides logging and debugging capabilities to assist users in troubleshooting any issues that may arise during the creation or operation of the socket-activated container services.
* The `bro-activator` script is compatible with the latest versions of Podman and systemd, ensuring that users can take advantage of the latest features and improvements in these technologies.
* The `bro-activator` script follows best practices for bash scripting, including proper error handling, input validation, and code organization.
* The `bro-activator` script is tested and validated to ensure that it functions correctly and reliably in various environments and use cases.
* The `bro-activator` script is documented with clear and concise comments to assist users in understanding its functionality and usage.
* The `bro-activator` script is intended to be a key component of the Brothaman project, providing a standardized and efficient way to create socket-activated container services for unprivileged users.
* The `bro-activator` script provides a consistent and repeatable process for creating socket-activated container services, making it easier for users to deploy and manage these services in their environments.
* The `bro-activator` script is designed to be user-friendly, with clear command line options and helpful error messages to guide users through the process of creating socket-activated container services.
* The `bro-activator` script is intended to be used in a variety of scenarios, including development, testing, and production environments, providing flexibility and adaptability for different use cases.
* The `bro-activator` script adds the proper dependencies to the <CONTAINER_NAME>-activator.service to ensure that it starts after the <CONTAINER_NAME>.service (the service generated for the quadlet <CONTAINER_NAME>.container) with the right Requires= for the socket and the quadlet service as well as the After= directives to ensure proper startup ordering. See how postgresql-activator.service is done in the `4. networking.md` lab for an example.
