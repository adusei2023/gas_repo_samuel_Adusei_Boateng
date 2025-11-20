# Deployment Guide

This document describes the deployment strategies and procedures for the GAS (GitHub Actions Staging) project.

## Table of Contents

- [Overview](#overview)
- [Deployment Strategies](#deployment-strategies)
- [Local Testing](#local-testing)
- [CI/CD Pipelines](#cicd-pipelines)
- [Rollback Procedures](#rollback-procedures)

## Overview

The GAS project implements multiple deployment strategies to ensure safe and reliable releases:

- **Blue-Green Deployment**: Zero-downtime deployments with instant rollback capability
- **Canary Deployment**: Gradual rollout with traffic splitting for risk mitigation
- **Staging Environment**: Pre-production testing environment

## Deployment Strategies

### Blue-Green Deployment

Blue-green deployment maintains two identical production environments (blue and green). Only one serves live traffic at a time.

**Process:**

1. Deploy new version to inactive environment (e.g., green)
2. Run health checks and tests on green
3. Switch traffic from blue to green
4. Keep blue as backup for instant rollback

**Advantages:**
- Zero downtime
- Instant rollback
- Full testing in production-like environment

**Local Simulation:**
```bash
./scripts/simulate-blue-green.sh
```

**Production Workflow:**
- Triggered on push to `main` branch
- Workflow: `.github/workflows/cd-production.yml`

### Canary Deployment

Canary deployment gradually rolls out changes to a small subset of users before full deployment.

**Process:**

1. Deploy canary version alongside stable version
2. Route small percentage of traffic to canary (e.g., 10%)
3. Monitor metrics (errors, latency, etc.)
4. Gradually increase traffic if metrics are good
5. Promote to 100% or rollback if issues detected

**Advantages:**
- Reduced risk
- Real user feedback
- Gradual rollout

**Local Simulation:**
```bash
# Deploy with 10% canary traffic
./scripts/simulate-canary.sh 10

# Deploy with 25% canary traffic
./scripts/simulate-canary.sh 25
```

**Production Workflow:**
- Manually triggered via GitHub Actions
- Workflow: `.github/workflows/canary.yml`

### Staging Deployment

Staging environment for pre-production testing.

**Process:**

1. Deploy to staging on push to `develop` branch
2. Run automated tests
3. Manual testing and validation
4. Promote to production when ready

**Workflow:**
- Triggered on push to `develop` branch
- Workflow: `.github/workflows/cd-staging.yml`

## Local Testing

### Prerequisites

- Node.js 18+
- Docker and Docker Compose
- Git

### Setup

```bash
# Run complete setup
./scripts/local-setup.sh
```

This will:
1. Install dependencies
2. Create `.env` file
3. Build Docker image
4. Start monitoring stack
5. Run tests

### Manual Setup

```bash
# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Build Docker image
docker build -t gas-app:latest -f docker/Dockerfile .

# Start monitoring stack
cd docker && docker-compose up -d && cd ..

# Run application
npm start
```

### Testing Deployments Locally

**Test Blue-Green:**
```bash
./scripts/simulate-blue-green.sh
```

**Test Canary:**
```bash
./scripts/simulate-canary.sh 10
```

**Access Monitoring:**
- Application: http://localhost:3000
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001 (admin/admin)

## CI/CD Pipelines

### Continuous Integration (CI)

**Trigger:** Push to any branch, Pull Request

**Steps:**
1. Checkout code
2. Install dependencies
3. Run linting
4. Run unit tests
5. Run integration tests
6. Build Docker image
7. Generate coverage report

**Workflow:** `.github/workflows/ci.yml`

### Continuous Deployment - Staging

**Trigger:** Push to `develop` branch

**Steps:**
1. Build and push Docker image
2. Deploy to Azure App Service (staging slot)
3. Run smoke tests
4. Notify deployment status

**Workflow:** `.github/workflows/cd-staging.yml`

### Continuous Deployment - Production

**Trigger:** Push to `main` branch or version tag

**Steps:**
1. Build and push Docker image
2. Deploy to inactive slot (blue or green)
3. Run tests on inactive slot
4. Swap slots (blue-green switch)
5. Verify production health

**Workflow:** `.github/workflows/cd-production.yml`

### Canary Deployment

**Trigger:** Manual (workflow_dispatch)

**Parameters:**
- `traffic_percentage`: Percentage of traffic to route to canary (1-100)

**Steps:**
1. Build and push canary image
2. Deploy to canary slot
3. Configure traffic routing
4. Monitor metrics
5. Promote or rollback

**Workflow:** `.github/workflows/canary.yml`

## Rollback Procedures

### Automatic Rollback

Deployments automatically rollback if:
- Health checks fail
- Smoke tests fail
- Deployment timeout

### Manual Rollback

**Via GitHub Actions:**

1. Go to Actions tab
2. Select "Rollback Deployment" workflow
3. Click "Run workflow"
4. Select environment and rollback type
5. Confirm and run

**Rollback Types:**

1. **Slot Swap**: Swap back to previous slot (fastest)
2. **Previous Image**: Deploy previous Docker image
3. **Specific Version**: Deploy specific version tag

**Workflow:** `.github/workflows/rollback.yml`

### Emergency Rollback

For critical issues:

```bash
# Using Azure CLI
az webapp deployment slot swap \
  --name gas-app-production \
  --resource-group <resource-group> \
  --slot blue \
  --target-slot production
```

## Monitoring and Observability

### Health Checks

- **Liveness**: `/health/live` - Is the app running?
- **Readiness**: `/health/ready` - Is the app ready to serve traffic?
- **Health**: `/health` - Detailed health information

### Metrics

Prometheus metrics available at `/metrics`:

- `gas_http_requests_total` - Total HTTP requests
- `gas_http_request_duration_seconds` - Request duration
- `gas_http_request_size_bytes` - Request size
- `gas_http_response_size_bytes` - Response size
- `gas_active_connections` - Active connections

### Dashboards

Grafana dashboards:
- **RED Metrics**: Rate, Errors, Duration
- **Canary Comparison**: Compare stable vs canary metrics

## Required Secrets

Configure these secrets in GitHub repository settings:

- `ACR_LOGIN_SERVER`: Azure Container Registry URL
- `ACR_USERNAME`: ACR username
- `ACR_PASSWORD`: ACR password
- `AZURE_CREDENTIALS`: Azure service principal credentials
- `AZURE_RESOURCE_GROUP`: Azure resource group name

## Best Practices

1. **Always test in staging first**
2. **Monitor metrics during canary deployments**
3. **Keep rollback plan ready**
4. **Use feature flags for risky changes**
5. **Automate as much as possible**
6. **Document deployment decisions**
7. **Run smoke tests after every deployment**

## Troubleshooting

### Deployment Fails

1. Check workflow logs in GitHub Actions
2. Verify health endpoints are responding
3. Check Azure App Service logs
4. Verify secrets are configured correctly

### Health Check Fails

1. Check application logs
2. Verify environment variables
3. Check resource availability (CPU, memory)
4. Test endpoints manually

### Rollback Fails

1. Verify Azure credentials
2. Check slot configuration
3. Manually swap slots via Azure Portal
4. Contact DevOps team

## Support

For issues or questions:
- Create an issue in the repository
- Contact the DevOps team
- Check Azure App Service diagnostics

