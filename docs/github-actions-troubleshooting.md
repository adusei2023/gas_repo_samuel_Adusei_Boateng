# GitHub Actions Troubleshooting Guide

## Overview

This guide helps you troubleshoot CI/CD workflow failures in GitHub Actions.

## Common Issues and Solutions

### 1. **Workflows Not Running**

**Problem:** Workflows don't trigger on push or pull request.

**Solutions:**
- Check that your branch matches the workflow trigger conditions
- Verify the workflow file syntax is correct (YAML formatting)
- Ensure the workflow file is in `.github/workflows/` directory
- Check GitHub repository settings → Actions → General → Workflow permissions

### 2. **npm Dependencies Not Found**

**Problem:** `npm ERR! code ENOENT` or `Cannot find module`

**Solution:** The workflow must install dependencies before running tests:
```yaml
- name: Install dependencies
  run: npm ci  # Use 'npm ci' instead of 'npm install' in CI
```

### 3. **Tests Failing in GitHub but Passing Locally**

**Problem:** Tests pass locally but fail in GitHub Actions.

**Causes:**
- Different Node.js version
- Missing environment variables
- Timing issues (tests too slow)
- File path issues (Windows vs Linux)

**Solutions:**
```yaml
# Ensure Node.js version matches
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '18'  # Match your local version

# Set environment variables
- name: Run tests
  env:
    NODE_ENV: test
  run: npm test
```

### 4. **ESLint Errors**

**Problem:** Linting fails with "Cannot find module" or "Unexpected token"

**Solutions:**
- Ensure `.eslintignore` exists and excludes `node_modules/`
- Check `.eslintrc.json` configuration
- Run locally: `npm run lint`

### 5. **Docker Build Failures**

**Problem:** Docker build fails in GitHub Actions

**Solutions:**
- Ensure `docker/Dockerfile` exists
- Check Docker build context is correct
- Verify all dependencies are in `package.json`

### 6. **Azure Deployment Secrets Not Configured**

**Problem:** Deployment jobs fail with "secret not found"

**Solution:** The workflows are designed to skip deployment if secrets aren't configured. To enable Azure deployment:

1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Add these secrets:
   - `ACR_LOGIN_SERVER` - Your Azure Container Registry login server
   - `ACR_USERNAME` - ACR username
   - `ACR_PASSWORD` - ACR password
   - `AZURE_CREDENTIALS` - Azure service principal credentials
   - `AZURE_RESOURCE_GROUP` - Your Azure resource group name

## Viewing Workflow Logs

1. Go to your GitHub repository
2. Click "Actions" tab
3. Select the workflow run
4. Click on the failed job
5. Expand the failed step to see detailed logs

## Local Testing Before Pushing

Always test locally before pushing to GitHub:

```bash
# Install dependencies
npm ci

# Run linting
npm run lint

# Run tests
npm test

# Build
npm run build

# Start the app
npm start
```

## Workflow Files

- **`.github/workflows/ci.yml`** - Runs on every push/PR (lint, test, build)
- **`.github/workflows/cd-staging.yml`** - Deploys to staging on develop push
- **`.github/workflows/cd-production.yml`** - Deploys to production on main push
- **`.github/workflows/canary.yml`** - Manual canary deployment
- **`.github/workflows/rollback.yml`** - Manual rollback

## Quick Checklist

- [ ] All tests pass locally: `npm test`
- [ ] Linting passes: `npm run lint`
- [ ] Build succeeds: `npm run build`
- [ ] App starts: `npm start`
- [ ] `.eslintignore` exists
- [ ] `jest.config.js` is configured
- [ ] `.env.example` has all required variables
- [ ] GitHub secrets are configured (if using Azure)
- [ ] Workflow files are in `.github/workflows/`
- [ ] Workflow YAML syntax is valid

## Getting Help

1. Check the workflow run logs in GitHub Actions
2. Run the same commands locally to reproduce the issue
3. Check the documentation in `docs/` directory
4. Review the error messages carefully - they usually indicate the exact problem

