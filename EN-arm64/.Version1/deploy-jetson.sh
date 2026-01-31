#!/bin/bash
# deploy-jetson.sh
# Complete deployment script for xiaozhi-esp32-server on Jetson Orin NX

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if running on ARM64
print_header "Jetson Orin NX Deployment Script"
print_status "Checking system compatibility..."

if [[ "$(uname -m)" != "aarch64" ]]; then
    print_error "This script is designed for ARM64 architecture (Jetson Orin NX)"
    print_error "Current architecture: $(uname -m)"
    exit 1
fi

# Check system resources
print_status "System information:"
echo "  - Architecture: $(uname -m)"
echo "  - OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
echo "  - Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "  - Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    print_status "Run: curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running"
    print_status "Run: sudo systemctl start docker"
    exit 1
fi

# Ask for deployment method
print_header "Deployment Options"
echo "Choose deployment method:"
echo "  1) Quick start with Docker Compose (recommended)"
echo "  2) Manual build and run"
echo "  3) Configuration setup only"
echo ""
read -p "Choice (1-3): " deploy_choice

case $deploy_choice in
    1)
        print_header "Quick Start Deployment"
        
        print_status "Step 1: Setting up configuration..."
        ./setup-config-arm64.sh
        
        print_status "Step 2: Building base image first..."
        docker build --platform linux/arm64 -t xiaozhi-esp32-server:server-base-arm64 -f ./Dockerfile-server-base-arm64 .
        
        if [ $? -ne 0 ]; then
            print_error "❌ Failed to build base image"
            exit 1
        fi
        
        print_status "Step 3: Deploying with Docker Compose..."
        docker compose -f docker-compose-arm64.yml up -d --build
        
        if [ $? -eq 0 ]; then
            print_status "✅ Deployment successful!"
            HOSTNAME=$(hostname)
            LOCAL_DOMAIN="${HOSTNAME}.local"
            LOCAL_IP=$(hostname -I | awk '{print $1}')
            echo ""
            print_status "🚀 Jetson Orin NX deployment complete!"
            echo ""
            print_status "Service URLs for other systems to connect:"
            echo "  📡 Primary (mDNS): http://${LOCAL_DOMAIN}:8003"
            echo "  📡 WebSocket (mDNS): ws://${LOCAL_DOMAIN}:8000"
            echo "  🌐 Alternative (IP): http://${LOCAL_IP}:8003"
            echo "  🌐 WebSocket (IP): ws://${LOCAL_IP}:8000"
            echo ""
            print_status "Local access (from this Jetson):"
            echo "  - HTTP API: http://localhost:8003"
            echo "  - WebSocket: ws://localhost:8000"
            echo ""
            print_status "Useful commands:"
            echo "  - Check status: docker compose -f docker-compose-arm64.yml ps"
            echo "  - View logs: docker compose -f docker-compose-arm64.yml logs -f"
            echo "  - Stop service: docker compose -f docker-compose-arm64.yml down"
        else
            print_error "❌ Deployment failed"
            exit 1
        fi
        ;;
    2)
        print_header "Manual Build and Run"
        
        print_status "Step 1: Setting up configuration..."
        ./setup-config-arm64.sh
        
        print_status "Step 2: Building Docker images..."
        ./build-arm64.sh
        
        if [ $? -eq 0 ]; then
            print_status "Step 3: Starting container..."
            docker run -d \
                --name xiaozhi-server \
                -p 8003:8003 \
                -p 8000:8000 \
                -v $(pwd)/main/xiaozhi-server/data:/opt/xiaozhi-esp32-server/data \
                -v $(pwd)/logs:/opt/xiaozhi-esp32-server/logs \
                --restart unless-stopped \
                xiaozhi-esp32-server:server-arm64
            
            if [ $? -eq 0 ]; then
                print_status "✅ Container started successfully!"
                HOSTNAME=$(hostname)
                LOCAL_DOMAIN="${HOSTNAME}.local"
                LOCAL_IP=$(hostname -I | awk '{print $1}')
                echo ""
                print_status "🚀 Jetson Orin NX deployment complete!"
                echo ""
                print_status "Service URLs for other systems to connect:"
                echo "  📡 Primary (mDNS): http://${LOCAL_DOMAIN}:8003"
                echo "  📡 WebSocket (mDNS): ws://${LOCAL_DOMAIN}:8000"
                echo "  🌐 Alternative (IP): http://${LOCAL_IP}:8003"
                echo "  🌐 WebSocket (IP): ws://${LOCAL_IP}:8000"
                echo ""
                print_status "Local access (from this Jetson):"
                echo "  - HTTP API: http://localhost:8003"
                echo "  - WebSocket: ws://localhost:8000"
                echo ""
                print_status "Useful commands:"
                echo "  - Check status: docker ps"
                echo "  - View logs: docker logs -f xiaozhi-server"
                echo "  - Stop service: docker stop xiaozhi-server"
            else
                print_error "❌ Failed to start container"
                exit 1
            fi
        else
            print_error "❌ Build failed"
            exit 1
        fi
        ;;
    3)
        print_header "Configuration Setup Only"
        ./setup-config-arm64.sh
        print_status "Configuration complete. You can now build and deploy manually."
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

print_header "Deployment Complete!"
print_status "For more details, see: DEPLOYMENT-ARM64.md"