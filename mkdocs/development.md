# Development Guide

This guide covers development practices, conventions, and contribution guidelines for the brothaman project.

## Naming Conventions

Brothaman follows a consistent dual naming convention across all components:

### Package Names
All Debian packages use the **full prefix** `brothaman-*`:

- `brothaman-helper` - Network namespace helper utility
- `brothaman-compose` - Container compose management
- `brothaman-service` - Service lifecycle management  
- `brothaman-install-deps` - Dependency installation utilities
- `brothaman-zfs` - ZFS management tools

**Rationale**: Full package names provide clear identification in APT repositories and package listings.

### Command Names  
All executable commands use the **short prefix** `bro-*`:

- `bro-helper` - Network namespace helper
- `bro-compose` - Container compose management
- `bro-service` - Service lifecycle management
- `bro-install-deps` - Install system dependencies
- `bro-install-zfs` - Install ZFS utilities

**Rationale**: Short command names are convenient for daily terminal usage and tab completion.

### Examples

```bash
# Install the package
sudo apt install brothaman-helper

# Use the command
bro-helper --netns /run/user/1000/netns/podman -- curl ifconfig.me

# Search for all brothaman packages
apt search brothaman-*

# Tab complete all bro commands  
bro-<TAB><TAB>
```

## Package Structure

Each brothaman component follows this standard Debian package structure:

```
pkgs/brothaman-<name>/
├── DEBIAN/
│   ├── control          # Package metadata
│   ├── postinst         # Post-installation script
│   └── prerm            # Pre-removal script (if needed)
├── usr/local/bin/       # Executable binaries
│   └── bro-<name>       # Main executable
├── src/                 # Source code (for compiled tools)
│   ├── Makefile         # Build configuration
│   └── *.c/*.go/etc     # Source files
└── build.sh             # Build script (optional)
```

## Build Process

Packages are built using the containerized build system:

```bash
# Build all packages
./scripts/build.sh

# Build specific components
./scripts/mkdebs.sh

# Generate documentation
./scripts/mkdocs.sh

# Create repository
./scripts/mkrepo.sh
```

## Development Workflow

1. **Create Package Structure**: Add new package to `pkgs/brothaman-<name>/`
2. **Add DEBIAN Control Files**: Define package metadata and dependencies  
3. **Implement Functionality**: Add source code and build configuration
4. **Update Documentation**: Add or update relevant markdown files
5. **Test Build**: Run `./scripts/build.sh` to verify package creation
6. **Update Navigation**: Add new docs to `mkdocs.yml` navigation

## Code Standards

- **Shell Scripts**: Follow bash best practices with `set -euo pipefail`
- **C Code**: Use standard GNU C with appropriate compiler warnings
- **Go Code**: Follow standard Go formatting and conventions
- **Documentation**: Use clear, concise markdown with examples

## Security Considerations

- All network namespace operations validate ownership
- Capabilities are set via postinst scripts, not SUID binaries
- Commands use allowlists for permitted operations
- ZFS operations respect user permissions and quotas

## Testing

- Unit tests in `tests/` directory
- Integration tests via Vagrant environments  
- Package installation testing in clean containers
- Documentation validation via MkDocs build

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-tool`
3. Follow naming conventions for packages and commands
4. Add tests and documentation
5. Submit a pull request

## Release Process

1. Update version numbers in package control files
2. Run full build: `./scripts/build.sh`  
3. Sign repository: `./scripts/signrepo.sh`
4. Publish changes: `./scripts/publish.sh`
5. Create release: `./scripts/release.sh`