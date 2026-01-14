#!/bin/bash
# build-base-first.sh
# Quick script to build the base image before Docker Compose

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Building ARM64 base image for Jetson Orin NX..."

# Build base image first
docker build \
    --platform linux/arm64 \
    -t xiaozhi-esp32-server:server-base-arm64 \
    -f ./Dockerfile-server-base-arm64 \
    .

if [ $? -eq 0 ]; then
    print_status "✅ Base image built successfully!"
    print_status "Now you can run: docker compose -f docker-compose-arm64.yml up -d"
else
    print_error "❌ Failed to build base image"
    exit 1
fi