#!/usr/bin/env bash
set -euo pipefail

# build.sh - Main build orchestrator script
# This script runs on the HOST and executes container scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting GH-Repos build process..."
echo "════════════════════════════════════"

# Function to check cache status
check_cache_status() {
    echo "📊 Cache Status Check:"
    
    # Check MkDocs venv cache
    VENV_DIR="$HOME/.local/mkdocs-venv"
    if [[ -f "$VENV_DIR/bin/mkdocs" && -f "$VENV_DIR/.requirements_hash" ]]; then
        echo "   ✅ MkDocs virtual environment cached"
    else
        echo "   🔄 MkDocs virtual environment will be created"
    fi
    
    # Check container image cache (only when running on host)
    if [[ -z "${REMOTE_CONTAINERS:-}" && -z "${CODESPACES:-}" && ! -f "/.dockerenv" ]]; then
        if command -v docker &> /dev/null; then
            if docker images gh-repos-build --format "table {{.Repository}}" | grep -q gh-repos-build; then
                echo "   ✅ Container image cached"
            else
                echo "   🔄 Container image will be built"
            fi
        fi
    fi
    
    echo ""
}

# Show cache status first
check_cache_status

# Git configuration removed - not needed without git-revision-date plugin

# Fix common permission issues when running in container
if [[ "${REMOTE_CONTAINERS:-}" == "true" ]] || [[ "${CODESPACES:-}" == "true" ]] || [[ -f "/.dockerenv" ]]; then
    echo "🔧 Ensuring proper permissions..."
    # Fix ownership of workspace files
    sudo chown -R "$(id -u):$(id -g)" "$WORKSPACE_ROOT" 2>/dev/null || true
    # Ensure we can write to key directories
    sudo chmod -R u+w "$WORKSPACE_ROOT" 2>/dev/null || true
fi

# Check if we're in a dev container or need to use docker
if [[ "${REMOTE_CONTAINERS:-}" == "true" ]] || [[ "${CODESPACES:-}" == "true" ]] || [[ -f "/.dockerenv" ]]; then
    echo "📦 Running inside container - executing scripts directly"
    CONTAINER_CMD=""
else
    echo "🐳 Running on host - will execute scripts in container"
    
    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        echo "❌ Error: Docker is not installed or not in PATH"
        echo "💡 Please install Docker or run this script inside a dev container"
        exit 1
    fi
    
    # Check if dev container image exists or build it
    IMAGE_NAME="gh-repos-build"
    DOCKERFILE_PATH="$WORKSPACE_ROOT/.devcontainer/Dockerfile"
    DEVCONTAINER_JSON="$WORKSPACE_ROOT/.devcontainer/devcontainer.json"
    
    # Create hash of devcontainer files to detect changes
    if [[ -f "$DOCKERFILE_PATH" ]] && [[ -f "$DEVCONTAINER_JSON" ]]; then
        DEVCONTAINER_HASH=$(cat "$DOCKERFILE_PATH" "$DEVCONTAINER_JSON" | sha256sum | cut -d' ' -f1)
        EXPECTED_TAG="$IMAGE_NAME:$DEVCONTAINER_HASH"
        
        # Check if we have the exact image we need
        if docker image inspect "$EXPECTED_TAG" &> /dev/null; then
            echo "✅ Found cached container image ($EXPECTED_TAG)"
            IMAGE_NAME="$EXPECTED_TAG"
        else
            echo "🔨 Building dev container image (configuration changed)..."
            
            # Remove old images to save space
            docker images "$IMAGE_NAME" --format "table {{.Repository}}:{{.Tag}}" | grep -v REPOSITORY | xargs -r docker rmi 2>/dev/null || true
            
            # Build new image with hash tag
            docker build -t "$EXPECTED_TAG" "$WORKSPACE_ROOT/.devcontainer/"
            docker tag "$EXPECTED_TAG" "$IMAGE_NAME"  # Also tag as latest for compatibility
            IMAGE_NAME="$EXPECTED_TAG"
            
            echo "✅ Container image built and cached"
        fi
    else
        echo "❌ Error: .devcontainer/Dockerfile or devcontainer.json not found"
        echo "💡 Please set up the dev container or run inside VS Code dev container"
        exit 1
    fi
    
    # Set up container command
    CONTAINER_CMD="docker run --rm -v \"$WORKSPACE_ROOT:/workspace\" -w /workspace \"$IMAGE_NAME\""
fi

# Function to run script in container
run_in_container() {
    local script_name="$1"
    local script_path="/workspace/scripts/$script_name"
    
    echo ""
    echo "▶️  Executing $script_name..."
    echo "────────────────────────────────"
    
    if [[ -n "$CONTAINER_CMD" ]]; then
        eval "$CONTAINER_CMD bash $script_path"
    else
        bash "$WORKSPACE_ROOT/scripts/$script_name"
    fi
    
    if [[ $? -eq 0 ]]; then
        echo "✅ $script_name completed successfully"
    else
        echo "❌ $script_name failed"
        exit 1
    fi
}

# Execute build steps in order
echo "📋 Build plan:"
echo "   1. Generate website with MkDocs"
echo "   2. Build Debian packages"
echo "   3. Create APT repository structure"
echo ""

# Step 1: Generate MkDocs website
run_in_container "mkdocs.sh"

# Step 2: Build Debian packages
run_in_container "mkdebs.sh"

# Step 3: Create APT repository
run_in_container "mkrepo.sh"

echo ""
echo "🎉 Build process completed successfully!"
echo "════════════════════════════════════════"
echo "✅ Website generated in: docs/"
echo "✅ APT repository created in: docs/apt/"
echo ""
echo "📋 Next steps:"
echo "   1. Review generated files in docs/"
echo "   2. Run signrepo.sh to sign the repository (on host)"
echo "   3. Run publish.sh to commit and deploy"
echo "   4. Run release.sh to create GitHub release"
echo ""
echo "⚠️  Note: Repository is currently UNSIGNED"
echo "🔐 Run signrepo.sh on the host to sign with your GPG key"

