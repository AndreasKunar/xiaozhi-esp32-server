#!/bin/bash
# setup-config-arm64.sh
# Configuration setup script for xiaozhi-esp32-server on ARM64 (Jetson Orin NX)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_question() {
    echo -e "${BLUE}[QUESTION]${NC} $1"
}

CONFIG_FILE="main/xiaozhi-server/data/.config.yaml"
CONFIG_DIR="main/xiaozhi-server/data"

print_status "Setting up configuration for Jetson Orin NX deployment..."

# Create data directory if it doesn't exist
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    print_status "Created data directory: $CONFIG_DIR"
fi

# Get local IP address and hostname for Jetson
LOCAL_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)
LOCAL_DOMAIN="${HOSTNAME}.local"

if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="localhost"
fi

print_status "Detected network configuration:"
echo "  - Local IP: $LOCAL_IP"
echo "  - Hostname: $HOSTNAME"
echo "  - mDNS address: $LOCAL_DOMAIN"

# Ask user for IP configuration optimized for Jetson Orin NX
print_question "What address should other systems use to connect to this Jetson?"
echo "  1) Use mDNS hostname: $LOCAL_DOMAIN (recommended for local network)"
echo "  2) Use local IP: $LOCAL_IP (alternative for local network)"
echo "  3) Enter custom IP/domain name"
echo "  4) Use localhost (testing only - other systems won't connect)"
echo ""
read -p "Choice (1-4): " choice

case $choice in
    1)
        DEVICE_IP="$LOCAL_DOMAIN"
        print_status "Using mDNS hostname: $LOCAL_DOMAIN"
        print_status "Other systems can connect using: $LOCAL_DOMAIN"
        ;;
    2)
        DEVICE_IP="$LOCAL_IP"
        print_status "Using local IP: $LOCAL_IP"
        print_status "Other systems can connect using: $LOCAL_IP"
        ;;
    3)
        read -p "Enter IP address or domain name: " DEVICE_IP
        print_status "Using custom address: $DEVICE_IP"
        ;;
    4)
        DEVICE_IP="localhost"
        print_warning "Using localhost - other systems won't be able to connect!"
        ;;
    *)
        DEVICE_IP="$LOCAL_DOMAIN"
        print_status "Using default mDNS hostname: $LOCAL_DOMAIN"
        ;;
esac

# Create configuration file
cat > "$CONFIG_FILE" << EOF
# Configuration override for ARM64 deployment on Jetson Orin NX
# This file overrides settings in config.yaml
# Optimized for Jetson hostname: $HOSTNAME ($LOCAL_DOMAIN)

server:
  # Server configuration optimized for Jetson Orin NX
  # Bind to all interfaces to accept connections from other systems
  ip: 0.0.0.0
  port: 8000
  http_port: 8003
  
  # WebSocket endpoint for devices to connect from other systems
  websocket: ws://${DEVICE_IP}:8000/xiaozhi/v1/
  
  # Vision analysis endpoint accessible from other systems
  vision_explain: http://${DEVICE_IP}:8003/mcp/vision/explain
  
  # Timezone for China
  timezone_offset: +8

# Performance settings optimized for Jetson Orin NX 16GB
performance:
  # Optimize for ARM64 architecture and 16GB memory
  max_concurrent_requests: 12
  request_timeout: 30
  memory_limit_mb: 8192
  
# Logging configuration for containerized deployment
logging:
  level: INFO
  file_rotation: true
  max_size: "50MB"
  backup_count: 3

# Network configuration for local network access
network:
  # Allow connections from other systems in local network
  cors_origins: ["*"]
  max_connection_pool: 100
EOF

print_status "Configuration file created: $CONFIG_FILE"
print_status "Jetson Orin NX network configuration:"
echo "  - Hostname: $HOSTNAME"
echo "  - mDNS address: $LOCAL_DOMAIN"
echo "  - Local IP: $LOCAL_IP"
echo "  - Selected address: $DEVICE_IP"
echo ""
print_status "Service endpoints for other systems:"
echo "  - WebSocket: ws://${DEVICE_IP}:8000/xiaozhi/v1/"
echo "  - Vision API: http://${DEVICE_IP}:8003/mcp/vision/explain"
echo "  - HTTP API: http://${DEVICE_IP}:8003"
echo ""
print_status "Connection options for other systems:"
if [[ "$DEVICE_IP" == *.local ]]; then
    echo "  - Direct: Use $DEVICE_IP (works with mDNS/Bonjour)"
    echo "  - Alternative: Use IP $LOCAL_IP if mDNS doesn't work"
else
    echo "  - Direct: Use $DEVICE_IP"
fi
echo ""

# Create logs directory
LOGS_DIR="logs"
if [ ! -d "$LOGS_DIR" ]; then
    mkdir -p "$LOGS_DIR"
    print_status "Created logs directory: $LOGS_DIR"
fi

print_status "Setup complete!"
echo ""
print_status "Next steps:"
echo "  1. Build the Docker images: ./build-arm64.sh"
echo "  2. Or deploy with Docker Compose: docker compose -f docker-compose-arm64.yml up -d"
echo "  3. Access the service at: http://${DEVICE_IP}:8003"
echo ""
print_warning "Remember to configure your AI service API keys in the config file if needed."