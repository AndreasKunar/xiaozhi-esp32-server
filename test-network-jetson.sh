#!/bin/bash
# test-network-jetson.sh
# Network connectivity test script for Jetson Orin NX deployment

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

print_header "Jetson Orin NX Network Test"

# Get network information
HOSTNAME=$(hostname)
LOCAL_DOMAIN="${HOSTNAME}.local"
LOCAL_IP=$(hostname -I | awk '{print $1}')

print_status "Network Configuration:"
echo "  - Hostname: $HOSTNAME"
echo "  - mDNS address: $LOCAL_DOMAIN"
echo "  - Local IP: $LOCAL_IP"
echo "  - SSH name: jn2 (AndreasKJN2.local)"
echo ""

# Test if services are running
print_status "Testing service availability..."

# Test HTTP port
echo -n "  HTTP port 8003: "
if curl -s --connect-timeout 5 http://localhost:8003 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ RUNNING${NC}"
    HTTP_RUNNING=true
else
    echo -e "${RED}✗ NOT ACCESSIBLE${NC}"
    HTTP_RUNNING=false
fi

# Test WebSocket port
echo -n "  WebSocket port 8000: "
if nc -z localhost 8000 2>/dev/null; then
    echo -e "${GREEN}✓ LISTENING${NC}"
    WS_RUNNING=true
else
    echo -e "${RED}✗ NOT LISTENING${NC}"
    WS_RUNNING=false
fi

echo ""

# Test network accessibility
print_status "Testing network accessibility..."

# Test mDNS resolution
echo -n "  mDNS resolution ($LOCAL_DOMAIN): "
if ping -c 1 -W 2 "$LOCAL_DOMAIN" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ WORKING${NC}"
else
    echo -e "${YELLOW}⚠ MAY NOT WORK${NC} (depends on client mDNS support)"
fi

# Test if ports are accessible from outside
echo -n "  External port accessibility: "
if netstat -ln | grep -E "(8003|8000)" | grep "0.0.0.0" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ PORTS BOUND TO ALL INTERFACES${NC}"
else
    echo -e "${YELLOW}⚠ CHECK FIREWALL SETTINGS${NC}"
fi

echo ""

# Connection instructions
print_status "📱 Connection Instructions for Other Systems:"
echo ""

if [ "$HTTP_RUNNING" = true ] || [ "$WS_RUNNING" = true ]; then
    echo "✅ Services are running! Other systems can connect using:"
    echo ""
    echo "🔗 Primary addresses (use these first):"
    echo "   - HTTP API: http://${LOCAL_DOMAIN}:8003"
    echo "   - WebSocket: ws://${LOCAL_DOMAIN}:8000/xiaozhi/v1/"
    echo ""
    echo "🔗 Alternative addresses (if mDNS doesn't work):"
    echo "   - HTTP API: http://${LOCAL_IP}:8003"
    echo "   - WebSocket: ws://${LOCAL_IP}:8000/xiaozhi/v1/"
    echo ""
    echo "🔗 From SSH connection:"
    echo "   - You're connected via: $HOSTNAME (jn2)"
    echo "   - Forward ports: ssh -L 8003:localhost:8003 -L 8000:localhost:8000 jn2"
else
    echo "❌ Services are not running!"
    echo ""
    echo "To start the services:"
    echo "  1. Run: ./deploy-jetson.sh"
    echo "  2. Or: docker compose -f docker-compose-arm64.yml up -d"
fi

echo ""

# Firewall check
print_status "🛡️ Firewall Status:"
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null | grep "Status:" | awk '{print $2}' || echo "unknown")
    echo "  - UFW status: $UFW_STATUS"
    if [ "$UFW_STATUS" = "active" ]; then
        print_warning "UFW is active. You may need to open ports 8003 and 8000:"
        echo "    sudo ufw allow 8003"
        echo "    sudo ufw allow 8000"
    fi
else
    echo "  - UFW not installed (likely no restrictions)"
fi

echo ""

# Docker status
print_status "🐳 Docker Container Status:"
if command -v docker >/dev/null 2>&1; then
    if docker ps | grep xiaozhi >/dev/null 2>&1; then
        echo "  ✅ xiaozhi containers running:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep xiaozhi || true
    else
        echo "  ❌ No xiaozhi containers running"
    fi
else
    echo "  ❌ Docker not available"
fi

echo ""
print_status "Test complete! Use the connection addresses above from other systems."