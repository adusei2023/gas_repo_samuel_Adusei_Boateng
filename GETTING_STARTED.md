# Getting Started with Your GAS Project

## 🎓 Welcome, Student!

This guide will help you understand what's already built in your project and how to work with it step-by-step.

## 📚 What You Have (Learning Overview)

Your project is a **complete CI/CD demonstration** that shows modern DevOps practices. Think of it like this:

- **Your App** = A restaurant kitchen (serves requests)
- **Health Checks** = Kitchen inspection (is everything working?)
- **Metrics** = Performance tracking (how many orders, how fast?)
- **Docker** = Portable kitchen (works anywhere)
- **CI/CD** = Automated quality control and delivery
- **Blue-Green/Canary** = Safe ways to update without breaking things

---

## 🚀 Phase 1: Understanding Your Application

### What's Already Built

Your `src/index.js` is a complete Express.js web server with:

1. **Root Endpoint** (`/`) - Welcome page
2. **Health Checks** (`/health`, `/health/live`, `/health/ready`)
3. **Metrics** (`/metrics`) - Prometheus-compatible metrics
4. **API Endpoints** (`/api`, `/api/data`, `/api/slow`, `/api/error`)

### Let's Test It!

#### Step 1: Start the Server

```bash
npm start
```

**What you should see:**
```
info: Server running on http://0.0.0.0:3000
info: Environment: development
info: Deployment Type: local
```

#### Step 2: Test the Endpoints

Open your browser or use `curl`:

**1. Root Endpoint:**
```bash
curl http://localhost:3000/
```

**Expected Response:**
```json
{
  "message": "GAS Project - GitHub Actions Staging",
  "version": "1.0.0",
  "environment": "development",
  "endpoints": ["/health", "/metrics", "/api"]
}
```

**2. Health Check:**
```bash
curl http://localhost:3000/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-18T...",
  "uptime": 123.45,
  "version": "1.0.0",
  "environment": "development"
}
```

**3. Metrics (Prometheus format):**
```bash
curl http://localhost:3000/metrics
```

**Expected Response:** Text format with metrics like:
```
# HELP gas_http_requests_total Total number of HTTP requests
# TYPE gas_http_requests_total counter
gas_http_requests_total{method="GET",route="/",status_code="200"} 1
```

#### Step 3: Stop the Server

Press `Ctrl+C` in the terminal where the server is running.

---

## 📖 Understanding the Code Structure

### `src/index.js` - The Main Application

This is your **entry point**. It:
- Creates an Express server
- Sets up middleware (logging, metrics)
- Defines routes
- Starts listening on port 3000

**Key Concept:** Think of this as the "main office" that coordinates everything.

### `src/health.js` - Health Check Module

This provides **three types of health checks**:

1. **`/health`** - Detailed health info (like a full medical checkup)
2. **`/health/live`** - Is the app alive? (like checking pulse)
3. **`/health/ready`** - Is the app ready to serve traffic? (like checking if a store is open)

**Why do we need this?**
- Kubernetes/Docker can automatically restart unhealthy containers
- Load balancers can route traffic away from unhealthy instances

### `src/metrics.js` - Prometheus Metrics

This tracks **performance metrics**:
- How many requests? (Rate)
- How many errors? (Errors)
- How long do requests take? (Duration)

This is called **RED metrics** (Rate, Errors, Duration).

**Why do we need this?**
- To monitor performance in production
- To detect problems before users complain
- To understand usage patterns

---

## 🧪 Phase 2: Running Tests

Your project has **18 tests** already written!

### Run All Tests

```bash
npm test
```

**What this does:**
- Runs unit tests (test individual functions)
- Runs integration tests (test API endpoints)
- Generates coverage report (how much code is tested)

**Expected Output:**
```
Test Suites: 3 passed, 3 total
Tests:       18 passed, 18 total
Coverage:    81.75% statements
```

### Run Specific Test Types

```bash
# Only unit tests
npm run test:unit

# Only integration tests
npm run test:integration

# E2E tests (requires running server)
npm run test:e2e
```

---

## 🔍 Phase 3: Code Quality (Linting)

Linting checks your code for style issues and potential bugs.

### Check Code Quality

```bash
npm run lint
```

**Expected Output:**
```
(No errors - all files pass!)
```

### Auto-Fix Issues

```bash
npm run lint:fix
```

This automatically fixes formatting issues like spacing, quotes, etc.

---

## 📦 Phase 4: Understanding Docker

Docker lets you package your app so it runs the same everywhere.

### Build Docker Image

```bash
npm run docker:build
```

**What this does:**
- Reads `docker/Dockerfile`
- Creates a container image with your app
- Tags it as `gas-app`

**Note:** Docker Desktop must be running!

### Run Docker Container

```bash
npm run docker:run
```

**What this does:**
- Starts a container from your image
- Maps port 3000 inside container to port 3000 on your machine
- Your app is now running in an isolated environment

### Test Docker Container

```bash
curl http://localhost:3000/health
```

Should work the same as before!

---

## 🎯 Next Steps

Now that you understand the basics, you're ready to explore:

1. **Phase 5:** Docker Compose (Prometheus + Grafana)
2. **Phase 6:** Blue-Green Deployment Simulation
3. **Phase 7:** Canary Deployment Simulation
4. **Phase 8:** GitHub Actions Workflows
5. **Phase 9:** Azure Deployment

---

## 🆘 Troubleshooting

### Port Already in Use

```bash
# Windows
netstat -ano | findstr :3000

# Kill the process or change PORT in .env
```

### Tests Failing

```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
```

### Docker Not Working

```bash
# Make sure Docker Desktop is running
docker --version
```

---

## 📚 Learning Resources

- **Express.js:** https://expressjs.com/
- **Prometheus:** https://prometheus.io/docs/introduction/overview/
- **Docker:** https://docs.docker.com/get-started/
- **Jest Testing:** https://jestjs.io/docs/getting-started

---

**Ready to continue? Ask me about any phase you want to explore next!** 🚀

