#!/bin/bash

# Canary Deployment Simulation Script
# This script simulates a canary deployment locally using Docker and nginx

set -e

echo "🐤 Starting Canary Deployment Simulation"
echo "========================================="

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
STABLE_PORT=3001
CANARY_PORT=3002
NGINX_PORT=3000
CANARY_PERCENTAGE=${1:-10}

echo -e "${BLUE}Canary traffic percentage: ${CANARY_PERCENTAGE}%${NC}"

echo -e "${GREEN}Step 1: Building Docker image...${NC}"
docker build -t gas-app:latest -f docker/Dockerfile .

echo -e "${GREEN}Step 2: Starting Stable environment (current production)...${NC}"
docker run -d --name gas-stable \
  -p $STABLE_PORT:3000 \
  -e DEPLOYMENT_TYPE=stable \
  -e NODE_ENV=production \
  gas-app:latest

echo "Waiting for Stable environment to be ready..."
sleep 5

# Health check for Stable
if curl -f http://localhost:$STABLE_PORT/health > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Stable environment is healthy${NC}"
else
  echo -e "${YELLOW}⚠️  Stable environment health check failed${NC}"
fi

echo -e "${GREEN}Step 3: Starting Canary environment (new version)...${NC}"
docker run -d --name gas-canary \
  -p $CANARY_PORT:3000 \
  -e DEPLOYMENT_TYPE=canary \
  -e NODE_ENV=production \
  gas-app:latest

echo "Waiting for Canary environment to be ready..."
sleep 5

# Health check for Canary
if curl -f http://localhost:$CANARY_PORT/health > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Canary environment is healthy${NC}"
else
  echo -e "${YELLOW}⚠️  Canary environment health check failed${NC}"
  exit 1
fi

echo -e "${BLUE}Step 4: Simulating canary traffic routing...${NC}"
echo "Sending requests to test traffic distribution..."

STABLE_COUNT=0
CANARY_COUNT=0
TOTAL_REQUESTS=100

for i in $(seq 1 $TOTAL_REQUESTS); do
  # Simulate weighted routing
  RANDOM_NUM=$((RANDOM % 100))
  
  if [ $RANDOM_NUM -lt $CANARY_PERCENTAGE ]; then
    curl -s http://localhost:$CANARY_PORT/api > /dev/null
    CANARY_COUNT=$((CANARY_COUNT + 1))
  else
    curl -s http://localhost:$STABLE_PORT/api > /dev/null
    STABLE_COUNT=$((STABLE_COUNT + 1))
  fi
  
  if [ $((i % 20)) -eq 0 ]; then
    echo "  Processed $i/$TOTAL_REQUESTS requests..."
  fi
done

echo ""
echo "Traffic distribution results:"
echo "  Stable: $STABLE_COUNT requests ($((STABLE_COUNT * 100 / TOTAL_REQUESTS))%)"
echo "  Canary: $CANARY_COUNT requests ($((CANARY_COUNT * 100 / TOTAL_REQUESTS))%)"

echo ""
echo -e "${GREEN}Step 5: Monitoring canary metrics...${NC}"
echo "In production, you would monitor:"
echo "  - Error rates"
echo "  - Response times"
echo "  - Resource usage"
echo "  - Business metrics"
echo ""
echo "Check Grafana dashboard at http://localhost:3001 for canary comparison"

echo ""
echo -e "${GREEN}✅ Canary deployment simulation complete!${NC}"
echo ""
echo "Environments running:"
echo "  Stable: http://localhost:$STABLE_PORT"
echo "  Canary: http://localhost:$CANARY_PORT"
echo ""
echo "To promote canary to 100%:"
echo "  ./scripts/promote-canary.sh"
echo ""
echo "To rollback canary:"
echo "  ./scripts/rollback-canary.sh"
echo ""
echo "To clean up:"
echo "  docker stop gas-stable gas-canary"
echo "  docker rm gas-stable gas-canary"

