# Deployment Information

## GitHub Pages
- **Website URL**: https://brothaman-org.github.io/brothaman
- **APT Repository URL**: https://brothaman-org.github.io/brothaman/apt/

## Repository Setup for Users
```bash
# Add repository
curl -fsSL https://brothaman-org.github.io/brothaman/apt/apt-repo-pubkey.asc | sudo apt-key add -
echo "deb https://brothaman-org.github.io/brothaman/apt stable main" | sudo tee /etc/apt/sources.list.d/gh-repos.list
sudo apt update

# Install packages
sudo apt install <package-name>
```

## Release Information
- **Version**: v1.0.5
- **Commit**: 601425f
- **Released**: Sat, 25 Oct 2025 12:34:24 +0000
- **Packages**: 2

## GitHub Pages Configuration
Ensure GitHub Pages is configured to serve from:
- **Source**: Deploy from a branch
- **Branch**: main
- **Folder**: /docs
