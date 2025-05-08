import request from 'supertest';
import app from '../src/app';

describe('GET /health', () => {
  it('should return service running', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.text).toBe('User Service is running!');
  });
});
