#!/usr/bin/env bash
set -euo pipefail

# clean-cache.sh - Clean build caches to force fresh installs
# Useful when you want to rebuild everything from scratch

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🧹 Cleaning build caches..."

# Clean MkDocs virtual environment
VENV_DIR="$HOME/.local/mkdocs-venv"
if [[ -d "$VENV_DIR" ]]; then
    echo "🗑️  Removing MkDocs virtual environment..."
    rm -rf "$VENV_DIR"
    echo "   ✅ MkDocs venv removed"
else
    echo "   ℹ️  No MkDocs venv to remove"
fi

# Clean Docker images (only if not in container)
if [[ -z "${REMOTE_CONTAINERS:-}" && -z "${CODESPACES:-}" && ! -f "/.dockerenv" ]]; then
    if command -v docker &> /dev/null; then
        echo "🗑️  Removing cached container images..."
        
        # Remove gh-repos-build images
        IMAGES_TO_REMOVE=$(docker images gh-repos-build --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || true)
        if [[ -n "$IMAGES_TO_REMOVE" ]]; then
            echo "$IMAGES_TO_REMOVE" | xargs docker rmi 2>/dev/null || true
            echo "   ✅ Container images removed"
        else
            echo "   ℹ️  No container images to remove"
        fi
        
        # Clean up dangling images
        DANGLING=$(docker images -f "dangling=true" -q 2>/dev/null || true)
        if [[ -n "$DANGLING" ]]; then
            echo "🗑️  Cleaning up dangling images..."
            echo "$DANGLING" | xargs docker rmi 2>/dev/null || true
            echo "   ✅ Dangling images cleaned"
        fi
    else
        echo "   ℹ️  Docker not available, skipping image cleanup"
    fi
else
    echo "   ℹ️  Running in container, skipping Docker image cleanup"
fi

# Clean docs directory  
DOCS_DIR="$WORKSPACE_ROOT/docs"
if [[ -d "$DOCS_DIR" ]]; then
    echo "🗑️  Removing generated docs..."
    # Preserve apt/ directory if it exists
    if [[ -d "$DOCS_DIR/apt" ]]; then
        echo "   💾 Preserving apt/ directory..."
        mv "$DOCS_DIR/apt" "$DOCS_DIR.apt.backup" 2>/dev/null || true
    fi
    
    rm -rf "$DOCS_DIR"
    
    # Restore apt/ directory if we backed it up
    if [[ -d "$DOCS_DIR.apt.backup" ]]; then
        mkdir -p "$DOCS_DIR"
        mv "$DOCS_DIR.apt.backup" "$DOCS_DIR/apt"
        echo "   ✅ Docs cleaned (apt/ preserved)"
    else
        echo "   ✅ Docs directory removed"
    fi
else
    echo "   ℹ️  No docs directory to clean"
fi

echo ""
echo "✨ Cache cleanup complete!"
echo "💡 Next build will install everything fresh"