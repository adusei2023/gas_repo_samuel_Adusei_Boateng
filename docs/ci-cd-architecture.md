# CI/CD Architecture Guide

## Overview

The GAS Project uses **GitHub Actions** for continuous integration and deployment. This guide explains how the CI/CD pipelines work and how they integrate with Azure.

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Pushes Code                     │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
   ┌─────────────┐         ┌──────────────┐
   │  PR to main │         │ Push to main │
   │  (CI only)  │         │ (CI + CD)    │
   └─────────────┘         └──────────────┘
        │                         │
        ▼                         ▼
   ┌─────────────┐         ┌──────────────┐
   │  ci.yml     │         │  ci.yml      │
   │  - Lint     │         │  - Lint      │
   │  - Test     │         │  - Test      │
   │  - Build    │         │  - Build     │
   │  - Security │         │  - Security  │
   └─────────────┘         └──────────────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │cd-production │
                          │  - Build     │
                          │  - Push ACR  │
                          │  - Deploy    │
                          │  - Swap      │
                          └──────────────┘
```

## Workflows

### 1. CI Workflow (ci.yml)

**Triggers:**
- Push to any branch
- Pull requests to any branch

**Jobs:**

#### Lint Job
- Runs ESLint on all source files
- Checks code style (Airbnb style guide)
- Fails if style violations found

```bash
npm run lint
```

#### Test Job
- Runs all tests (unit, integration, e2e)
- Generates coverage report
- Uploads to Codecov
- Fails if coverage below threshold

```bash
npm test
npm run test:coverage
```

#### Build Job
- Builds the application
- Archives artifacts
- Verifies build succeeds

```bash
npm run build
```

#### Docker Build Job
- Builds Docker image
- Tests image can start
- Verifies health endpoint works

```bash
npm run docker:build
docker run -p 3000:3000 gas-app:latest
```

#### Security Scan Job
- Runs `npm audit` for vulnerabilities
- Scans Docker image with Trivy
- Reports security issues

```bash
npm audit
trivy image gas-app:latest
```

### 2. Staging Deployment (cd-staging.yml)

**Triggers:**
- Push to `develop` branch
- Manual trigger (workflow_dispatch)

**Jobs:**

#### Build and Push
- Builds Docker image
- Tags with commit SHA
- Pushes to Azure Container Registry (ACR)

#### Deploy to Staging
- Deploys to staging slot
- Waits for health check to pass
- Configures environment variables

#### Smoke Tests
- Tests `/health` endpoint
- Tests `/metrics` endpoint
- Tests `/api` endpoints
- Verifies app is responding

#### Notify
- Sends deployment status notification
- Includes staging URL and commit info

### 3. Production Deployment (cd-production.yml)

**Triggers:**
- Push to `main` branch
- Tags matching `v*` (e.g., v1.0.0)
- Manual trigger (workflow_dispatch)

**Jobs:**

#### Build and Push
- Builds Docker image
- Tags with version and latest
- Pushes to ACR

#### Deploy to Inactive Slot
- Determines which slot is inactive (blue or green)
- Deploys new image to inactive slot
- Waits for health check

#### Swap Slots
- Swaps traffic from active to inactive slot
- Verifies swap succeeded
- Monitors for errors

**Result:** Zero-downtime blue-green deployment

### 4. Canary Deployment (canary.yml)

**Triggers:**
- Manual trigger with traffic percentage input

**Jobs:**

#### Deploy Canary
- Builds Docker image
- Deploys to canary slot
- Routes specified traffic percentage

#### Monitor Canary
- Waits 5 minutes
- Monitors error rate and latency
- Compares with stable version

#### Promote or Rollback
- If metrics are good: promote to 100%
- If metrics are bad: rollback to 0%

### 5. Rollback (rollback.yml)

**Triggers:**
- Manual trigger with options:
  - Slot swap (swap back to previous slot)
  - Previous image (deploy previous commit)

**Jobs:**

#### Rollback Slot Swap
- Swaps slots back to previous version
- Instant rollback

#### Rollback Previous Image
- Deploys previous commit's image
- Useful if slot swap not available

#### Notify Rollback
- Sends notification of rollback
- Includes reason and previous version

## GitHub Secrets Configuration

Required secrets for CI/CD to work:

```
ACR_LOGIN_SERVER      - Azure Container Registry login server
ACR_USERNAME          - ACR username
ACR_PASSWORD          - ACR password
AZURE_CREDENTIALS     - Service principal credentials (JSON)
AZURE_RESOURCE_GROUP  - Azure resource group name
```

### How to Add Secrets

1. Go to GitHub repository
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret

### How to Create Service Principal

```bash
az ad sp create-for-rbac \
  --name "gas-project-sp" \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group> \
  --sdk-auth
```

Copy the JSON output and add as `AZURE_CREDENTIALS` secret.

## Branch Strategy

### Main Branch (`main`)
- Production-ready code
- Triggers production deployment
- Blue-green deployment
- Zero-downtime release

### Develop Branch (`develop`)
- Integration branch
- Triggers staging deployment
- Pre-production testing
- Team validation

### Feature Branches (`feature/*`)
- Individual features
- Triggers CI only (lint, test, build)
- Pull request to develop
- Code review required

### Hotfix Branches (`hotfix/*`)
- Critical production fixes
- Pull request to main
- Triggers CI
- Fast-tracked to production

## Deployment Flow

### Feature Development

```
1. Create feature branch from develop
2. Push code
3. GitHub Actions runs CI (lint, test, build)
4. Create Pull Request
5. Code review
6. Merge to develop
7. Staging deployment triggered
8. Team tests on staging
9. Create PR to main
10. Merge to main
11. Production deployment triggered
12. Blue-green swap
13. Production live
```

### Hotfix

```
1. Create hotfix branch from main
2. Push code
3. GitHub Actions runs CI
4. Create Pull Request to main
5. Code review (expedited)
6. Merge to main
7. Production deployment triggered
8. Blue-green swap
9. Production live
10. Merge back to develop
```

## Environment Variables

### CI Environment

```env
NODE_ENV=test
LOG_LEVEL=error
```

### Staging Environment

```env
NODE_ENV=production
DEPLOYMENT_TYPE=staging
LOG_LEVEL=info
```

### Production Environment

```env
NODE_ENV=production
DEPLOYMENT_TYPE=production
LOG_LEVEL=warn
```

## Monitoring Deployments

### GitHub Actions UI

1. Go to repository
2. Click "Actions" tab
3. View workflow runs
4. Click on run to see details
5. View logs for each job

### Azure Portal

1. Go to App Service
2. Deployment slots
3. View deployment history
4. Check health status

### Application Logs

```bash
# Stream logs from staging
az webapp log tail --name <app-name> --resource-group <resource-group> --slot staging

# Stream logs from production
az webapp log tail --name <app-name> --resource-group <resource-group>
```

## Troubleshooting

### Deployment Failed

1. Check GitHub Actions logs
2. Look for error messages
3. Common issues:
   - ACR credentials invalid
   - Docker image build failed
   - Health check timeout
   - Insufficient resources

### Tests Failing in CI

1. Run tests locally: `npm test`
2. Check test output
3. Fix failing tests
4. Push again

### Linting Errors

1. Run locally: `npm run lint`
2. Auto-fix: `npm run lint:fix`
3. Commit and push

### Security Scan Failures

1. Check npm audit output
2. Update vulnerable packages
3. Or suppress if false positive

## Best Practices

1. **Always test locally before pushing**
   ```bash
   npm run lint
   npm test
   npm run build
   ```

2. **Use meaningful commit messages**
   ```
   feat: Add new feature
   fix: Fix bug
   docs: Update documentation
   ```

3. **Keep feature branches short-lived**
   - Merge within 1-2 days
   - Reduces merge conflicts

4. **Review code before merging**
   - At least one approval
   - All checks passing

5. **Monitor deployments**
   - Check logs after deployment
   - Monitor metrics
   - Be ready to rollback

6. **Use semantic versioning**
   - v1.0.0 (major.minor.patch)
   - Tag releases on main branch

## Performance Tips

1. **Cache dependencies**
   - GitHub Actions caches npm packages
   - Speeds up CI runs

2. **Parallel jobs**
   - Lint, test, build run in parallel
   - Reduces total CI time

3. **Docker layer caching**
   - Multi-stage builds
   - Reuse base layers

4. **Artifact retention**
   - Keep artifacts for 30 days
   - Reduces storage costs

## Security Considerations

1. **Secrets management**
   - Never commit secrets
   - Use GitHub Secrets
   - Rotate regularly

2. **Access control**
   - Limit who can deploy
   - Use branch protection rules
   - Require code review

3. **Audit logging**
   - GitHub logs all actions
   - Review deployment history
   - Monitor for suspicious activity

4. **Image scanning**
   - Trivy scans for vulnerabilities
   - ACR scans on push
   - Review and fix issues

## Next Steps

1. Configure GitHub Secrets
2. Create Azure resources
3. Push code to trigger CI
4. Monitor first deployment
5. Set up monitoring and alerts

---

**Last Updated:** 2025-11-20
**Version:** 1.0.0
