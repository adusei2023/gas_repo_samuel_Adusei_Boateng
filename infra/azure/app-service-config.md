# Azure App Service Configuration Guide

## Overview

This guide explains how to configure Azure App Service for the GAS Project with support for:
- Blue-Green deployments
- Canary deployments
- Staging environment
- Health checks and monitoring

## Prerequisites

- Azure subscription
- Azure CLI installed (`az --version`)
- Docker installed
- Logged in to Azure (`az login`)

## Quick Start

### 1. Create Azure Resources

Run the automated setup script:

```bash
chmod +x infra/azure/create-resources.sh
./infra/azure/create-resources.sh
```

This creates:
- Resource Group
- Azure Container Registry (ACR)
- App Service Plan
- Web App with deployment slots (staging, blue, green)
- Health check configuration

### 2. Build and Push Docker Image

```bash
chmod +x infra/azure/acr-setup.sh
./infra/azure/acr-setup.sh <acr-name> v1.0.0
```

### 3. Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

```
ACR_LOGIN_SERVER      - Your ACR login server URL
ACR_USERNAME          - ACR username
ACR_PASSWORD          - ACR password
AZURE_CREDENTIALS     - Service principal credentials (JSON)
AZURE_RESOURCE_GROUP  - Your resource group name
```

To create service principal credentials:

```bash
az ad sp create-for-rbac \
  --name "gas-project-sp" \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group> \
  --sdk-auth
```

## Deployment Slots

### Slot Configuration

| Slot | Purpose | URL |
|------|---------|-----|
| Production | Live traffic | `https://<app-name>.azurewebsites.net` |
| Staging | Pre-production testing | `https://<app-name>-staging.azurewebsites.net` |
| Blue | Blue-Green deployment | `https://<app-name>-blue.azurewebsites.net` |
| Green | Blue-Green deployment | `https://<app-name>-green.azurewebsites.net` |
| Canary | Canary deployment | `https://<app-name>-canary.azurewebsites.net` |

### Blue-Green Deployment

1. Deploy new version to inactive slot (green)
2. Run tests on green slot
3. Swap slots (green becomes production)
4. Old version (blue) becomes inactive

```bash
# Swap green to production
./infra/azure/slot-traffic-config.sh <app-name> <resource-group> swap green production
```

### Canary Deployment

1. Deploy new version to canary slot
2. Route 10% traffic to canary
3. Monitor metrics
4. Gradually increase traffic (25%, 50%, 100%)
5. Promote to production

```bash
# Route 10% traffic to canary
./infra/azure/slot-traffic-config.sh <app-name> <resource-group> route canary 10

# Check status
./infra/azure/slot-traffic-config.sh <app-name> <resource-group> status

# Promote to 100%
./infra/azure/slot-traffic-config.sh <app-name> <resource-group> route canary 100

# Reset traffic
./infra/azure/slot-traffic-config.sh <app-name> <resource-group> reset
```

## Application Settings

Key environment variables configured in App Service:

```
NODE_ENV=production
PORT=8080
DEPLOYMENT_TYPE=production
LOG_LEVEL=info
WEBSITES_PORT=3000
```

## Health Checks

The app is configured with health check endpoint: `/health/ready`

Azure App Service uses this to:
- Determine if instance is healthy
- Route traffic only to healthy instances
- Trigger automatic restarts if unhealthy

## Monitoring

### Application Insights

Optional: Enable Application Insights for advanced monitoring:

```bash
az monitor app-insights component create \
  --app <app-name> \
  --location <location> \
  --resource-group <resource-group> \
  --application-type web
```

### Logs

View application logs:

```bash
# Stream logs in real-time
az webapp log tail --name <app-name> --resource-group <resource-group>

# Download logs
az webapp log download --name <app-name> --resource-group <resource-group>
```

## Scaling

### Manual Scaling

```bash
# Scale up to Premium tier
az appservice plan update \
  --name <plan-name> \
  --resource-group <resource-group> \
  --sku P1V2
```

### Auto-scaling

```bash
# Create autoscale settings
az monitor autoscale create \
  --resource-group <resource-group> \
  --resource <app-name> \
  --resource-type "Microsoft.Web/sites" \
  --name <autoscale-name> \
  --min-count 1 \
  --max-count 5 \
  --count 2
```

## Troubleshooting

### App won't start

1. Check logs: `az webapp log tail --name <app-name> --resource-group <resource-group>`
2. Verify environment variables are set
3. Check Docker image is accessible in ACR
4. Verify health check endpoint is working

### Deployment fails

1. Check ACR credentials
2. Verify Docker image exists in ACR
3. Check App Service plan has enough resources
4. Review deployment logs in Azure Portal

### Health check failures

1. Verify `/health/ready` endpoint returns 200
2. Check application logs for errors
3. Verify network connectivity
4. Check resource limits (CPU, memory)

## Cleanup

To delete all resources:

```bash
az group delete --name <resource-group> --yes
```

## References

- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Deployment Slots](https://docs.microsoft.com/en-us/azure/app-service/deploy-staging-slots)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
