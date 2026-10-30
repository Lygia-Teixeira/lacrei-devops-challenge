const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const ALLOWED_ORIGINS = (process.env.CORS_ALLOWED_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

function buildApp() {
  const app = express();

  app.use(helmet());
  app.use(
    cors({
      origin: ALLOWED_ORIGINS.length > 0 ? ALLOWED_ORIGINS : false,
      methods: ['GET'],
    })
  );
  app.disable('x-powered-by');

  app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
      const durationMs = Date.now() - start;
      console.log(
        JSON.stringify({
          level: 'info',
          msg: 'request',
          method: req.method,
          path: req.path,
          status: res.statusCode,
          durationMs,
          timestamp: new Date().toISOString(),
        })
      );
    });
    next();
  });

  app.get('/status', (req, res) => {
    res.status(200).json({
      status: 'ok',
      service: 'lacrei-devops-challenge',
      environment: process.env.NODE_ENV || 'development',
      version: process.env.APP_VERSION || 'unknown',
      timestamp: new Date().toISOString(),
      uptimeSeconds: process.uptime(),
    });
  });

  app.get('/', (req, res) => {
    res.status(200).json({ message: 'Lacrei Saúde DevOps Challenge API' });
  });

  app.use((req, res) => {
    res.status(404).json({ error: 'not_found' });
  });

  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    console.error(JSON.stringify({ level: 'error', msg: err.message, stack: err.stack }));
    res.status(500).json({ error: 'internal_server_error' });
  });

  return app;
}

module.exports = { buildApp };
