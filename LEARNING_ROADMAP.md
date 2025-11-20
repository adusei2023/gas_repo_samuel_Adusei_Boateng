# 🎓 GAS Project - Your Learning Roadmap

## Welcome, Junior Engineer! 👋

This document is your **step-by-step guide** to understanding and mastering this project. I've organized everything into phases, from beginner to advanced.

---

## 🗺️ Your Journey Overview

```
Phase 1: Basics          → Understanding what you have
Phase 2: Testing         → Making sure it works
Phase 3: Docker          → Containerization
Phase 4: Monitoring      → Observability with Prometheus + Grafana
Phase 5: Deployments     → Blue-Green & Canary strategies
Phase 6: CI/CD           → Automation with GitHub Actions
Phase 7: Cloud           → Azure deployment (future)
```

---

## ✅ Phase 1: Understanding the Basics (START HERE)

### What You'll Learn
- How Express.js works
- What health checks are and why they matter
- What metrics are and how Prometheus uses them
- How to read and modify the code

### Tasks

#### Task 1.1: Start the Application
```bash
npm start
```

**Expected:** Server starts on port 3000

#### Task 1.2: Test All Endpoints

Open a new terminal and run:

```bash
# Test root endpoint
curl http://localhost:3000/

# Test health check
curl http://localhost:3000/health

# Test liveness probe
curl http://localhost:3000/health/live

# Test readiness probe
curl http://localhost:3000/health/ready

# Test metrics
curl http://localhost:3000/metrics

# Test API endpoints
curl http://localhost:3000/api
curl http://localhost:3000/api/data
curl "http://localhost:3000/api/slow?delay=500"
```

#### Task 1.3: Read the Code

Open these files and try to understand them:

1. **`src/index.js`** (lines 1-100)
   - Look for `app.get()` - these define routes
   - Look for `app.use()` - these are middleware
   - Find where the server starts listening

2. **`src/health.js`**
   - Find the `healthCheck()` function
   - See what information it returns
   - Notice how it uses `process.uptime()` and `process.memoryUsage()`

3. **`src/metrics.js`**
   - Find where metrics are defined
   - Look for `new Counter()` and `new Histogram()`
   - See how the middleware tracks requests

#### Task 1.4: Make a Small Change

**Exercise:** Add a new endpoint that returns your name!

1. Open `src/index.js`
2. Find the section with `app.get()` routes
3. Add this code:

```javascript
// Your custom endpoint
app.get('/api/me', (req, res) => {
  res.json({
    name: 'Your Name Here',
    role: 'Junior DevOps Engineer',
    learning: 'CI/CD and Deployment Strategies'
  });
});
```

4. Restart the server (`Ctrl+C`, then `npm start`)
5. Test it: `curl http://localhost:3000/api/me`

**Success Criteria:** You see your name in the response!

---

## ✅ Phase 2: Testing & Quality

### What You'll Learn
- How automated testing works
- What unit tests vs integration tests are
- How code coverage works
- What linting is and why it matters

### Tasks

#### Task 2.1: Run All Tests
```bash
npm test
```

**Expected:** 18 tests pass with 81%+ coverage

#### Task 2.2: Understand Test Types

**Unit Tests** (`tests/unit/`)
- Test individual functions in isolation
- Fast and focused
- Example: Testing `healthCheck()` function

**Integration Tests** (`tests/integration/`)
- Test multiple components together
- Test actual HTTP requests
- Example: Testing `/health` endpoint

**E2E Tests** (`tests/e2e/`)
- Test the entire system
- Simulate real user scenarios
- Require running server

#### Task 2.3: Read a Test File

Open `tests/unit/health.test.js`:

```javascript
describe('Health Check', () => {
  it('should return healthy status', async () => {
    const result = await healthCheck();
    expect(result.status).toBe('healthy');
  });
});
```

**Understand:**
- `describe()` groups related tests
- `it()` defines a single test
- `expect()` checks if something is true

#### Task 2.4: Write Your Own Test

Create `tests/unit/custom.test.js`:

```javascript
describe('My Custom Tests', () => {
  it('should add two numbers', () => {
    const result = 2 + 2;
    expect(result).toBe(4);
  });

  it('should concatenate strings', () => {
    const greeting = 'Hello' + ' ' + 'World';
    expect(greeting).toBe('Hello World');
  });
});
```

Run: `npm test`

**Success Criteria:** Your new tests pass!

#### Task 2.5: Check Code Quality
```bash
npm run lint
```

**Expected:** No errors (all code follows style guide)

---

## ✅ Phase 3: Docker Basics

### What You'll Learn
- What Docker is and why we use it
- How to build container images
- How to run containers
- How Docker Compose orchestrates multiple containers

### Prerequisites
- Docker Desktop must be installed and running

### Tasks

#### Task 3.1: Understand the Dockerfile

Open `docker/Dockerfile` and read the comments:

```dockerfile
# Stage 1: Base image
FROM node:18-alpine AS base
# Uses lightweight Alpine Linux with Node.js 18

# Stage 2: Dependencies
FROM base AS dependencies
COPY package*.json ./
RUN npm ci --only=production
# Installs only production dependencies

# Stage 3: Production
FROM base AS production
COPY --from=dependencies /app/node_modules ./node_modules
COPY src ./src
# Copies code and dependencies
```

**Key Concept:** Multi-stage builds keep images small!

#### Task 3.2: Build Your Image
```bash
npm run docker:build
```

**What happens:**
1. Docker reads the Dockerfile
2. Downloads Node.js base image
3. Installs dependencies
4. Copies your code
5. Creates final image tagged as `gas-app`

**Expected:** "Successfully built" message

#### Task 3.3: Run Your Container
```bash
npm run docker:run
```

**What happens:**
- Container starts from your image
- Port 3000 inside container → port 3000 on your machine
- App runs in isolated environment

#### Task 3.4: Test Containerized App
```bash
curl http://localhost:3000/health
```

**Success Criteria:** Same response as before!

#### Task 3.5: Explore Docker Commands

```bash
# List running containers
docker ps

# List all containers
docker ps -a

# List images
docker images

# Stop container
docker stop <container-id>

# Remove container
docker rm <container-id>

# View logs
docker logs <container-id>
```

---

## ✅ Phase 4: Monitoring with Prometheus & Grafana

### What You'll Learn
- How Prometheus collects metrics
- How Grafana visualizes data
- How to create dashboards
- How to monitor application health

### Tasks

#### Task 4.1: Start Monitoring Stack
```bash
cd docker
docker-compose up -d
cd ..
```

**What this starts:**
- Your application (port 3000)
- Prometheus (port 9090)
- Grafana (port 3001)
- Nginx (port 8080)

#### Task 4.2: Access Prometheus

Open browser: http://localhost:9090

**Try these queries:**
```
# Total requests
gas_http_requests_total

# Requests per second
rate(gas_http_requests_total[1m])

# Average response time
rate(gas_http_request_duration_seconds_sum[1m]) / rate(gas_http_request_duration_seconds_count[1m])
```

#### Task 4.3: Access Grafana

Open browser: http://localhost:3001

**Login:**
- Username: `admin`
- Password: `admin`

**Explore:**
- Dashboards → Browse
- Look for "RED Metrics" dashboard
- Look for "Canary Comparison" dashboard

#### Task 4.4: Generate Traffic

Run this to generate metrics:

```bash
# Generate 100 requests
for i in {1..100}; do curl -s http://localhost:3000/api > /dev/null; done
```

Watch the metrics update in Prometheus and Grafana!

---

## 🎯 What's Next?

Continue to:
- **Phase 5:** Blue-Green & Canary Deployments
- **Phase 6:** GitHub Actions CI/CD
- **Phase 7:** Azure Cloud Deployment

---

## 📚 Learning Tips

1. **Don't rush** - Take time to understand each phase
2. **Experiment** - Try changing things and see what happens
3. **Read errors** - Error messages teach you a lot
4. **Ask questions** - No question is too basic
5. **Document** - Write notes about what you learn

---

## 🆘 Need Help?

- Check `GETTING_STARTED.md` for basics
- Check `docs/` folder for detailed guides
- Check `PROJECT_SUMMARY.md` for overview
- Check `CHECKLIST.md` for progress tracking

**You're doing great! Keep learning! 🚀**

