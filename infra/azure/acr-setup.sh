#!/bin/bash

################################################################################
# Azure Container Registry (ACR) Setup Script
#
# This script helps you:
# 1. Build your Docker image
# 2. Tag it for ACR
# 3. Login to ACR
# 4. Push the image to ACR
# 5. Verify the image is available
#
# Prerequisites:
# - Docker installed and running
# - Azure CLI installed
# - ACR already created (run create-resources.sh first)
#
# Usage:
#   ./acr-setup.sh <acr-name> <image-tag>
#
# Example:
#   ./acr-setup.sh gasappacr v1.0.0
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
ACR_NAME="${1}"
IMAGE_TAG="${2:-latest}"
IMAGE_NAME="gas-app"
DOCKERFILE_PATH="docker/Dockerfile"

# Validate inputs
if [ -z "$ACR_NAME" ]; then
    print_error "ACR name is required!"
    echo ""
    echo "Usage: $0 <acr-name> [image-tag]"
    echo ""
    echo "Example:"
    echo "  $0 gasappacr v1.0.0"
    echo ""
    echo "To find your ACR name, run:"
    echo "  az acr list --query '[].name' -o tsv"
    exit 1
fi

print_info "Starting ACR setup..."
echo ""
print_info "Configuration:"
echo "  ACR Name: $ACR_NAME"
echo "  Image Name: $IMAGE_NAME"
echo "  Image Tag: $IMAGE_TAG"
echo "  Dockerfile: $DOCKERFILE_PATH"
echo ""

################################################################################
# Step 1: Check Prerequisites
################################################################################
print_info "Step 1: Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

print_success "Docker is installed and running"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

print_success "Azure CLI is installed"

# Check if logged in
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

print_success "Logged in to Azure"

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
    print_error "Dockerfile not found at: $DOCKERFILE_PATH"
    exit 1
fi

print_success "Dockerfile found"
echo ""

################################################################################
# Step 2: Get ACR Information
################################################################################
print_info "Step 2: Retrieving ACR information..."

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv 2>/dev/null)

if [ -z "$ACR_LOGIN_SERVER" ]; then
    print_error "ACR '$ACR_NAME' not found. Please create it first using create-resources.sh"
    exit 1
fi

print_success "ACR Login Server: $ACR_LOGIN_SERVER"

# Full image name with tag
FULL_IMAGE_NAME="$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
print_info "Full Image Name: $FULL_IMAGE_NAME"
echo ""

################################################################################
# Step 3: Build Docker Image
################################################################################
print_info "Step 3: Building Docker image..."
print_warning "This may take a few minutes..."

# Build the image
docker build \
    -t "$IMAGE_NAME:$IMAGE_TAG" \
    -t "$IMAGE_NAME:latest" \
    -f "$DOCKERFILE_PATH" \
    .

print_success "Docker image built successfully"
echo ""

################################################################################
# Step 4: Tag Image for ACR
################################################################################
print_info "Step 4: Tagging image for ACR..."

docker tag "$IMAGE_NAME:$IMAGE_TAG" "$FULL_IMAGE_NAME"
docker tag "$IMAGE_NAME:$IMAGE_TAG" "$ACR_LOGIN_SERVER/$IMAGE_NAME:latest"

print_success "Image tagged for ACR"
echo ""

################################################################################
# Step 5: Login to ACR
################################################################################
print_info "Step 5: Logging in to ACR..."

# Login using Azure CLI (recommended)
az acr login --name "$ACR_NAME"

print_success "Logged in to ACR"
echo ""

################################################################################
# Step 6: Push Image to ACR
################################################################################
print_info "Step 6: Pushing image to ACR..."
print_warning "This may take a few minutes depending on your internet speed..."

# Push the tagged image
docker push "$FULL_IMAGE_NAME"

# Also push the latest tag
if [ "$IMAGE_TAG" != "latest" ]; then
    docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME:latest"
fi

print_success "Image pushed to ACR successfully"
echo ""

################################################################################
# Step 7: Verify Image in ACR
################################################################################
print_info "Step 7: Verifying image in ACR..."

# List images in ACR
print_info "Images in ACR:"
az acr repository show-tags \
    --name "$ACR_NAME" \
    --repository "$IMAGE_NAME" \
    --output table

print_success "Image verified in ACR"
echo ""

################################################################################
# Summary
################################################################################
print_success "=========================================="
print_success "ACR Setup Complete!"
print_success "=========================================="
echo ""
print_info "Image Details:"
print_info "  Repository: $ACR_LOGIN_SERVER/$IMAGE_NAME"
print_info "  Tag: $IMAGE_TAG"
print_info "  Full Name: $FULL_IMAGE_NAME"
echo ""
print_info "Next Steps:"
echo ""
print_info "1. Update your App Service to use this image:"
print_info "   az webapp config container set \\"
print_info "     --name <app-name> \\"
print_info "     --resource-group <resource-group> \\"
print_info "     --docker-custom-image-name $FULL_IMAGE_NAME"
echo ""
print_info "2. Restart your App Service:"
print_info "   az webapp restart --name <app-name> --resource-group <resource-group>"
echo ""
print_info "3. View logs:"
print_info "   az webapp log tail --name <app-name> --resource-group <resource-group>"
echo ""
print_info "4. Test your application:"
print_info "   curl https://<app-name>.azurewebsites.net/health"
echo ""
print_success "Done! 🎉"
