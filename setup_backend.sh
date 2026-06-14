#!/bin/bash

# Complete Backend + Flutter Connectivity Setup & Testing Script
# Run from repository root

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  BACKEND + FLUTTER LAN CONNECTIVITY FIX                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get host IP (Linux/WSL compatible)
get_host_ip() {
    if command -v hostname &> /dev/null; then
        hostname -I | awk '{print $1}'
    elif command -v ipconfig &> /dev/null; then
        ipconfig | grep "IPv4 Address" | head -1 | awk '{print $NF}'
    else
        echo "192.168.1.123"
    fi
}

HOST_IP=$(get_host_ip)

echo -e "${BLUE}🔍 Detected Host IP: ${YELLOW}${HOST_IP}${NC}"
echo ""

# Phase 1: Verify Backend is Running
echo -e "${BLUE}▶ PHASE 1: Verifying backend services...${NC}"
cd Backend/core

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found. Please install Docker first.${NC}"
    exit 1
fi

docker compose ps

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker Compose is accessible${NC}"
else
    echo -e "${RED}✗ Docker Compose failed. Make sure Docker is running.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}▶ PHASE 2: Starting backend services...${NC}"

# Update ALLOWED_HOSTS dynamically
echo "  Updating ALLOWED_HOSTS in .env.docker..."
sed -i "s/ALLOWED_HOSTS=.*/ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,${HOST_IP},192.168.1.123,192.168.56.1,192.168.56.2/" .env.docker

echo "  Starting services..."
docker compose down 2>/dev/null || true
docker compose up -d

echo -e "${GREEN}✓ Waiting for services to become healthy...${NC}"
sleep 15

docker compose ps

echo ""
echo -e "${BLUE}▶ PHASE 3: Testing backend connectivity...${NC}"

# Test 1: Localhost
echo -n "  Testing localhost (http://localhost:8000/health/)... "
if curl -s http://localhost:8000/health/ | grep -q "ok"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "    Backend may not be fully initialized. Waiting..."
    sleep 5
fi

# Test 2: LAN IP
echo -n "  Testing LAN IP (http://${HOST_IP}:8000/health/)... "
if curl -s http://${HOST_IP}:8000/health/ | grep -q "ok"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Backend not reachable on LAN IP${NC}"
    echo "    Possible causes:"
    echo "    - Firewall blocking port 8000"
    echo "    - Wrong IP address"
    echo "    - Backend not running"
fi

# Check Django Configuration
echo ""
echo -e "${BLUE}▶ PHASE 4: Checking Django configuration...${NC}"
echo "  ALLOWED_HOSTS:"
docker compose exec web python -c "from django.conf import settings; print('   ', settings.ALLOWED_HOSTS)" || echo "    (Could not retrieve)"

echo "  CORS_ALLOW_ALL_ORIGINS:"
docker compose exec web python -c "from django.conf import settings; print('   ', settings.CORS_ALLOW_ALL_ORIGINS)" || echo "    (Could not retrieve)"

echo ""
echo -e "${BLUE}▶ PHASE 5: Backend logs (last 20 lines)...${NC}"
docker compose logs --tail 20 web || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo -e "${GREEN}✓ BACKEND SETUP COMPLETE${NC}"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

cd - > /dev/null

echo -e "${BLUE}▶ PHASE 6: Flutter configuration...${NC}"
echo ""
echo "Update Flutter to use correct backend IP:"
echo ""
echo "Option 1 - Run with environment variable (RECOMMENDED):"
echo -e "  ${YELLOW}flutter run --dart-define=API_BASE_URL=http://${HOST_IP}:8000${NC}"
echo ""
echo "Option 2 - For Android Emulator:"
echo -e "  ${YELLOW}flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000${NC}"
echo ""
echo "Option 3 - For iOS Simulator:"
echo -e "  ${YELLOW}flutter run --dart-define=API_BASE_URL=http://localhost:8000${NC}"
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo -e "${GREEN}✅ SETUP COMPLETE!${NC}"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "1. On your physical device (same WiFi), open browser:"
echo -e "   ${YELLOW}http://${HOST_IP}:8000/health/${NC}"
echo "   Should see: {\"status\":\"ok\"}"
echo ""
echo "2. Then run Flutter app from Flutter directory:"
echo -e "   ${YELLOW}cd apps/shop_manager${NC}"
echo -e "   ${YELLOW}flutter run --dart-define=API_BASE_URL=http://${HOST_IP}:8000${NC}"
echo ""
echo "3. Watch Flutter logs:"
echo -e "   ${YELLOW}flutter logs${NC}"
echo ""

if [ $(uname -s) == "Darwin" ]; then
    echo "🍎 macOS detected - Port 8000 should be open by default"
elif [ $(uname -s) == "Linux" ]; then
    echo "🐧 Linux detected - UFW firewall rule:"
    echo -e "   ${YELLOW}sudo ufw allow 8000/tcp${NC}"
else
    echo "🪟 Windows detected - Run as Administrator:"
    echo -e "   ${YELLOW}setup_firewall.bat${NC}"
fi

echo ""
