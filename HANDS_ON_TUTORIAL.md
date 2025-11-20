# 🛠️ Hands-On Tutorial: Learn by Doing

## Introduction

This tutorial will guide you through **actually using** your GAS project. You'll run commands, see results, and understand what's happening at each step.

**Time Required:** 30-45 minutes  
**Difficulty:** Beginner-friendly  
**Prerequisites:** Node.js installed, project dependencies installed (`npm install`)

---

## 🎯 Tutorial 1: Your First API Request (5 minutes)

### Step 1: Start the Server

Open your terminal in the project directory:

```bash
npm start
```

**What you should see:**
```
info: Server running on http://0.0.0.0:3000
info: Environment: development
```

✅ **Success!** Your server is running.

### Step 2: Open a Second Terminal

Keep the first terminal running. Open a **new terminal** window.

### Step 3: Make Your First Request

```bash
curl http://localhost:3000/
```

**What you should see:**
```json
{
  "message": "GAS Project - GitHub Actions Staging",
  "version": "1.0.0",
  "environment": "development",
  "deploymentType": "local",
  "endpoints": [
    "/health",
    "/health/live",
    "/health/ready",
    "/metrics",
    "/api",
    "/api/data"
  ]
}
```

✅ **Success!** Your API is responding.

### Step 4: Check the Server Logs

Go back to the first terminal. You should see:

```
info: GET / 200 - 5ms
```

This shows:
- **Method:** GET
- **Path:** /
- **Status:** 200 (success)
- **Time:** 5ms (how long it took)

**🎓 Learning Point:** Every request is logged automatically!

---

## 🎯 Tutorial 2: Understanding Health Checks (10 minutes)

### What Are Health Checks?

Health checks tell you if your application is working properly. Think of it like a doctor's checkup for your app!

### Step 1: Detailed Health Check

```bash
curl http://localhost:3000/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-18T10:30:00.000Z",
  "uptime": 45.123,
  "version": "1.0.0",
  "environment": "development",
  "deploymentType": "local",
  "system": {
    "platform": "win32",
    "arch": "x64",
    "nodeVersion": "v18.17.0"
  },
  "process": {
    "pid": 12345,
    "memory": {
      "rss": "50.23 MB",
      "heapTotal": "20.45 MB",
      "heapUsed": "15.67 MB"
    },
    "uptime": "45.12 seconds"
  }
}
```

**🎓 What This Tells You:**
- **status:** Is the app healthy?
- **uptime:** How long has it been running?
- **memory:** How much RAM is it using?
- **system:** What OS and Node version?

### Step 2: Liveness Probe

```bash
curl http://localhost:3000/health/live
```

**Response:**
```json
{
  "status": "alive",
  "timestamp": "2025-11-18T10:30:00.000Z"
}
```

**🎓 Purpose:** Kubernetes uses this to know if it should restart your container.

### Step 3: Readiness Probe

```bash
curl http://localhost:3000/health/ready
```

**Response:**
```json
{
  "status": "ready",
  "timestamp": "2025-11-18T10:30:00.000Z",
  "checks": {
    "server": "ok",
    "dependencies": "ok"
  }
}
```

**🎓 Purpose:** Load balancers use this to know if they should send traffic to your app.

---

## 🎯 Tutorial 3: Exploring Metrics (15 minutes)

### What Are Metrics?

Metrics are **measurements** of your application's performance. Like a car's dashboard showing speed, fuel, temperature.

### Step 1: View Raw Metrics

```bash
curl http://localhost:3000/metrics
```

**Response (excerpt):**
```
# HELP gas_http_requests_total Total number of HTTP requests
# TYPE gas_http_requests_total counter
gas_http_requests_total{method="GET",route="/",status_code="200"} 1

# HELP gas_http_request_duration_seconds HTTP request duration in seconds
# TYPE gas_http_request_duration_seconds histogram
gas_http_request_duration_seconds_bucket{le="0.005",method="GET",route="/"} 1
```

**🎓 Understanding the Format:**
- `# HELP` - Describes what the metric measures
- `# TYPE` - Type of metric (counter, histogram, gauge)
- The actual values with labels in `{}`

### Step 2: Generate Some Traffic

Let's create some data to measure!

```bash
# Make 10 requests to different endpoints
for i in {1..10}; do curl -s http://localhost:3000/api > /dev/null; done
```

### Step 3: Check Metrics Again

```bash
curl http://localhost:3000/metrics | grep gas_http_requests_total
```

**You should see the counter increased!**

### Step 4: Test the Slow Endpoint

```bash
curl "http://localhost:3000/api/slow?delay=1000"
```

This takes 1 second to respond (simulating a slow database query).

### Step 5: Check Duration Metrics

```bash
curl http://localhost:3000/metrics | grep duration
```

**You'll see different buckets showing response times!**

---

## 🎯 Tutorial 4: Running Tests (10 minutes)

### Step 1: Stop the Server

Go to the first terminal and press `Ctrl+C`.

### Step 2: Run All Tests

```bash
npm test
```

**What happens:**
1. Jest starts
2. Runs 18 tests
3. Shows coverage report

**Expected output:**
```
PASS  tests/unit/health.test.js
PASS  tests/unit/metrics.test.js
PASS  tests/integration/api.test.js

Test Suites: 3 passed, 3 total
Tests:       18 passed, 18 total
Snapshots:   0 total
Time:        2.5 s

Coverage:
Statements   : 81.75%
Branches     : 59.09%
Functions    : 65.38%
Lines        : 84.73%
```

✅ **Success!** All tests pass.

### Step 3: Run Only Unit Tests

```bash
npm run test:unit
```

**Faster!** Only tests individual functions.

### Step 4: Look at a Test File

Open `tests/unit/health.test.js` in your editor.

**You'll see:**
```javascript
describe('Health Check', () => {
  it('should return healthy status', async () => {
    const result = await healthCheck();
    expect(result.status).toBe('healthy');
    expect(result).toHaveProperty('uptime');
  });
});
```

**🎓 Reading Tests:**
- `describe()` = Group of related tests
- `it()` = One specific test
- `expect()` = What we're checking

---

## 🎯 Tutorial 5: Code Quality Check (5 minutes)

### Step 1: Run Linter

```bash
npm run lint
```

**Expected:** No errors!

### Step 2: Intentionally Break Something

Open `src/index.js` and add this line at the end:

```javascript
var x = 5
```

### Step 3: Run Linter Again

```bash
npm run lint
```

**You'll see errors:**
```
error  Unexpected var, use let or const instead  no-var
error  Missing semicolon                         semi
```

### Step 4: Auto-Fix

```bash
npm run lint:fix
```

**The linter fixes it automatically!**

### Step 5: Undo Your Change

Remove that line you added.

---

## 🎉 Congratulations!

You've completed the hands-on tutorial! You now know how to:

✅ Start and stop the server  
✅ Make API requests  
✅ Understand health checks  
✅ Read metrics  
✅ Run tests  
✅ Check code quality  

---

## 🚀 What's Next?

Continue with:
- **Docker Tutorial** - Run your app in containers
- **Monitoring Tutorial** - Set up Prometheus + Grafana
- **Deployment Tutorial** - Blue-Green and Canary strategies

Check `LEARNING_ROADMAP.md` for the full path!

**Keep experimenting and learning! 🎓**

