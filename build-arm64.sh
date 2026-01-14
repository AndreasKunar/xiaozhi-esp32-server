#!/bin/bash
# build-arm64.sh
# Build script for xiaozhi-esp32-server on ARM64 architecture (Jetson Orin NX)

set -e

echo "Building xiaozhi-esp32-server for ARM64..."
echo "Platform: $(uname -m)"
echo "OS: $(lsb_release -d 2>/dev/null || echo 'Unknown')"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're on ARM64
if [[ "$(uname -m)" != "aarch64" ]]; then
    print_warning "Warning: This script is optimized for ARM64/aarch64. Current architecture: $(uname -m)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Docker availability
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running"
    exit 1
fi

print_status "Building base image for ARM64..."
# Build the base image first
docker build \
    --platform linux/arm64 \
    -t xiaozhi-esp32-server:server-base-arm64 \
    -f ./Dockerfile-server-base-arm64 \
    .

if [ $? -eq 0 ]; then
    print_status "Base image built successfully!"
else
    print_error "Failed to build base image"
    exit 1
fi

print_status "Building server image for ARM64..."
# Build the server image
docker build \
    --platform linux/arm64 \
    -t xiaozhi-esp32-server:server-arm64 \
    -f ./Dockerfile-server-arm64 \
    .

if [ $? -eq 0 ]; then
    print_status "Server image built successfully!"
    print_status "Images created:"
    docker images | grep xiaozhi-esp32-server
    
    echo ""
    print_status "To run the container:"
    echo "docker run -d --name xiaozhi-server -p 8003:8003 -p 8000:8000 xiaozhi-esp32-server:server-arm64"
    
    echo ""
    print_status "To run with GPU support (if needed):"
    echo "docker run -d --name xiaozhi-server --gpus all -p 8003:8003 -p 8000:8000 xiaozhi-esp32-server:server-arm64"
    
else
    print_error "Failed to build server image"
    exit 1
fi