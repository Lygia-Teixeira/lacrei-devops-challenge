const request = require('supertest');
const { buildApp } = require('../src/app');

const app = buildApp();

describe('GET /status', () => {
  it('returns 200 and status ok', async () => {
    const res = await request(app).get('/status');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.service).toBe('lacrei-devops-challenge');
    expect(typeof res.body.timestamp).toBe('string');
  });
});

describe('GET /', () => {
  it('returns 200 with a welcome message', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBeDefined();
  });
});

describe('unknown route', () => {
  it('returns 404', async () => {
    const res = await request(app).get('/does-not-exist');
    expect(res.statusCode).toBe(404);
  });
});
