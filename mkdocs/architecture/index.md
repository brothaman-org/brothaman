# Architecture Overview

This section covers the architectural design and patterns used in Brothaman for containerized service management.

## Key Concepts

- **Socket Activation**: How systemd socket activation enables on-demand service startup
- **Quadlet Patterns**: Standardized container deployment patterns using Podman Quadlets  
- **System Design**: Overall architecture and component interactions

## Documentation

- [System Architecture](../architecture.md) - Core architectural principles and design
- [Socket Activation](../socket-activation.md) - systemd socket activation implementation
- [Quadlet Patterns](../quadlet-patterns.md) - Container deployment patterns

## Visual Diagrams

- [System Architecture Diagram](../diagrams/architecture.md) - Overall system architecture
- [Service Pattern Diagram](../diagrams/per-service-pattern.md) - Per-service deployment patterns

## Design Principles

1. **Security First**: Unprivileged containers with proper isolation
2. **SystemD Integration**: Native systemd service management  
3. **ZFS Storage**: Advanced storage features with snapshots
4. **Declarative Configuration**: Infrastructure as Code approach