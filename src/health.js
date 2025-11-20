const os = require('os');
const packageJson = require('../package.json');

/**
 * Health check endpoint handler
 * Returns application status, version, and system information
 */
function healthCheck(req, res) {
  const uptime = process.uptime();
  const memoryUsage = process.memoryUsage();

  const healthData = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: packageJson.version,
    application: packageJson.name,
    uptime: {
      seconds: Math.floor(uptime),
      formatted: formatUptime(uptime)
    },
    system: {
      platform: os.platform(),
      arch: os.arch(),
      nodeVersion: process.version,
      hostname: os.hostname(),
      totalMemory: `${Math.round(os.totalmem() / 1024 / 1024)} MB`,
      freeMemory: `${Math.round(os.freemem() / 1024 / 1024)} MB`
    },
    process: {
      pid: process.pid,
      memory: {
        rss: `${Math.round(memoryUsage.rss / 1024 / 1024)} MB`,
        heapTotal: `${Math.round(memoryUsage.heapTotal / 1024 / 1024)} MB`,
        heapUsed: `${Math.round(memoryUsage.heapUsed / 1024 / 1024)} MB`,
        external: `${Math.round(memoryUsage.external / 1024 / 1024)} MB`
      }
    },
    environment: process.env.NODE_ENV || 'development'
  };

  res.status(200).json(healthData);
}

/**
 * Liveness probe - simple check if the application is running
 */
function livenessProbe(req, res) {
  res.status(200).json({
    status: 'alive',
    timestamp: new Date().toISOString()
  });
}

/**
 * Readiness probe - check if the application is ready to serve traffic
 */
function readinessProbe(req, res) {
  // Add checks for database connections, external services, etc.
  const isReady = true; // Placeholder - add actual readiness checks

  if (isReady) {
    res.status(200).json({
      status: 'ready',
      timestamp: new Date().toISOString()
    });
  } else {
    res.status(503).json({
      status: 'not ready',
      timestamp: new Date().toISOString()
    });
  }
}

/**
 * Format uptime in human-readable format
 */
function formatUptime(seconds) {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  const parts = [];
  if (days > 0) parts.push(`${days}d`);
  if (hours > 0) parts.push(`${hours}h`);
  if (minutes > 0) parts.push(`${minutes}m`);
  parts.push(`${secs}s`);

  return parts.join(' ');
}

module.exports = {
  healthCheck,
  livenessProbe,
  readinessProbe
};
