#!/bin/bash

################################################################################
# Azure Resources Creation Script
#
# This script creates all the Azure resources needed for the GAS project:
# - Resource Group
# - Container Registry (ACR)
# - App Service Plan
# - App Service (Web App)
# - Deployment Slots (for blue-green deployment)
#
# Prerequisites:
# - Azure CLI installed (az --version)
# - Logged in to Azure (az login)
# - Appropriate permissions to create resources
#
# Usage:
#   ./create-resources.sh
#
# Or with custom parameters:
#   ./create-resources.sh <resource-group> <location> <app-name>
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

# Configuration variables (customize these)
RESOURCE_GROUP="${1:-gas-project-rg}"
LOCATION="${2:-eastus}"
APP_NAME="${3:-gas-app-$(date +%s)}"  # Unique name with timestamp
ACR_NAME="${APP_NAME//-/}acr"  # Remove hyphens for ACR name
APP_SERVICE_PLAN="${APP_NAME}-plan"
ACR_SKU="Basic"
APP_SERVICE_SKU="B1"  # Basic tier (cheapest for learning)

print_info "Starting Azure resource creation..."
echo ""
print_info "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  App Name: $APP_NAME"
echo "  ACR Name: $ACR_NAME"
echo "  App Service Plan: $APP_SERVICE_PLAN"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    print_info "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in to Azure
print_info "Checking Azure login status..."
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
print_success "Logged in to Azure"
print_info "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo ""

################################################################################
# Step 1: Create Resource Group
################################################################################
print_info "Step 1: Creating Resource Group..."

if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    print_warning "Resource group '$RESOURCE_GROUP' already exists. Skipping creation."
else
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --tags "project=gas" "environment=learning" "created-by=script"

    print_success "Resource group created: $RESOURCE_GROUP"
fi
echo ""

################################################################################
# Step 2: Create Azure Container Registry (ACR)
################################################################################
print_info "Step 2: Creating Azure Container Registry..."

if az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    print_warning "ACR '$ACR_NAME' already exists. Skipping creation."
else
    az acr create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$ACR_NAME" \
        --sku "$ACR_SKU" \
        --admin-enabled true \
        --tags "project=gas" "environment=learning"

    print_success "Container Registry created: $ACR_NAME"
fi

# Get ACR credentials
print_info "Retrieving ACR credentials..."
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query passwords[0].value -o tsv)

print_success "ACR Login Server: $ACR_LOGIN_SERVER"
print_info "ACR Username: $ACR_USERNAME"
print_warning "ACR Password: [hidden - stored in credentials file]"
echo ""

################################################################################
# Step 3: Create App Service Plan
################################################################################
print_info "Step 3: Creating App Service Plan..."

if az appservice plan show --name "$APP_SERVICE_PLAN" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    print_warning "App Service Plan '$APP_SERVICE_PLAN' already exists. Skipping creation."
else
    az appservice plan create \
        --name "$APP_SERVICE_PLAN" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --is-linux \
        --sku "$APP_SERVICE_SKU" \
        --tags "project=gas" "environment=learning"

    print_success "App Service Plan created: $APP_SERVICE_PLAN"
fi
echo ""

################################################################################
# Step 4: Create Web App (App Service)
################################################################################
print_info "Step 4: Creating Web App..."

if az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    print_warning "Web App '$APP_NAME' already exists. Skipping creation."
else
    az webapp create \
        --resource-group "$RESOURCE_GROUP" \
        --plan "$APP_SERVICE_PLAN" \
        --name "$APP_NAME" \
        --deployment-container-image-name "mcr.microsoft.com/appsvc/staticsite:latest" \
        --tags "project=gas" "environment=production"

    print_success "Web App created: $APP_NAME"
fi

# Configure Web App to use ACR
print_info "Configuring Web App to use ACR..."
az webapp config container set \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --docker-custom-image-name "$ACR_LOGIN_SERVER/gas-app:latest" \
    --docker-registry-server-url "https://$ACR_LOGIN_SERVER" \
    --docker-registry-server-user "$ACR_USERNAME" \
    --docker-registry-server-password "$ACR_PASSWORD"

print_success "Web App configured to use ACR"
echo ""

################################################################################
# Step 5: Create Deployment Slots (for Blue-Green Deployment)
################################################################################
print_info "Step 5: Creating deployment slots..."

# Create staging slot
if az webapp deployment slot list --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query "[?name=='staging']" -o tsv | grep -q staging; then
    print_warning "Staging slot already exists. Skipping creation."
else
    az webapp deployment slot create \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --slot staging \
        --configuration-source "$APP_NAME"

    print_success "Staging slot created"
fi

# Create blue slot (for blue-green deployment)
if az webapp deployment slot list --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query "[?name=='blue']" -o tsv | grep -q blue; then
    print_warning "Blue slot already exists. Skipping creation."
else
    az webapp deployment slot create \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --slot blue \
        --configuration-source "$APP_NAME"

    print_success "Blue slot created"
fi

# Create green slot (for blue-green deployment)
if az webapp deployment slot list --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query "[?name=='green']" -o tsv | grep -q green; then
    print_warning "Green slot already exists. Skipping creation."
else
    az webapp deployment slot create \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --slot green \
        --configuration-source "$APP_NAME"

    print_success "Green slot created"
fi

echo ""

################################################################################
# Step 6: Configure App Settings
################################################################################
print_info "Step 6: Configuring application settings..."

az webapp config appsettings set \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --settings \
        NODE_ENV=production \
        PORT=8080 \
        DEPLOYMENT_TYPE=production \
        LOG_LEVEL=info \
        WEBSITES_PORT=3000

print_success "Application settings configured"
echo ""

################################################################################
# Step 7: Configure Health Check
################################################################################
print_info "Step 7: Configuring health check..."

az webapp config set \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --health-check-path "/health/ready"

print_success "Health check configured at /health/ready"
echo ""

################################################################################
# Step 8: Enable Logging
################################################################################
print_info "Step 8: Enabling application logging..."

az webapp log config \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --application-logging filesystem \
    --detailed-error-messages true \
    --failed-request-tracing true \
    --web-server-logging filesystem

print_success "Logging enabled"
echo ""

################################################################################
# Summary
################################################################################
print_success "=========================================="
print_success "Azure Resources Created Successfully!"
print_success "=========================================="
echo ""
print_info "Resource Group: $RESOURCE_GROUP"
print_info "Location: $LOCATION"
echo ""
print_info "Container Registry:"
print_info "  Name: $ACR_NAME"
print_info "  Login Server: $ACR_LOGIN_SERVER"
print_info "  Username: $ACR_USERNAME"
echo ""
print_info "App Service:"
print_info "  Name: $APP_NAME"
print_info "  URL: https://$APP_NAME.azurewebsites.net"
print_info "  Plan: $APP_SERVICE_PLAN ($APP_SERVICE_SKU)"
echo ""
print_info "Deployment Slots:"
print_info "  Staging: https://$APP_NAME-staging.azurewebsites.net"
print_info "  Blue: https://$APP_NAME-blue.azurewebsites.net"
print_info "  Green: https://$APP_NAME-green.azurewebsites.net"
echo ""

# Save credentials to file
CREDENTIALS_FILE="azure-credentials.txt"
cat > "$CREDENTIALS_FILE" << EOF
# Azure Credentials for GAS Project
# Generated: $(date)

RESOURCE_GROUP=$RESOURCE_GROUP
LOCATION=$LOCATION
APP_NAME=$APP_NAME
ACR_NAME=$ACR_NAME
ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
ACR_USERNAME=$ACR_USERNAME
ACR_PASSWORD=$ACR_PASSWORD
SUBSCRIPTION_ID=$SUBSCRIPTION_ID

# GitHub Secrets (add these to your repository)
# Settings -> Secrets and variables -> Actions -> New repository secret

ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
ACR_USERNAME=$ACR_USERNAME
ACR_PASSWORD=$ACR_PASSWORD
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP

# To get AZURE_CREDENTIALS for GitHub Actions, run:
# az ad sp create-for-rbac --name "gas-project-sp" --role contributor --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP --sdk-auth

# App URLs
PRODUCTION_URL=https://$APP_NAME.azurewebsites.net
STAGING_URL=https://$APP_NAME-staging.azurewebsites.net
BLUE_URL=https://$APP_NAME-blue.azurewebsites.net
GREEN_URL=https://$APP_NAME-green.azurewebsites.net
EOF

print_success "Credentials saved to: $CREDENTIALS_FILE"
print_warning "IMPORTANT: Keep this file secure and do not commit it to git!"
echo ""

print_info "Next Steps:"
print_info "1. Build and push your Docker image to ACR:"
print_info "   docker build -t $ACR_LOGIN_SERVER/gas-app:latest -f docker/Dockerfile ."
print_info "   docker login $ACR_LOGIN_SERVER -u $ACR_USERNAME -p [password]"
print_info "   docker push $ACR_LOGIN_SERVER/gas-app:latest"
echo ""
print_info "2. Create Service Principal for GitHub Actions:"
print_info "   az ad sp create-for-rbac --name \"gas-project-sp\" --role contributor --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP --sdk-auth"
echo ""
print_info "3. Add secrets to GitHub repository (Settings -> Secrets):"
print_info "   - ACR_LOGIN_SERVER"
print_info "   - ACR_USERNAME"
print_info "   - ACR_PASSWORD"
print_info "   - AZURE_CREDENTIALS (from step 2)"
print_info "   - AZURE_RESOURCE_GROUP"
echo ""
print_info "4. Push your code to GitHub to trigger CI/CD pipelines"
echo ""
print_success "Setup complete! 🎉"
