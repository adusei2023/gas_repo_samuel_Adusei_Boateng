# Canary Deployment Guide

## What is Canary Deployment?

**Canary** is a deployment strategy where you gradually roll out a new version to a percentage of users.

Named after "canary in a coal mine" - canaries were used to detect dangerous gases. Similarly, canary deployments detect issues early by exposing them to a small subset of users first.

## Why Use Canary?

### Benefits

✅ **Detect issues early** - Real traffic reveals problems
✅ **Minimize blast radius** - Only small % of users affected
✅ **Gradual rollout** - Reduce risk of widespread outage
✅ **Easy rollback** - Stop routing traffic to canary
✅ **Data-driven decisions** - Monitor metrics before promoting

### When to Use

- New features with uncertain impact
- Experimental changes
- When you want to minimize risk
- When you need real-world validation

## How It Works

### Step 1: Deploy Canary Version

```
Before:
┌─────────────────────────────────────────┐
│ Production (Stable)                     │
│ - Receiving 100% traffic                │
│ - Version 1.0.0                         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Canary                                  │
│ - Not receiving traffic                 │
│ - Empty                                 │
└─────────────────────────────────────────┘
```

Deploy new version to canary:

```
After Deploy:
┌─────────────────────────────────────────┐
│ Production (Stable)                     │
│ - Receiving 100% traffic                │
│ - Version 1.0.0                         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Canary                                  │
│ - Not receiving traffic yet             │
│ - Version 2.0.0 (NEW)                   │
└─────────────────────────────────────────┘
```

### Step 2: Route Traffic to Canary

Start with small percentage (e.g., 10%):

```
After Routing 10%:
┌─────────────────────────────────────────┐
│ Production (Stable)                     │
│ - Receiving 90% traffic                 │
│ - Version 1.0.0                         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Canary                                  │
│ - Receiving 10% traffic                 │
│ - Version 2.0.0 (NEW)                   │
└─────────────────────────────────────────┘
```

### Step 3: Monitor Metrics

Watch key metrics for 5-10 minutes:

- **Error Rate** - Should be similar to stable
- **Response Time** - Should be similar to stable
- **CPU/Memory** - Should be within normal range
- **User Feedback** - Any complaints?

### Step 4: Decide

Based on metrics:

**If Good:** Increase traffic to next level (25%, 50%, 100%)
**If Bad:** Rollback to 0% (stop routing traffic)

### Step 5: Promote or Rollback

```
Promote Path:
10% → 25% → 50% → 100% (Promoted to production)

Rollback Path:
10% → 0% (Canary stopped, stable continues)
```

## Local Testing

### Using Docker Compose

Test canary locally with docker-compose:

```bash
# Start stable and canary versions
docker-compose --profile canary up -d

# Stable version (port 3000)
curl http://localhost:3000/health

# Canary version (port 3003)
curl http://localhost:3003/health

# Nginx load balancer (port 8080)
# Routes traffic based on configuration
curl http://localhost:8080/health
```

### Simulating Traffic Split

```bash
# Edit docker/monitoring/nginx.conf
# Set upstream weights:
# upstream stable { server app-stable:3000 weight=90; }
# upstream canary { server app-canary:3000 weight=10; }

# Reload nginx
docker exec <nginx-container> nginx -s reload

# Test traffic distribution
for i in {1..100}; do curl http://localhost:8080/health; done
```

### Monitoring with Grafana

```bash
# Access Grafana
# http://localhost:3001 (admin/admin)

# View "Canary Comparison" dashboard
# Compare metrics between stable and canary
```

## Azure Implementation

### Deployment Slots

Azure App Service provides traffic routing:

```bash
# Create canary slot
az webapp deployment slot create \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot canary

# Deploy to canary slot
az webapp config container set \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot canary \
  --docker-custom-image-name <image-name>
```

### Traffic Routing

```bash
# Route 10% traffic to canary
az webapp traffic-routing set \
  --name <app-name> \
  --resource-group <resource-group> \
  --distribution canary=10

# Check current routing
az webapp traffic-routing show \
  --name <app-name> \
  --resource-group <resource-group>

# Increase to 25%
az webapp traffic-routing set \
  --name <app-name> \
  --resource-group <resource-group> \
  --distribution canary=25

# Promote to 100%
az webapp traffic-routing set \
  --name <app-name> \
  --resource-group <resource-group> \
  --distribution canary=100

# Rollback to 0%
az webapp traffic-routing clear \
  --name <app-name> \
  --resource-group <resource-group>
```

## GitHub Actions Workflow

The `canary.yml` workflow automates canary deployment:

```yaml
name: Canary Deployment

on:
  workflow_dispatch:
    inputs:
      traffic_percentage:
        description: 'Traffic percentage for canary (1-100)'
        required: true
        default: '10'

jobs:
  deploy-canary:
    # Deploy to canary slot
    # Route specified traffic percentage

  monitor-canary:
    # Wait 5 minutes
    # Monitor error rate and latency

  promote-or-rollback:
    # If metrics good: promote to 100%
    # If metrics bad: rollback to 0%
```

### Workflow Steps

1. **Deploy Canary**
   - Build Docker image
   - Deploy to canary slot
   - Route specified traffic percentage

2. **Monitor Canary**
   - Wait 5 minutes
   - Collect metrics
   - Compare with stable version

3. **Promote or Rollback**
   - If error rate < 1%: promote
   - If error rate > 5%: rollback
   - Otherwise: manual decision

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

# 5. Deploy to canary slot
az webapp config container set \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot canary \
  --docker-custom-image-name <acr-name>.azurecr.io/gas-app:v2.0.0

# 6. Wait for health check
sleep 30

# 7. Route 10% traffic to canary
az webapp traffic-routing set \
  --name <app-name> \
  --resource-group <resource-group> \
  --distribution canary=10

# 8. Monitor for 5 minutes
sleep 300

# 9. Check metrics (in Grafana or Application Insights)

# 10a. If good, promote to 100%
az webapp traffic-routing set \
  --name <app-name> \
  --resource-group <resource-group> \
  --distribution canary=100

# 10b. If bad, rollback to 0%
az webapp traffic-routing clear \
  --name <app-name> \
  --resource-group <resource-group>
```

## Monitoring During Canary

### Key Metrics

1. **Error Rate**
   - Canary vs Stable comparison
   - Should be similar or lower
   - Alert if > 5% difference

2. **Response Time (p95, p99)**
   - Canary vs Stable
   - Should be similar
   - Alert if > 10% slower

3. **CPU/Memory Usage**
   - Per instance
   - Should be within normal range
   - Alert if > 20% increase

4. **Request Rate**
   - Should match traffic percentage
   - 10% traffic = ~10% of requests

### Grafana Dashboard

View canary metrics:

```
1. Go to http://localhost:3001 (admin/admin)
2. Select "Canary Comparison" dashboard
3. View side-by-side metrics
4. Look for anomalies
```

### Application Insights

```bash
# Query error rate
az monitor metrics list \
  --resource <app-name> \
  --metric "Http5xx" \
  --start-time 2025-11-20T00:00:00Z \
  --end-time 2025-11-20T01:00:00Z

# Query response time
az monitor metrics list \
  --resource <app-name> \
  --metric "ResponseTime" \
  --start-time 2025-11-20T00:00:00Z \
  --end-time 2025-11-20T01:00:00Z
```

## Canary Promotion Strategy

### Conservative (Recommended for Critical Apps)

```
10% (5 min) → 25% (5 min) → 50% (10 min) → 100%
Total: 20 minutes
```

### Moderate

```
10% (5 min) → 50% (5 min) → 100%
Total: 10 minutes
```

### Aggressive

```
10% (2 min) → 100%
Total: 2 minutes
```

## Troubleshooting

### Canary Deployment Failed

```bash
# Check canary slot status
az webapp show --name <app-name> --resource-group <resource-group> --slot canary

# Check logs
az webapp log tail --name <app-name> --resource-group <resource-group> --slot canary

# Verify health check
curl https://<app-name>-canary.azurewebsites.net/health/ready
```

### High Error Rate in Canary

```bash
# Check application logs
az webapp log tail --name <app-name> --resource-group <resource-group> --slot canary

# Check for exceptions
# Look for patterns in errors

# Rollback if needed
az webapp traffic-routing clear \
  --name <app-name> \
  --resource-group <resource-group>
```

### Metrics Not Showing

```bash
# Verify Prometheus is scraping
# Check http://localhost:9090/targets

# Verify Grafana datasource
# Check http://localhost:3001/datasources

# Check application metrics endpoint
curl http://localhost:3000/metrics
```

## Best Practices

1. **Start small**
   - Begin with 5-10% traffic
   - Gradually increase
   - Don't jump to 100%

2. **Monitor continuously**
   - Watch metrics in real-time
   - Set up alerts
   - Be ready to rollback

3. **Have clear success criteria**
   - Define what "good" looks like
   - Error rate threshold
   - Response time threshold
   - Resource usage threshold

4. **Document decisions**
   - Why you promoted/rolled back
   - What metrics you watched
   - Any issues encountered

5. **Test locally first**
   - Use docker-compose
   - Simulate traffic split
   - Verify monitoring works

6. **Communicate with team**
   - Notify team of canary deployment
   - Share metrics dashboard
   - Discuss promotion decision

## Comparison with Other Strategies

| Strategy | Downtime | Rollback | Risk | Complexity |
|----------|----------|----------|------|-----------|
| Canary | None | Gradual | Very Low | High |
| Blue-Green | None | Instant | Low | Medium |
| Rolling | Minimal | Gradual | Medium | Medium |
| Big Bang | Yes | Manual | High | Low |

## Next Steps

1. Set up canary slot in Azure
2. Configure traffic routing
3. Test canary locally with docker-compose
4. Deploy to staging first
5. Monitor canary deployment
6. Practice promotion and rollback

---

**Last Updated:** 2025-11-20
**Version:** 1.0.0
