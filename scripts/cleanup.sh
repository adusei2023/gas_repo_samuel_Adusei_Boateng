#!/bin/bash

# Cleanup Script
# Stops and removes all Docker containers and cleans up resources

echo "🧹 Cleaning up Docker containers and resources..."

# Stop and remove application containers
echo "Stopping application containers..."
docker stop gas-blue gas-green gas-stable gas-canary 2>/dev/null || true
docker rm gas-blue gas-green gas-stable gas-canary 2>/dev/null || true

# Stop and remove monitoring stack
echo "Stopping monitoring stack..."
cd docker
docker-compose down -v 2>/dev/null || true
cd ..

# Remove dangling images
echo "Removing dangling images..."
docker image prune -f

echo "✅ Cleanup complete!"

