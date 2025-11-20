const request = require('supertest');

describe('E2E Deployment Tests', () => {
  const baseURL = process.env.TEST_URL || 'http://localhost:3000';

  describe('Application Availability', () => {
    it('should be accessible', async () => {
      const response = await request(baseURL).get('/');
      expect(response.status).toBe(200);
    });

    it('should have health endpoint available', async () => {
      const response = await request(baseURL).get('/health');
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
    });

    it('should have metrics endpoint available', async () => {
      const response = await request(baseURL).get('/metrics');
      expect(response.status).toBe(200);
    });
  });

  describe('Deployment Type Detection', () => {
    it('should report correct deployment type', async () => {
      const response = await request(baseURL).get('/');
      expect(response.body).toHaveProperty('deploymentType');
      expect(['stable', 'canary', 'blue', 'green', 'staging']).toContain(
        response.body.deploymentType
      );
    });
  });

  describe('Performance', () => {
    it('should respond within acceptable time', async () => {
      const start = Date.now();
      await request(baseURL).get('/api');
      const duration = Date.now() - start;

      expect(duration).toBeLessThan(1000); // Should respond within 1 second
    });
  });
});
