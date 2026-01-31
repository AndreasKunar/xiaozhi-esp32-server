#!/bin/bash
# try-build-arm64.sh
# Try building ARM64 base image with fallback approaches

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Attempting ARM64 base image build with multiple approaches..."

# Approach 1: Try the optimized Dockerfile first
print_status "Approach 1: Trying optimized Dockerfile-server-base-arm64..."
if docker build --platform linux/arm64 -t xiaozhi-esp32-server:server-base-arm64 -f ./Dockerfile-server-base-arm64 . 2>/dev/null; then
    print_status "✅ Success with optimized Dockerfile!"
    exit 0
else
    print_warning "❌ Optimized Dockerfile failed, trying simple approach..."
fi

# Approach 2: Try the simple Dockerfile
print_status "Approach 2: Trying simple Dockerfile-server-base-arm64-simple..."
if docker build --platform linux/arm64 -t xiaozhi-esp32-server:server-base-arm64 -f ./Dockerfile-server-base-arm64-simple . 2>/dev/null; then
    print_status "✅ Success with simple Dockerfile!"
    exit 0
else
    print_error "❌ Simple Dockerfile also failed."
fi

# Approach 3: Manual debugging
print_error "Both approaches failed. Let's try manual debugging..."
print_status "Building with verbose output to see the exact error..."

docker build --platform linux/arm64 -t xiaozhi-esp32-server:server-base-arm64 -f ./Dockerfile-server-base-arm64-simple . || {
    print_error "Build failed. Common issues on ARM64:"
    echo "1. Some Python packages may not have ARM64 wheels"
    echo "2. PyTorch installation might need different approach"
    echo "3. Build tools might be missing"
    echo ""
    print_status "Suggested fixes:"
    echo "1. Check if all packages support ARM64"
    echo "2. Try installing packages individually"
    echo "3. Use different PyTorch index URL"
    exit 1
}