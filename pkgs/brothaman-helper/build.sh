#!/bin/bash
# Build script for brothaman-helper package

set -e

echo "Building brothaman-helper..."

# Change to source directory
cd "$(dirname "$0")/src"

# Clean and build
make clean
make

# Create destination directory if it doesn't exist
mkdir -p ../usr/local/bin

# Install binary
cp bro-helper ../usr/local/bin/

# Set permissions
chmod 755 ../usr/local/bin/bro-helper

echo "Build completed successfully!"