const promClient = require('prom-client');

// Create a Registry to register the metrics
const register = new promClient.Registry();

// Add default metrics (CPU, memory, event loop lag, etc.)
promClient.collectDefaultMetrics({
  register,
  prefix: 'gas_app_',
  gcDurationBuckets: [0.001, 0.01, 0.1, 1, 2, 5]
});

// Custom metrics

// HTTP request counter
const httpRequestCounter = new promClient.Counter({
  name: 'gas_http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// HTTP request duration histogram
const httpRequestDuration = new promClient.Histogram({
  name: 'gas_http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10],
  registers: [register]
});

// HTTP request size summary
const httpRequestSize = new promClient.Summary({
  name: 'gas_http_request_size_bytes',
  help: 'Size of HTTP requests in bytes',
  labelNames: ['method', 'route'],
  registers: [register]
});

// HTTP response size summary
const httpResponseSize = new promClient.Summary({
  name: 'gas_http_response_size_bytes',
  help: 'Size of HTTP responses in bytes',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// Active connections gauge
const activeConnections = new promClient.Gauge({
  name: 'gas_active_connections',
  help: 'Number of active connections',
  registers: [register]
});

// Application version info
const versionInfo = new promClient.Gauge({
  name: 'gas_app_version_info',
  help: 'Application version information',
  labelNames: ['version', 'node_version'],
  registers: [register]
});

// Set version info
const packageJson = require('../package.json');

versionInfo.labels(packageJson.version, process.version).set(1);

// Deployment type gauge (for canary deployments)
const deploymentType = new promClient.Gauge({
  name: 'gas_deployment_type',
  help: 'Deployment type: 0=stable, 1=canary',
  labelNames: ['type'],
  registers: [register]
});

// Set deployment type from environment variable
const isCanary = process.env.DEPLOYMENT_TYPE === 'canary';
deploymentType.labels(isCanary ? 'canary' : 'stable').set(isCanary ? 1 : 0);

/**
 * Middleware to track HTTP metrics
 */
function metricsMiddleware(req, res, next) {
  const start = Date.now();

  // Increment active connections
  activeConnections.inc();

  // Track request size
  const requestSize = parseInt(req.get('content-length') || '0', 10);

  // Override res.end to capture response metrics
  const originalEnd = res.end;
  res.end = function endWrapper(...args) {
    const duration = (Date.now() - start) / 1000; // Convert to seconds
    const route = req.route ? req.route.path : req.path;
    const statusCode = res.statusCode.toString();

    // Record metrics
    httpRequestCounter.labels(req.method, route, statusCode).inc();
    httpRequestDuration.labels(req.method, route, statusCode).observe(duration);

    if (requestSize > 0) {
      httpRequestSize.labels(req.method, route).observe(requestSize);
    }

    const responseSize = parseInt(res.get('content-length') || '0', 10);
    if (responseSize > 0) {
      httpResponseSize.labels(req.method, route, statusCode).observe(responseSize);
    }

    // Decrement active connections
    activeConnections.dec();

    // Call original end
    originalEnd.apply(res, args);
  };

  next();
}

/**
 * Metrics endpoint handler
 */
async function metricsHandler(req, res) {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
  } catch (error) {
    res.status(500).end(error.message);
  }
}

/**
 * Get current metrics (for testing)
 */
function getMetrics() {
  return {
    httpRequestCounter,
    httpRequestDuration,
    httpRequestSize,
    httpResponseSize,
    activeConnections,
    versionInfo,
    deploymentType,
    register
  };
}

module.exports = {
  metricsMiddleware,
  metricsHandler,
  getMetrics,
  register
};
