require('dotenv').config();
const express = require('express');
const winston = require('winston');
const appInsights = require('applicationinsights');
const { healthCheck, livenessProbe, readinessProbe } = require('./health');
const { metricsMiddleware, metricsHandler } = require('./metrics');

// Configure Winston logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

// Configure Application Insights (Azure monitoring)
if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  appInsights.setup(process.env.APPLICATIONINSIGHTS_CONNECTION_STRING)
    .setAutoDependencyCorrelation(true)
    .setAutoCollectRequests(true)
    .setAutoCollectPerformance(true, true)
    .setAutoCollectExceptions(true)
    .setAutoCollectDependencies(true)
    .setAutoCollectConsole(true)
    .setUseDiskRetryCaching(true)
    .setSendLiveMetrics(true)
    .start();

  logger.info('Application Insights initialized');
}

// Create Express app
const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// Apply metrics middleware to all routes
app.use(metricsMiddleware);

// Health check endpoints
app.get('/health', healthCheck);
app.get('/health/live', livenessProbe);
app.get('/health/ready', readinessProbe);

// Metrics endpoint
app.get('/metrics', metricsHandler);

// Root endpoint
app.get('/', (req, res) => {
  const deploymentType = process.env.DEPLOYMENT_TYPE || 'stable';
  const { version } = require('../package.json');

  res.json({
    message: 'GAS Project - GitHub Actions Staging',
    version,
    deploymentType,
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/health',
      liveness: '/health/live',
      readiness: '/health/ready',
      metrics: '/metrics',
      api: '/api'
    }
  });
});

// API endpoints
app.get('/api', (req, res) => {
  res.json({
    message: 'API is working',
    version: require('../package.json').version,
    timestamp: new Date().toISOString()
  });
});

// Sample API endpoint for testing
app.get('/api/data', (req, res) => {
  res.json({
    data: [
      { id: 1, name: 'Item 1', value: 100 },
      { id: 2, name: 'Item 2', value: 200 },
      { id: 3, name: 'Item 3', value: 300 }
    ],
    timestamp: new Date().toISOString()
  });
});

// Error simulation endpoint (for testing)
app.get('/api/error', (req, res) => {
  logger.error('Simulated error endpoint called');
  res.status(500).json({
    error: 'Simulated error',
    message: 'This is a test error endpoint',
    timestamp: new Date().toISOString()
  });
});

// Slow endpoint (for testing latency)
app.get('/api/slow', async (req, res) => {
  const delay = parseInt(req.query.delay || '2000', 10);
  logger.info(`Slow endpoint called with delay: ${delay}ms`);

  await new Promise((resolve) => setTimeout(resolve, delay));

  res.json({
    message: 'Slow response completed',
    delay: `${delay}ms`,
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  logger.warn(`404 - Not Found: ${req.method} ${req.path}`);
  res.status(404).json({
    error: 'Not Found',
    message: `Cannot ${req.method} ${req.path}`,
    timestamp: new Date().toISOString()
  });
});

// Error handler
app.use((err, req, res, _next) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'production' ? 'An error occurred' : err.message,
    timestamp: new Date().toISOString()
  });
});

// Graceful shutdown handler
function gracefulShutdown(signal) {
  logger.info(`${signal} received, starting graceful shutdown...`);

  server.close(() => {
    logger.info('HTTP server closed');

    // Close Application Insights
    if (appInsights.defaultClient) {
      appInsights.defaultClient.flush({
        callback: () => {
          logger.info('Application Insights flushed');
          process.exit(0);
        }
      });
    } else {
      process.exit(0);
    }
  });

  // Force shutdown after 30 seconds
  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 30000);
}

// Start server
const server = app.listen(PORT, HOST, () => {
  logger.info(`Server started on ${HOST}:${PORT}`);
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`Deployment Type: ${process.env.DEPLOYMENT_TYPE || 'stable'}`);
  logger.info(`Health check: http://${HOST}:${PORT}/health`);
  logger.info(`Metrics: http://${HOST}:${PORT}/metrics`);
});

// Handle shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  gracefulShutdown('uncaughtException');
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

module.exports = app;
