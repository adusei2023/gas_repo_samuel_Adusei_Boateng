# Rollback Guide

## What is Rollback?

**Rollback** is the process of reverting to a previous version of your application when something goes wrong in production.

Think of it like an "undo" button for deployments.

## When to Rollback

### Immediate Rollback Needed

- 🔴 **Critical errors** - App is crashing or not responding
- 🔴 **Data corruption** - Database issues or data loss
- 🔴 **Security breach** - Vulnerability discovered
- 🔴 **High error rate** - > 10% of requests failing
- 🔴 **Performance degradation** - Response time > 5x normal

### Monitor and Decide

- 🟡 **Moderate errors** - 1-5% error rate
- 🟡 **Slow performance** - 2-5x normal response time
- 🟡 **Resource issues** - High CPU/memory usage
- 🟡 **User complaints** - Multiple users reporting issues

### No Rollback Needed

- 🟢 **Minor issues** - Can be fixed with hotfix
- 🟢 **Expected behavior** - Not actually a bug
- 🟢 **Isolated issues** - Only affects specific users

## Rollback Strategies

### 1. Blue-Green Rollback (Fastest)

**Time:** < 1 minute
**Risk:** Very Low
**Complexity:** Low

Swap slots back to previous version:

```bash
# Swap back to previous version
az webapp deployment slot swap \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot blue
```

**Pros:**
- Instant rollback
- Previous version still running
- Easy to verify

**Cons:**
- Only works if using blue-green deployment
- Requires deployment slots

### 2. Previous Image Rollback (Medium)

**Time:** 2-5 minutes
**Risk:** Low
**Complexity:** Medium

Deploy previous commit's Docker image:

```bash
# Get previous image tag
PREVIOUS_TAG=$(git describe --tags --abbrev=0 HEAD~1)

# Deploy previous image
az webapp config container set \
  --name <app-name> \
  --resource-group <resource-group> \
  --docker-custom-image-name <acr-name>.azurecr.io/gas-app:${PREVIOUS_TAG}

# Restart app
az webapp restart --name <app-name> --resource-group <resource-group>
```

**Pros:**
- Works without deployment slots
- Can rollback to any previous version
- Flexible

**Cons:**
- Takes longer than slot swap
- Requires previous image in ACR
- Brief downtime during restart

### 3. Code Rollback (Slowest)

**Time:** 5-15 minutes
**Risk:** Medium
**Complexity:** High

Revert code and redeploy:

```bash
# Revert to previous commit
git revert HEAD

# Push to trigger deployment
git push origin main

# Wait for CI/CD pipeline to complete
```

**Pros:**
- Can fix issues in code
- Audit trail of changes
- Permanent fix

**Cons:**
- Slowest option
- Requires code review
- Downtime during deployment

## Automated Rollback

### GitHub Actions Rollback Workflow

The `rollback.yml` workflow provides automated rollback:

```yaml
name: Rollback

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to rollback'
        required: true
        type: choice
        options:
          - staging
          - production
      rollback_type:
        description: 'Rollback type'
        required: true
        type: choice
        options:
          - slot-swap
          - previous-image

jobs:
  rollback-slot-swap:
    # Swap slots back to previous version

  rollback-previous-image:
    # Deploy previous commit's image

  notify-rollback:
    # Send notification
```

### Using GitHub Actions

```bash
# Trigger rollback workflow
gh workflow run rollback.yml \
  -f environment=production \
  -f rollback_type=slot-swap
```

## Manual Rollback Procedures

### Scenario 1: Blue-Green Deployment

**Situation:** Just deployed to production, high error rate detected

**Steps:**

```bash
# 1. Check current status
az webapp deployment slot list \
  --name <app-name> \
  --resource-group <resource-group>

# 2. Identify which slot is production
# (Usually the one with higher traffic)

# 3. Swap back to previous version
az webapp deployment slot swap \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot blue

# 4. Verify production is back to previous version
curl https://<app-name>.azurewebsites.net/health

# 5. Check error rate in Grafana
# Should return to normal within 1-2 minutes

# 6. Investigate what went wrong
# Check logs, metrics, recent changes
```

### Scenario 2: Canary Deployment

**Situation:** Canary showing high error rate

**Steps:**

```bash
# 1. Check canary metrics
az webapp traffic-routing show \
  --name <app-name> \
  --resource-group <resource-group>

# 2. Stop routing traffic to canary
az webapp traffic-routing clear \
  --name <app-name> \
  --resource-group <resource-group>

# 3. Verify all traffic back to stable
curl https://<app-name>.azurewebsites.net/health

# 4. Check error rate returns to normal
# Monitor for 2-3 minutes

# 5. Investigate canary logs
az webapp log tail \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot canary

# 6. Fix issue and redeploy
```

### Scenario 3: Staging Deployment

**Situation:** Issue found in staging before production

**Steps:**

```bash
# 1. Check staging slot status
az webapp show \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot staging

# 2. Redeploy previous version to staging
az webapp config container set \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot staging \
  --docker-custom-image-name <acr-name>.azurecr.io/gas-app:previous-tag

# 3. Wait for health check
sleep 30

# 4. Test staging
curl https://<app-name>-staging.azurewebsites.net/health

# 5. Fix issue in code
# Don't promote to production until fixed
```

## Monitoring for Rollback Triggers

### Key Metrics to Watch

```
Error Rate:
- < 1%: Normal
- 1-5%: Monitor
- > 5%: Consider rollback
- > 10%: Immediate rollback

Response Time (p95):
- < 500ms: Normal
- 500ms-1s: Monitor
- 1-2s: Investigate
- > 2s: Consider rollback

CPU Usage:
- < 70%: Normal
- 70-85%: Monitor
- > 85%: Investigate
- > 95%: Immediate rollback

Memory Usage:
- < 70%: Normal
- 70-85%: Monitor
- > 85%: Investigate
- > 95%: Immediate rollback
```

### Grafana Alerts

Set up alerts in Grafana:

```
1. Go to http://localhost:3001
2. Alerts → Alert rules
3. Create alert for:
   - Error rate > 5%
   - Response time > 1s
   - CPU > 85%
   - Memory > 85%
4. Set notification channel (email, Slack, etc.)
```

## Post-Rollback Actions

### 1. Investigate Root Cause

```bash
# Check application logs
az webapp log tail --name <app-name> --resource-group <resource-group>

# Check recent changes
git log --oneline -10

# Check metrics around deployment time
# Use Grafana to view historical data

# Check for external issues
# Database, API dependencies, etc.
```

### 2. Document the Incident

Create incident report:

```markdown
# Incident Report

## Timeline
- 14:30 - Deployed version 2.0.0
- 14:32 - Error rate increased to 15%
- 14:33 - Initiated rollback
- 14:34 - Rollback complete, error rate normal

## Root Cause
[Describe what went wrong]

## Impact
- Duration: 4 minutes
- Users affected: ~1000
- Requests failed: ~500

## Resolution
[Describe how it was fixed]

## Prevention
[Describe how to prevent in future]
```

### 3. Fix and Redeploy

```bash
# 1. Create hotfix branch
git checkout -b hotfix/issue-name

# 2. Fix the issue
# Edit files, test locally

# 3. Commit and push
git add .
git commit -m "fix: Resolve issue from deployment"
git push origin hotfix/issue-name

# 4. Create pull request
# Get code review

# 5. Merge to main
# Trigger production deployment

# 6. Monitor new deployment
# Watch metrics for 10 minutes
```

## Rollback Decision Tree

```
Issue Detected
    │
    ├─ Critical (app down, data loss)?
    │  └─ YES → Immediate rollback (slot swap)
    │
    ├─ Error rate > 10%?
    │  └─ YES → Immediate rollback (slot swap)
    │
    ├─ Error rate 5-10%?
    │  └─ YES → Rollback if trend increasing
    │
    ├─ Error rate 1-5%?
    │  └─ YES → Monitor for 5 minutes
    │           If increasing → Rollback
    │           If stable → Investigate
    │
    └─ Error rate < 1%?
       └─ NO → Continue monitoring
```

## Rollback Checklist

Before rolling back:

- [ ] Confirmed issue is real (not false alarm)
- [ ] Checked metrics and logs
- [ ] Notified team
- [ ] Identified rollback strategy
- [ ] Verified previous version is available

During rollback:

- [ ] Executed rollback command
- [ ] Verified rollback succeeded
- [ ] Checked health endpoints
- [ ] Monitored error rate
- [ ] Confirmed users can access app

After rollback:

- [ ] Error rate returned to normal
- [ ] Performance metrics normal
- [ ] Notified team of completion
- [ ] Started incident investigation
- [ ] Documented what happened
- [ ] Planned fix and redeployment

## Best Practices

1. **Have a rollback plan**
   - Know which strategy to use
   - Practice before needed
   - Document procedures

2. **Monitor continuously**
   - Watch metrics after deployment
   - Set up alerts
   - Be ready to act quickly

3. **Keep previous versions available**
   - Don't delete old Docker images
   - Keep deployment slots running
   - Maintain git history

4. **Test rollback procedure**
   - Practice in staging
   - Verify it works
   - Time how long it takes

5. **Communicate clearly**
   - Notify team immediately
   - Keep stakeholders informed
   - Document decisions

6. **Automate when possible**
   - Use GitHub Actions workflows
   - Reduce manual errors
   - Provide audit trail

## Troubleshooting

### Rollback Failed

```bash
# Check slot status
az webapp deployment slot list \
  --name <app-name> \
  --resource-group <resource-group>

# Check if slots exist
# If not, create them

# Try manual swap
az webapp deployment slot swap \
  --name <app-name> \
  --resource-group <resource-group> \
  --slot blue
```

### Previous Image Not Available

```bash
# List available images in ACR
az acr repository show-tags \
  --name <acr-name> \
  --repository gas-app

# If not available, deploy from git
git revert HEAD
git push origin main
```

### Rollback Took Too Long

```bash
# Analyze what happened
# Check deployment logs
# Identify bottlenecks

# Optimize for next time:
# - Pre-warm instances
# - Use faster health checks
# - Reduce deployment complexity
```

## Next Steps

1. Set up monitoring and alerts
2. Practice rollback in staging
3. Document your rollback procedures
4. Train team on rollback process
5. Set up automated rollback workflows

---

**Last Updated:** 2025-11-20
**Version:** 1.0.0
