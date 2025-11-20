# Observability Guide

## What is Observability?

**Observability** is the ability to understand what's happening inside your application by examining its outputs.

The three pillars of observability are:
1. **Logs** - Detailed records of events
2. **Metrics** - Numerical measurements over time
3. **Traces** - Request flow through the system

## Why Observability Matters

✅ **Detect issues early** - Before users notice
✅ **Debug faster** - Understand what went wrong
✅ **Optimize performance** - Find bottlenecks
✅ **Understand user behavior** - See how app is used
✅ **Make data-driven decisions** - Based on real data

## Logs

### What are Logs?

Logs are detailed records of events that happen in your application.

```
[2025-11-20T14:30:45.123Z] INFO: Server started on port 3000
[2025-11-20T14:30:46.456Z] INFO: GET /health 200 2ms
[2025-11-20T14:30:47.789Z] ERROR: Database connection failed
```

### Logging in GAS Project

The application uses **Winston** for structured logging:

```javascript
logger.info('Server started', { port: 3000 });
logger.error('Database error', { error: err.message });
logger.warn('High memory usage', { memory: process.memoryUsage() });
```

### Viewing Logs

**Local Development:**

```bash
# Start app with logs
npm run dev

# Logs appear in terminal
```

**Azure Production:**

```bash
# Stream logs in real-time
az webapp log tail --name <app-name> --resource-group <resource-group>

# Download logs
az webapp log download --name <app-name> --resource-group <resource-group>
```

### Log Levels

| Level | Usage | Example |
|-------|-------|---------|
| DEBUG | Detailed debugging info | Variable values, function calls |
| INFO | General information | Server started, request received |
| WARN | Warning messages | Deprecated API, high memory |
| ERROR | Error messages | Failed request, exception |

### Best Practices

1. **Use structured logging**
   ```javascript
   logger.info('User login', { userId: 123, timestamp: Date.now() });
   ```

2. **Include context**
   ```javascript
   logger.error('Request failed', {
     method: 'GET',
     path: '/api/users',
     statusCode: 500,
     error: err.message
   });
   ```

3. **Don't log sensitive data**
   ```javascript
   // BAD
   logger.info('User password', { password: user.password });

   // GOOD
   logger.info('User authenticated', { userId: user.id });
   ```

4. **Use appropriate log levels**
   ```javascript
   logger.debug('Processing request');  // Too verbose for production
   logger.info('Request processed');    // Good
   logger.error('Request failed');      // For errors
   ```

## Metrics

### What are Metrics?

Metrics are numerical measurements that track application behavior over time.

```
Request Count: 1,234 requests/minute
Error Rate: 0.5%
Response Time (p95): 245ms
Memory Usage: 128MB
```

### Prometheus Metrics

The application uses **Prometheus** to collect metrics:

```
# Counter - Total requests
gas_http_requests_total{method="GET", route="/api", status_code="200"} 1234

# Histogram - Request duration
gas_http_request_duration_seconds_bucket{le="0.1"} 500
gas_http_request_duration_seconds_bucket{le="0.5"} 1200

# Gauge - Active connections
gas_active_connections 42

# Info - Version information
gas_app_version_info{version="1.0.0"} 1
```

### Accessing Metrics

**Local Development:**

```bash
# View raw metrics
curl http://localhost:3000/metrics

# View in Prometheus
# http://localhost:9090
```

**Production:**

```bash
# View metrics endpoint
curl https://<app-name>.azurewebsites.net/metrics
```

### Key Metrics to Monitor

1. **Request Rate**
   - Requests per second
   - Indicates traffic volume
   - Alert if drops suddenly

2. **Error Rate**
   - Percentage of failed requests
   - Should be < 1%
   - Alert if > 5%

3. **Response Time (p95, p99)**
   - 95th and 99th percentile latency
   - p95 should be < 500ms
   - Alert if > 1s

4. **CPU Usage**
   - Percentage of CPU used
   - Should be < 70%
   - Alert if > 85%

5. **Memory Usage**
   - Bytes of memory used
   - Should be < 70% of limit
   - Alert if > 85%

6. **Active Connections**
   - Number of concurrent connections
   - Indicates load
   - Alert if spikes unexpectedly

## Grafana Dashboards

### What is Grafana?

Grafana is a visualization tool that displays metrics from Prometheus.

### Accessing Grafana

**Local Development:**

```bash
# Start docker-compose
docker-compose up -d

# Access Grafana
# http://localhost:3001
# Username: admin
# Password: admin
```

### Available Dashboards

1. **RED Metrics Dashboard**
   - Request Rate
   - Error Rate
   - Duration (p95, p99)
   - Useful for monitoring overall health

2. **Canary Comparison Dashboard**
   - Side-by-side comparison of stable vs canary
   - Useful for canary deployments
   - Shows if canary is performing well

### Creating Custom Dashboards

1. Go to http://localhost:3001
2. Click "+" → "Dashboard"
3. Click "Add panel"
4. Select Prometheus datasource
5. Write PromQL query
6. Configure visualization
7. Save dashboard

### Example Queries

```promql
# Request rate (requests per second)
rate(gas_http_requests_total[1m])

# Error rate (percentage)
rate(gas_http_requests_total{status_code=~"5.."}[1m]) / rate(gas_http_requests_total[1m]) * 100

# Response time (p95)
histogram_quantile(0.95, gas_http_request_duration_seconds)

# Memory usage (MB)
process_resident_memory_bytes / 1024 / 1024

# CPU usage (percentage)
rate(process_cpu_seconds_total[1m]) * 100
```

## Health Checks

### What are Health Checks?

Health checks are endpoints that report the health status of your application.

### Health Check Endpoints

1. **`/health`** - Detailed health information
   ```json
   {
     "status": "healthy",
     "version": "1.0.0",
     "uptime": "2h 30m",
     "system": {
       "os": "Linux",
       "nodeVersion": "18.0.0",
       "memory": "128MB"
     }
   }
   ```

2. **`/health/live`** - Liveness probe
   ```json
   {
     "status": "alive"
   }
   ```

3. **`/health/ready`** - Readiness probe
   ```json
   {
     "status": "ready"
   }
   ```

### Using Health Checks

**Local Testing:**

```bash
# Check health
curl http://localhost:3000/health

# Check liveness
curl http://localhost:3000/health/live

# Check readiness
curl http://localhost:3000/health/ready
```

**Azure Configuration:**

```bash
# Configure health check
az webapp config set \
  --name <app-name> \
  --resource-group <resource-group> \
  --health-check-path /health/ready
```

## Tracing

### What is Tracing?

Tracing follows a request through your entire system to understand performance and identify bottlenecks.

### Application Insights

Azure provides **Application Insights** for tracing:

```bash
# Enable Application Insights
az monitor app-insights component create \
  --app <app-name> \
  --location <location> \
  --resource-group <resource-group> \
  --application-type web
```

### Viewing Traces

1. Go to Azure Portal
2. Application Insights
3. Performance → Transactions
4. Click on transaction to see trace

## Alerting

### Setting Up Alerts

**Grafana Alerts:**

```
1. Go to http://localhost:3001
2. Alerts → Alert rules
3. Create alert for:
   - Error rate > 5%
   - Response time > 1s
   - CPU > 85%
   - Memory > 85%
4. Set notification channel
```

**Azure Alerts:**

```bash
# Create alert for high error rate
az monitor metrics alert create \
  --name "High Error Rate" \
  --resource-group <resource-group> \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Web/sites/<app-name> \
  --condition "avg Http5xx > 50" \
  --window-size 5m \
  --evaluation-frequency 1m
```

### Alert Best Practices

1. **Alert on symptoms, not causes**
   - Alert on error rate, not CPU
   - Alert on response time, not memory

2. **Set appropriate thresholds**
   - Too low: false alarms
   - Too high: miss real issues

3. **Include context in alerts**
   - What is the alert?
   - Why should I care?
   - What should I do?

4. **Test alerts**
   - Verify they trigger correctly
   - Verify notifications work
   - Practice response

## Monitoring Checklist

### Before Deployment

- [ ] Logs are configured
- [ ] Metrics are being collected
- [ ] Dashboards are set up
- [ ] Health checks are working
- [ ] Alerts are configured

### During Deployment

- [ ] Monitor error rate
- [ ] Monitor response time
- [ ] Monitor resource usage
- [ ] Check logs for errors
- [ ] Verify health checks pass

### After Deployment

- [ ] Error rate returned to normal
- [ ] Response time is acceptable
- [ ] Resource usage is normal
- [ ] No errors in logs
- [ ] Users report no issues

## Troubleshooting

### Metrics Not Showing

```bash
# Check if Prometheus is scraping
# http://localhost:9090/targets

# Check if app is exposing metrics
curl http://localhost:3000/metrics

# Check Grafana datasource
# http://localhost:3001/datasources
```

### Logs Not Appearing

```bash
# Check log level
# Should be "info" or lower

# Check if logs are being written
# Look in /var/log/app.log

# Check Azure logging is enabled
az webapp log config \
  --name <app-name> \
  --resource-group <resource-group> \
  --application-logging filesystem
```

### Health Checks Failing

```bash
# Test health endpoint
curl http://localhost:3000/health/ready

# Check app logs
npm run dev

# Check if app is running
ps aux | grep node
```

## Best Practices

1. **Monitor continuously**
   - Don't wait for issues
   - Watch metrics in real-time
   - Set up alerts

2. **Use structured logging**
   - Include context
   - Use consistent format
   - Don't log sensitive data

3. **Collect meaningful metrics**
   - Focus on business metrics
   - Track user experience
   - Monitor resource usage

4. **Create useful dashboards**
   - Show what matters
   - Make trends visible
   - Enable quick decisions

5. **Test your observability**
   - Verify logs appear
   - Verify metrics are collected
   - Verify alerts trigger
   - Practice responding

6. **Document your setup**
   - How to access logs
   - How to view metrics
   - How to respond to alerts
   - Who to contact

## Next Steps

1. Set up local monitoring stack
2. Create custom dashboards
3. Configure alerts
4. Practice monitoring
5. Document procedures

---

**Last Updated:** 2025-11-20
**Version:** 1.0.0
