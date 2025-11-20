# Blue-Green Deployment Guide

## What is Blue-Green Deployment?

**Blue-Green** is a deployment strategy where you have two identical production environments:
- **Blue** - Current production (receiving traffic)
- **Green** - New version (not receiving traffic)

When you're ready to release, you **swap** traffic from Blue to Green. If something goes wrong, you swap back instantly.

## Why Use Blue-Green?

### Benefits

✅ **Zero-downtime deployments** - No service interruption
✅ **Instant rollback** - Swap back if issues detected
✅ **Easy testing** - Test new version before going live
✅ **Reduced risk** - Old version still running as backup
✅ **Simple rollback** - Just swap slots back

### When to Use

- Major releases
- Critical updates
- When downtime is not acceptable
- When you need instant rollback capability

## How It Works

### Step 1: Deploy to Inactive Slot

```
Before:
┌─────────────────────────────────────────┐
│ Production (Blue)                       │
│ - Receiving 100% traffic                │
│ - Version 1.0.0                         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Staging (Green)                         │
│ - Not receiving traffic                 │
│ - Empty or old version                  │
└─────────────────────────────────────────┘
```

Deploy new version to Green:

```
After Deploy:
┌─────────────────────────────────────────┐
│ Production (Blue)                       │
│ - Receiving 100% traffic                │
│ - Version 1.0.0                         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Staging (Green)                         │
│ - Not receiving traffic                 │
│ - Version 2.0.0 (NEW)                   │
└─────────────────────────────────────────┘
```

### Step 2: Test New Version

Test Green slot before swapping:

```bash
# Test health endpoint
curl https://<app-name>-green.azurewebsites.net/health

# Test API endpoints
curl https://<app-name>-green.azurewebsites.net/api

# Run smoke tests
npm run test:smoke
```

### Step 3: Swap Slots

When ready, swap traffic from Blue to Green:

```
Before Swap:
Blue (1.0.0) ← 100% traffic
Green (2.0.0) ← 0% traffic

After Swap:
Blue (2.0.0) ← 100% traffic
Green (1.0.0) ← 0% traffic
```

### Step 4: Monitor

Monitor the new version in production:

```bash
# Check logs
az webapp log tail --name <app-name> --resource-group <resource-group>

# Check metrics
# Visit Grafana dashboard

# Check error rate
# Monitor application insights
```

### Step 5: Rollback (if needed)

If issues detected, swap back instantly:

```
Before Rollback:
Blue (2.0.0) ← 100% traffic (BROKEN)
Green (1.0.0) ← 0% traffic

After Rollback:
Blue (1.0.0) ← 100% traffic (FIXED)
Green (2.0.0) ← 0% traffic
```

## Local Testing

### Using Docker Compose

Test blue-green locally with docker-compose:

```bash
# Start blue and green versions
docker-compose --profile blue-green up -d

# Blue version (port 3001)
curl http://localhost:3001/health

# Green version (port 3002)
curl http://localhost:3002/health

# Nginx load balancer (port 8080)
curl http://localhost:8080/health
```

### Simulating Swap

```bash
# Update nginx config to route to green
# Edit docker/nginx.conf

# Reload nginx
docker exec <nginx-container> nginx -s reload

# Verify traffic now goes to green
curl http://localhost:8080/health
```

## Azure Implementation

### Deployment Slots

Azure App Service provides deployment slots:

```bash
# List slots
az webapp deployment slot list \
  --name <app-name> \
  --resource-group <resource-group>

# Create blue slot
az webapp deployment slot create \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot blue

# Create green slot
az webapp deployment slot create \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot green
```

### Deploying to Slot

```bash
# Deploy to green slot
az webapp deployment container config \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot green \
  --docker-custom-image-name <image-name>
```

### Swapping Slots

```bash
# Swap green to production
az webapp deployment slot swap \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot green

# Swap back to previous version
az webapp deployment slot swap \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot blue
```

## GitHub Actions Workflow

The `cd-production.yml` workflow automates blue-green deployment:

```yaml
name: Production Deployment (Blue-Green)

on:
  push:
    branches: [main]

jobs:
  build-and-push:
    # Build Docker image and push to ACR

  deploy-to-inactive-slot:
    # Deploy to inactive slot (blue or green)
    # Wait for health check

  swap-slots:
    # Swap traffic to new version
    # Verify swap succeeded
```

### Workflow Steps

1. **Build and Push**
   - Build Docker image
   - Tag with version
   - Push to ACR

2. **Deploy to Inactive Slot**
   - Determine which slot is inactive
   - Deploy image to inactive slot
   - Wait for health check (30s timeout)
   - Verify app is responding

3. **Swap Slots**
   - Swap traffic from active to inactive
   - Verify swap succeeded
   - Monitor for errors

## Manual Deployment

### Using Azure CLI

```bash
# 1. Build Docker image
docker build -t gas-app:v2.0.0 -f docker/Dockerfile .

# 2. Tag for ACR
docker tag gas-app:v2.0.0 <acr-name>.azurecr.io/gas-app:v2.0.0

# 3. Login to ACR
az acr login --name <acr-name>

# 4. Push to ACR
docker push <acr-name>.azurecr.io/gas-app:v2.0.0

# 5. Deploy to green slot
az webapp config container set \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot green \
  --docker-custom-image-name <acr-name>.azurecr.io/gas-app:v2.0.0

# 6. Wait for health check
sleep 30

# 7. Test green slot
curl https://<app-name>-green.azurewebsites.net/health

# 8. Swap slots
az webapp deployment slot swap \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot green

# 9. Verify production
curl https://<app-name>.azurewebsites.net/health
```

## Monitoring During Deployment

### Key Metrics to Watch

1. **Error Rate**
   - Should stay near 0%
   - If increases, rollback

2. **Response Time**
   - Should be similar to previous version
   - If increases significantly, investigate

3. **CPU/Memory**
   - Should be within normal range
   - If spikes, may indicate issue

4. **Active Connections**
   - Should gradually increase after swap
   - If drops, may indicate issue

### Grafana Dashboard

View metrics in Grafana:

```
1. Go to http://localhost:3001 (local)
2. Select "RED Metrics" dashboard
3. Watch Request Rate, Error Rate, Duration
4. Look for anomalies after swap
```

## Troubleshooting

### Swap Failed

```bash
# Check slot status
az webapp deployment slot list \
  --name <app-name> \
  --resource-group <resource-group>

# Check logs
az webapp log tail --name <app-name> --resource-group <resource-group> --slot green

# Verify health check
curl https://<app-name>-green.azurewebsites.net/health/ready
```

### Health Check Timeout

```bash
# Check if app is running
az webapp show --name <app-name> --resource-group <resource-group> --slot green

# Check logs for startup errors
az webapp log tail --name <app-name> --resource-group <resource-group> --slot green

# Increase health check timeout
az webapp config set \
  --name <app-name> \
  --resource-group <resource-group> \
  --health-check-path /health/ready
```

### Rollback Needed

```bash
# Swap back to previous version
az webapp deployment slot swap \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot blue

# Verify production is back to previous version
curl https://<app-name>.azurewebsites.net/health
```

## Best Practices

1. **Always test before swapping**
   - Run smoke tests on new version
   - Verify health endpoints
   - Check critical functionality

2. **Monitor after swap**
   - Watch error rate for 5 minutes
   - Check response times
   - Monitor resource usage

3. **Have rollback plan**
   - Know how to swap back
   - Keep previous version running
   - Be ready to act quickly

4. **Use health checks**
   - Configure `/health/ready` endpoint
   - Azure uses this to verify deployment
   - Prevents bad deployments

5. **Document changes**
   - Keep changelog
   - Document what changed
   - Note any issues encountered

6. **Automate with GitHub Actions**
   - Use workflows for consistency
   - Reduces manual errors
   - Provides audit trail

## Comparison with Other Strategies

| Strategy | Downtime | Rollback | Risk | Complexity |
|----------|----------|----------|------|-----------|
| Blue-Green | None | Instant | Low | Medium |
| Canary | None | Gradual | Very Low | High |
| Rolling | Minimal | Gradual | Medium | Medium |
| Big Bang | Yes | Manual | High | Low |

## Next Steps

1. Set up deployment slots in Azure
2. Configure health checks
3. Test blue-green locally with docker-compose
4. Deploy to staging first
5. Monitor production deployment
6. Practice rollback procedure

---

**Last Updated:** 2025-11-20
**Version:** 1.0.0
