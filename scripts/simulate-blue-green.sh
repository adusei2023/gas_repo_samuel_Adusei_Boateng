#!/bin/bash

# Blue-Green Deployment Simulation Script
# This script simulates a blue-green deployment locally using Docker

set -e

echo "🔵 Starting Blue-Green Deployment Simulation"
echo "=============================================="

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BLUE_PORT=3001
GREEN_PORT=3002
NGINX_PORT=3000

echo -e "${BLUE}Step 1: Building Docker image...${NC}"
docker build -t gas-app:latest -f docker/Dockerfile .

echo -e "${GREEN}Step 2: Starting Blue environment (current production)...${NC}"
docker run -d --name gas-blue \
  -p $BLUE_PORT:3000 \
  -e DEPLOYMENT_TYPE=blue \
  -e NODE_ENV=production \
  gas-app:latest

echo "Waiting for Blue environment to be ready..."
sleep 5

# Health check for Blue
if curl -f http://localhost:$BLUE_PORT/health > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Blue environment is healthy${NC}"
else
  echo -e "${YELLOW}⚠️  Blue environment health check failed${NC}"
fi

echo -e "${GREEN}Step 3: Starting Green environment (new version)...${NC}"
docker run -d --name gas-green \
  -p $GREEN_PORT:3000 \
  -e DEPLOYMENT_TYPE=green \
  -e NODE_ENV=production \
  gas-app:latest

echo "Waiting for Green environment to be ready..."
sleep 5

# Health check for Green
if curl -f http://localhost:$GREEN_PORT/health > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Green environment is healthy${NC}"
else
  echo -e "${YELLOW}⚠️  Green environment health check failed${NC}"
  exit 1
fi

echo -e "${BLUE}Step 4: Running tests on Green environment...${NC}"
TEST_URL=http://localhost:$GREEN_PORT npm run test:e2e

echo -e "${GREEN}Step 5: Simulating traffic switch...${NC}"
echo "In production, this would update the load balancer to route traffic to Green"
echo "Current setup:"
echo "  - Blue (old):  http://localhost:$BLUE_PORT"
echo "  - Green (new): http://localhost:$GREEN_PORT"

echo ""
echo -e "${GREEN}✅ Blue-Green deployment simulation complete!${NC}"
echo ""
echo "To test the environments:"
echo "  Blue:  curl http://localhost:$BLUE_PORT"
echo "  Green: curl http://localhost:$GREEN_PORT"
echo ""
echo "To clean up:"
echo "  docker stop gas-blue gas-green"
echo "  docker rm gas-blue gas-green"

