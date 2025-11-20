# GAS Project - System Overview

## What is GAS?

**GAS** stands for **GitHub Actions Staging**. It's a production-ready Node.js application that demonstrates modern deployment strategies and CI/CD best practices.

This project showcases:
- ✅ Continuous Integration (CI) with automated testing and linting
- ✅ Continuous Deployment (CD) with multiple strategies
- ✅ Blue-Green deployments for zero-downtime releases
- ✅ Canary deployments for gradual rollouts
- ✅ Comprehensive monitoring with Prometheus and Grafana
- ✅ Health checks and graceful shutdown
- ✅ Production-ready error handling and logging

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│  (Code, Tests, Workflows, Infrastructure as Code)           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │  GitHub Actions (CI)   │
        │  - Lint               │
        │  - Test               │
        │  - Build              │
        │  - Security Scan      │
        └────────────┬───────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │  Azure Container       │
        │  Registry (ACR)        │
        │  (Docker Images)       │
        └────────────┬───────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
   ┌─────────────┐         ┌──────────────┐
   │  Staging    │         │  Production  │
   │  Slot       │         │  (Blue/Green)│
   └─────────────┘         └──────────────┘
        │                         │
        ▼                         ▼
   ┌─────────────┐         ┌──────────────┐
   │ Prometheus  │         │  Grafana     │
   │ (Metrics)   │         │ (Dashboard)  │
   └─────────────┘         └──────────────┘
```

## Key Components

### 1. Application (Node.js + Express)

**Location:** `src/`

The core application provides:
- REST API endpoints
- Health check endpoints (`/health`, `/health/live`, `/health/ready`)
- Prometheus metrics endpoint (`/metrics`)
- Graceful shutdown handling
- Structured logging with Winston

**Key Files:**
- `src/index.js` - Main application server
- `src/health.js` - Health check handlers
- `src/metrics.js` - Prometheus metrics collection

### 2. CI/CD Pipelines (GitHub Actions)

**Location:** `.github/workflows/`

Automated workflows:
- **ci.yml** - Runs on every push/PR (lint, test, build, security scan)
- **cd-staging.yml** - Deploys to staging on `develop` branch
- **cd-production.yml** - Blue-Green deployment on `main` branch
- **canary.yml** - Canary deployment with traffic splitting
- **rollback.yml** - Manual rollback capability

### 3. Infrastructure as Code

**Location:** `infra/`

- **Azure Scripts** - Automated resource creation and configuration
- **Monitoring Config** - Prometheus and Grafana setup
- **Nginx Config** - Load balancer for canary deployments

### 4. Docker & Containerization

**Location:** `docker/`

- **Dockerfile** - Multi-stage build for optimized production image
- **docker-compose.yml** - Local development stack with monitoring

### 5. Tests

**Location:** `tests/`

- **Unit Tests** - Test individual functions
- **Integration Tests** - Test API endpoints
- **E2E Tests** - Test complete workflows

## Deployment Strategies

### Blue-Green Deployment

**What:** Two identical production environments (Blue and Green)

**How it works:**
1. Deploy new version to inactive slot (Green)
2. Run tests on Green
3. Swap traffic from Blue to Green (instant)
4. Blue becomes the backup

**Benefits:**
- Zero-downtime deployments
- Instant rollback (swap back to Blue)
- Easy to test before going live

**When to use:** Major releases, critical updates

### Canary Deployment

**What:** Gradually roll out new version to a percentage of users

**How it works:**
1. Deploy new version to canary slot
2. Route 10% traffic to canary
3. Monitor metrics (errors, latency)
4. Gradually increase traffic (25%, 50%, 100%)
5. Promote to production or rollback

**Benefits:**
- Detect issues early with real traffic
- Minimize blast radius of bugs
- Gradual rollout reduces risk

**When to use:** New features, experimental changes

### Staging Deployment

**What:** Pre-production environment for testing

**How it works:**
1. Deploy to staging slot on `develop` branch
2. Run smoke tests
3. Manual testing by team
4. Promote to production when ready

**Benefits:**
- Test in production-like environment
- Catch issues before production
- Team can validate changes

**When to use:** Before every production release

## Monitoring & Observability

### Prometheus

Collects metrics from the application:
- HTTP request count, duration, size
- Node.js process metrics (CPU, memory, GC)
- Custom application metrics
- Deployment type tracking

**Access:** `http://localhost:9090` (local)

### Grafana

Visualizes metrics in dashboards:
- **RED Metrics Dashboard** - Request Rate, Error Rate, Duration
- **Canary Comparison Dashboard** - Side-by-side comparison of stable vs canary

**Access:** `http://localhost:3001` (local)
**Default Credentials:** admin / admin

### Health Checks

Three health check endpoints:

1. **`/health`** - Detailed health information
   - System info (OS, Node version, memory)
   - Process info (PID, memory usage)
   - Uptime

2. **`/health/live`** - Liveness probe (Kubernetes)
   - Simple "alive" status
   - Used to detect if process is running

3. **`/health/ready`** - Readiness probe (Kubernetes)
   - Checks if app is ready to serve traffic
   - Can include dependency checks

## Local Development

### Quick Start

```bash
# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Start app in development mode
npm run dev

# Run tests
npm test

# Run linting
npm run lint
```

### Available Commands

```bash
npm start              # Start production server
npm run dev            # Start with hot reload (nodemon)
npm test               # Run all tests with coverage
npm run test:unit      # Unit tests only
npm run test:integration # Integration tests only
npm run lint           # Check code style
npm run lint:fix       # Fix code style issues
npm run build          # Build application
npm run docker:build   # Build Docker image
npm run docker:run     # Run Docker container
npm run docker:compose # Start full stack with monitoring
```

## Environment Variables

```env
NODE_ENV=development          # development, production, test
PORT=3000                     # Server port
HOST=localhost                # Server host
DEPLOYMENT_TYPE=stable        # stable, canary, blue, green
LOG_LEVEL=info                # debug, info, warn, error
APPLICATIONINSIGHTS_CONNECTION_STRING=  # Optional: Azure monitoring
```

## Project Structure

```
gas-project/
├── .github/workflows/          # CI/CD pipelines
├── src/                        # Application source code
│   ├── index.js               # Main server
│   ├── health.js              # Health checks
│   └── metrics.js             # Prometheus metrics
├── tests/                      # Test suites
│   ├── unit/                  # Unit tests
│   ├── integration/           # Integration tests
│   └── e2e/                   # End-to-end tests
├── docker/                     # Docker configuration
│   ├── Dockerfile             # Container image
│   └── docker-compose.yml     # Local stack
├── infra/                      # Infrastructure
│   ├── azure/                 # Azure scripts
│   └── monitoring/            # Prometheus & Grafana
├── docs/                       # Documentation
├── package.json               # Dependencies
└── README.md                  # Project README
```

## Next Steps

1. **Local Development** - See [SETUP_GUIDE.md](SETUP_GUIDE.md)
2. **Deployment** - See [DEPLOYMENT.md](DEPLOYMENT.md)
3. **Blue-Green** - See [blue-green-guide.md](blue-green-guide.md)
4. **Canary** - See [canary-guide.md](canary-guide.md)
5. **Monitoring** - See [infra/monitoring/setup-guide.md](../infra/monitoring/setup-guide.md)

## Key Concepts

### Graceful Shutdown

The application handles SIGTERM and SIGINT signals:
- Stops accepting new requests
- Waits for existing requests to complete
- Closes database connections
- Flushes monitoring data
- Exits cleanly

### Health Checks

Used by orchestration platforms (Kubernetes, Azure App Service):
- **Liveness** - Is the process alive?
- **Readiness** - Is it ready to serve traffic?
- **Startup** - Has it finished initializing?

### Metrics

Prometheus metrics track:
- **Counters** - Total requests, errors
- **Histograms** - Request duration, size
- **Gauges** - Active connections, memory usage
- **Summaries** - Request/response sizes

## Troubleshooting

### App won't start

```bash
# Check logs
npm run dev

# Check port is available
lsof -i :3000

# Check environment variables
cat .env
```

### Tests failing

```bash
# Run with verbose output
npm test -- --verbose

# Run specific test file
npm test tests/unit/health.test.js

# Run with coverage
npm run test:coverage
```

### Docker issues

```bash
# Check Docker is running
docker ps

# Build image
npm run docker:build

# Run container
npm run docker:run

# View logs
docker logs <container-id>
```

## Resources

- [Express.js Documentation](https://expressjs.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Azure App Service](https://docs.microsoft.com/en-us/azure/app-service/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)

## Support

For issues or questions:
1. Check the documentation in `docs/`
2. Review GitHub Issues
3. Check application logs
4. Review test output

---

**Last Updated:** 2025-11-20
**Version:** 1.0.0
