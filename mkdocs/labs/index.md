# Brothaman Labs

Welcome to the Brothaman hands-on laboratory series! These labs provide step-by-step tutorials for learning rootless container management with ZFS, systemd, and Podman.

## Lab Structure

The labs are organized into three main areas:

### Foundation Labs
Essential concepts and setup procedures:
- **Setup Environment** - Configure your test environment with Vagrant
- **User Lingering** - Understand systemd user services and lingering
- **Quadlet Basics** - Learn container service descriptors

### Storage & Data Labs  
Storage management and persistence:
- **Volumes & ZFS** - Bind mounts, persistent volumes, and ZFS snapshots
- **Debugging** - Container troubleshooting and log analysis

### Networking & Services Labs
Advanced networking and service composition:
- **Network Configuration** - Container networking and connectivity
- **Database Admin** - PostgreSQL with pgAdmin setup
- **Pod Management** - Multi-container pod orchestration  
- **Proxy Testing** - Load balancing and proxy configuration

## Prerequisites

- Basic familiarity with Linux command line
- Understanding of containers (Docker/Podman)
- Access to a Linux system with systemd
- Vagrant installed (for VM-based labs)

## Getting Started

Begin with the **Setup Environment** lab to configure your testing environment, then proceed through the Foundation labs before moving to more advanced topics.

Each lab includes:
- Clear learning objectives
- Step-by-step instructions
- Troubleshooting guidance
- Cleanup procedures
- VM snapshot management

Ready to begin? Start with [Setup Environment](0.%20setup.md)!