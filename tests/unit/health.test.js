const { healthCheck, livenessProbe, readinessProbe } = require('../../src/health');

describe('Health Check Module', () => {
  let req;
  let res;

  beforeEach(() => {
    req = {};
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis()
    };
  });

  describe('healthCheck', () => {
    it('should return 200 status with health data', () => {
      healthCheck(req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalled();

      const responseData = res.json.mock.calls[0][0];
      expect(responseData).toHaveProperty('status', 'healthy');
      expect(responseData).toHaveProperty('version');
      expect(responseData).toHaveProperty('timestamp');
      expect(responseData).toHaveProperty('uptime');
      expect(responseData).toHaveProperty('system');
      expect(responseData).toHaveProperty('process');
    });

    it('should include system information', () => {
      healthCheck(req, res);

      const responseData = res.json.mock.calls[0][0];
      expect(responseData.system).toHaveProperty('platform');
      expect(responseData.system).toHaveProperty('arch');
      expect(responseData.system).toHaveProperty('nodeVersion');
    });

    it('should include process information', () => {
      healthCheck(req, res);

      const responseData = res.json.mock.calls[0][0];
      expect(responseData.process).toHaveProperty('pid');
      expect(responseData.process).toHaveProperty('memory');
    });
  });

  describe('livenessProbe', () => {
    it('should return 200 status with alive status', () => {
      livenessProbe(req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalled();

      const responseData = res.json.mock.calls[0][0];
      expect(responseData).toHaveProperty('status', 'alive');
      expect(responseData).toHaveProperty('timestamp');
    });
  });

  describe('readinessProbe', () => {
    it('should return 200 status when ready', () => {
      readinessProbe(req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalled();

      const responseData = res.json.mock.calls[0][0];
      expect(responseData).toHaveProperty('status', 'ready');
      expect(responseData).toHaveProperty('timestamp');
    });
  });
});
