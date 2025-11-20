const { getMetrics, metricsHandler } = require('../../src/metrics');

describe('Metrics Module', () => {
  describe('getMetrics', () => {
    it('should return metrics objects', () => {
      const metrics = getMetrics();

      expect(metrics).toHaveProperty('httpRequestCounter');
      expect(metrics).toHaveProperty('httpRequestDuration');
      expect(metrics).toHaveProperty('httpRequestSize');
      expect(metrics).toHaveProperty('httpResponseSize');
      expect(metrics).toHaveProperty('activeConnections');
      expect(metrics).toHaveProperty('versionInfo');
      expect(metrics).toHaveProperty('deploymentType');
      expect(metrics).toHaveProperty('register');
    });
  });

  describe('metricsHandler', () => {
    let req;
    let res;

    beforeEach(() => {
      req = {};
      res = {
        set: jest.fn(),
        end: jest.fn(),
        status: jest.fn().mockReturnThis()
      };
    });

    it('should return metrics in Prometheus format', async () => {
      await metricsHandler(req, res);

      expect(res.set).toHaveBeenCalledWith('Content-Type', expect.any(String));
      expect(res.end).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      const errorRes = {
        set: jest.fn(() => {
          throw new Error('Test error');
        }),
        status: jest.fn().mockReturnThis(),
        end: jest.fn()
      };

      await metricsHandler(req, errorRes);

      expect(errorRes.status).toHaveBeenCalledWith(500);
    });
  });
});
