#!/bin/bash

# Local Setup Script
# Sets up the complete local development environment

set -e

echo "🚀 Setting up GAS Project Local Environment"
echo "==========================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js is not installed. Please install Node.js 18 or higher.${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker is not installed. Please install Docker.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker Compose is not installed. Please install Docker Compose.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are installed${NC}"

# Install dependencies
echo -e "${BLUE}Step 1: Installing Node.js dependencies...${NC}"
npm install

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${BLUE}Step 2: Creating .env file...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created${NC}"
else
    echo -e "${YELLOW}⚠️  .env file already exists, skipping...${NC}"
fi

# Build Docker image
echo -e "${BLUE}Step 3: Building Docker image...${NC}"
docker build -t gas-app:latest -f docker/Dockerfile .

# Start monitoring stack
echo -e "${BLUE}Step 4: Starting monitoring stack (Prometheus + Grafana)...${NC}"
cd docker
docker-compose up -d
cd ..

echo "Waiting for monitoring stack to be ready..."
sleep 10

# Verify monitoring stack
if curl -f http://localhost:9090/-/healthy > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Prometheus is running at http://localhost:9090${NC}"
else
    echo -e "${YELLOW}⚠️  Prometheus health check failed${NC}"
fi

if curl -f http://localhost:3001/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Grafana is running at http://localhost:3001${NC}"
    echo "   Default credentials: admin/admin"
else
    echo -e "${YELLOW}⚠️  Grafana health check failed${NC}"
fi

# Run tests
echo -e "${BLUE}Step 5: Running tests...${NC}"
npm test

echo ""
echo -e "${GREEN}✅ Local setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Start the application:     npm start"
echo "  2. Run in development mode:   npm run dev"
echo "  3. View Prometheus:           http://localhost:9090"
echo "  4. View Grafana:              http://localhost:3001 (admin/admin)"
echo "  5. Simulate blue-green:       ./scripts/simulate-blue-green.sh"
echo "  6. Simulate canary:           ./scripts/simulate-canary.sh 10"
echo ""
echo "To clean up everything:"
echo "  ./scripts/cleanup.sh"

