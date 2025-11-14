# Brothaman Labs

Welcome to the Brothaman hands-on laboratory series! These labs provide step-by-step tutorials for learning rootless container management with Podman Quadlets and systemd.

## Purpose

The entire point to unprivileged rootless containers is to improve security by isolating container processes from the host system and other users. Doing so reduces the attack surface and limits potential damage from compromised containers to reduce the blast radius.

Podman's Quadlet integration with systemd is revolutionary and allows us to manage these containers as first class systemd services, leveraging systemd's capabilities for service management, security, logging, and dependency handling. Podman features and different Quadlet types provide powerful constructs but knowing when and how to use them properly is key. These labs guide you through the essential concepts and practical steps needed to effectively use Podman Quadlets for managing rootless containers with a strong emphasis on security best practices.

As we progress together, we will consider challenging scenarios. You may feel this is more a security lab rather than a container management one using Podman Quadlets. This is intentional. We have to consider real scenarios because understanding the security implications of running containers is crucial for any system administrator or developer working with containerized applications. We don't mind doing so since you will be able to reuse the knowledge and approaches gained to batten down the hatches in your own environments. Furthermore, by addressing these challenges, you'll gain a deeper understanding of how to securely manage rootless containers using Podman quadlets and systemd which is the whole point.

## Lab Structure

The labs are organized into three main areas:

### Foundation Labs
Essential concepts and setup procedures:
- **Setup Environment** - Configure your test environment with Vagrant
- **User Lingering** - Understand systemd user services and lingering
- **Quadlet Basics** - Learn basic Quadlet service descriptors

### Storage & Data Labs  
Storage management and persistence:
- **Volumes & ZFS** - Bind mounts, persistent volumes, and ZFS snapshots
- **Debugging** - Container troubleshooting and log analysis

### Networking & Services Labs
Advanced networking and service composition:
- **Network Configuration** - Container networking and connectivity
- **Database Admin** - PostgreSQL with risky pgAdmin application setup
- **Pod Management** - Multi-container pod orchestration
- **Proxy Testing** - Load balancing and proxy configuration

## Prerequisites

- Basic familiarity with Linux command line
- A cursory understanding of containers (Docker/Podman)
- Access to a Linux system with systemd
- Vagrant and KVM hypervisor installed (for VM-based labs)

## Getting Started

Begin with the **Setup Environment** lab to configure your testing environment, then proceed through the Foundation labs before moving to more advanced topics.

Each lab includes:
- Clear learning objectives
- Step-by-step instructions
- Troubleshooting guidance
- Cleanup procedures
- VM snapshot management

Ready to begin? Start with [Setup Environment](0.%20setup.md)!
