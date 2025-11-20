# GAS Project - Complete Setup Guide

This guide will walk you through setting up the GAS (GitHub Actions Staging) project from scratch.

## Prerequisites

Before you begin, ensure you have the following installed:

### Required
- **Node.js 18+**: [Download](https://nodejs.org/)
- **npm 9+**: Comes with Node.js
- **Git**: [Download](https://git-scm.com/)

### Optional (for Docker/Monitoring)
- **Docker Desktop**: [Download](https://www.docker.com/products/docker-desktop/)
- **Docker Compose**: Included with Docker Desktop

## Quick Start (5 minutes)

### 1. Clone and Install

```bash
# Navigate to project directory
cd gas_repo_template

# Install dependencies
npm install
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env if needed (optional for local development)
```

### 3. Run Tests

```bash
# Run all tests
npm test

# Run linting
npm run lint
```

### 4. Start the Application

```bash
# Development mode (with hot reload)
npm run dev

# Production mode
npm start
```

The application will be available at http://localhost:3000

## Detailed Setup

### Step 1: Install Dependencies

```bash
npm install
```

This installs:
- **express**: Web framework
- **prom-client**: Prometheus metrics
- **dotenv**: Environment configuration
- **winston**: Logging
- **jest**: Testing framework
- **supertest**: API testing
- **eslint**: Code linting
- **nodemon**: Development server

### Step 2: Environment Configuration

Create a `.env` file:

```env
NODE_ENV=development
PORT=3000
DEPLOYMENT_TYPE=local
LOG_LEVEL=info
```

**Environment Variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment (development/production/test) | `development` |
| `PORT` | Server port | `3000` |
| `DEPLOYMENT_TYPE` | Deployment type (local/stable/canary/blue/green) | `local` |
| `LOG_LEVEL` | Logging level (debug/info/warn/error) | `info` |

### Step 3: Verify Installation

```bash
# Run tests
npm test

# Run linting
npm run lint

# Check for security vulnerabilities
npm audit
```

### Step 4: Start Development Server

```bash
# Start with hot reload
npm run dev
```

Visit http://localhost:3000 to see the application.

## Docker Setup (Optional)

### Prerequisites
- Docker Desktop must be running

### Build Docker Image

```bash
# Build the image
npm run docker:build

# Or manually
docker build -t gas-app:latest -f docker/Dockerfile .
```

### Run Docker Container

```bash
# Run the container
npm run docker:run

# Or manually
docker run -p 3000:3000 -e NODE_ENV=production gas-app:latest
```

### Start Monitoring Stack

```bash
# Start Prometheus + Grafana
cd docker
docker-compose up -d
cd ..
```

**Access Monitoring:**
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001 (admin/admin)

## Testing

### Run All Tests

```bash
npm test
```

### Run Specific Test Suites

```bash
# Unit tests only
npm run test:unit

# Integration tests only
npm run test:integration

# E2E tests only (requires running server)
npm run test:e2e

# With coverage report
npm run test:coverage
```

### Test Coverage

The project maintains the following coverage thresholds:
- Branches: 55%
- Functions: 60%
- Lines: 70%
- Statements: 70%

## Linting and Code Quality

### Run Linter

```bash
# Check for issues
npm run lint

# Fix issues automatically
npm run lint:fix
```

### Code Style

The project follows the Airbnb JavaScript Style Guide with some modifications:
- No console warnings (logging is allowed)
- Trailing commas not required
- Max line length: 120 characters
- Line breaks: flexible (Windows/Unix compatible)

## Deployment Simulation

### Blue-Green Deployment

```bash
# Make scripts executable (Unix/Mac)
chmod +x scripts/*.sh

# Run blue-green simulation
./scripts/simulate-blue-green.sh
```

**On Windows (Git Bash):**
```bash
bash scripts/simulate-blue-green.sh
```

### Canary Deployment

```bash
# 10% canary traffic
./scripts/simulate-canary.sh 10

# 25% canary traffic
./scripts/simulate-canary.sh 25
```

### Cleanup

```bash
# Stop and remove all containers
./scripts/cleanup.sh
```

## API Endpoints

Once the server is running, you can test these endpoints:

### Health Checks
```bash
# Detailed health
curl http://localhost:3000/health

# Liveness probe
curl http://localhost:3000/health/live

# Readiness probe
curl http://localhost:3000/health/ready
```

### Metrics
```bash
# Prometheus metrics
curl http://localhost:3000/metrics
```

### API Endpoints
```bash
# Root endpoint
curl http://localhost:3000/

# API status
curl http://localhost:3000/api

# Sample data
curl http://localhost:3000/api/data

# Slow endpoint (with delay)
curl "http://localhost:3000/api/slow?delay=500"

# Error endpoint (for testing)
curl http://localhost:3000/api/error
```

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 3000
# Windows
netstat -ano | findstr :3000

# Unix/Mac
lsof -i :3000

# Kill the process or change PORT in .env
```

### Docker Issues

```bash
# Ensure Docker Desktop is running
docker --version

# Check Docker status
docker ps

# Restart Docker Desktop if needed
```

### Test Failures

```bash
# Clear Jest cache
npm test -- --clearCache

# Run tests with verbose output
npm test -- --verbose

# Run specific test file
npm test tests/unit/health.test.js
```

### Module Not Found

```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

## Next Steps

### 1. Local Development
- Start the development server: `npm run dev`
- Make changes to code
- Tests run automatically
- View changes at http://localhost:3000

### 2. Set Up Monitoring
- Start Docker Desktop
- Run `docker-compose -f docker/docker-compose.yml up -d`
- Access Grafana at http://localhost:3001
- Import dashboards from `infra/monitoring/grafana-dashboards/`

### 3. Test Deployments
- Run blue-green simulation
- Run canary simulation
- Monitor metrics in Grafana

### 4. Push to GitHub
```bash
# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: GAS project setup"

# Add remote (replace with your repo URL)
git remote add origin https://github.com/yourusername/gas_repo_template.git

# Push to GitHub
git push -u origin main
```

### 5. Configure GitHub Secrets

In your GitHub repository settings, add these secrets:
- `ACR_LOGIN_SERVER`: Azure Container Registry URL
- `ACR_USERNAME`: ACR username
- `ACR_PASSWORD`: ACR password
- `AZURE_CREDENTIALS`: Azure service principal credentials
- `AZURE_RESOURCE_GROUP`: Azure resource group name

### 6. Test CI/CD Pipelines
- Push to `develop` branch → Triggers staging deployment
- Push to `main` branch → Triggers production deployment
- Manually trigger canary deployment from Actions tab

## Additional Resources

- [Deployment Guide](DEPLOYMENT.md)
- [API Documentation](../README.md#api-documentation)
- [GitHub Actions Workflows](../.github/workflows/)
- [Monitoring Dashboards](../infra/monitoring/grafana-dashboards/)

## Support

If you encounter issues:
1. Check this guide's troubleshooting section
2. Review the main [README.md](../README.md)
3. Check GitHub Issues
4. Review workflow logs in GitHub Actions

## Summary Checklist

- [ ] Node.js 18+ installed
- [ ] Dependencies installed (`npm install`)
- [ ] Environment configured (`.env` file)
- [ ] Tests passing (`npm test`)
- [ ] Linting passing (`npm run lint`)
- [ ] Application runs locally (`npm start`)
- [ ] Docker image builds (optional)
- [ ] Monitoring stack running (optional)
- [ ] Deployment simulations tested (optional)
- [ ] Code pushed to GitHub
- [ ] GitHub secrets configured
- [ ] CI/CD pipelines tested

**Congratulations! Your GAS project is now set up and ready for development!** 🎉

