import { OpenAPIHono } from '@hono/zod-openapi';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { requestId } from 'hono/request-id';
import { healthRoute } from './routes/health';
import { meRoute } from './routes/me';
import { AppError, errorEnvelope } from './common/errors';

const app = new OpenAPIHono();

const allowedOrigins = (process.env.CORS_ORIGINS ?? '')
  .split(',')
  .map((value) => value.trim())
  .filter(Boolean);

app.use(
  '*',
  cors({
    origin: (origin) => {
      if (allowedOrigins.includes(origin)) return origin;
      if (/^https:\/\/[a-z0-9-]+\.vercel\.app$/.test(origin)) return origin;
      if (/^http:\/\/localhost(:\d+)?$/.test(origin)) return origin;
      return null;
    },
  }),
);

app.use('*', logger());
app.use('*', requestId());

app.onError((err, c) => {
  if (err instanceof AppError) {
    return c.json(errorEnvelope(err.code, err.message, c.get('requestId')), err.status);
  }
  const reqId = c.get('requestId');
  console.error(JSON.stringify({ level: 'error', requestId: reqId, message: err.message }));
  return c.json(errorEnvelope('INTERNAL', 'Unexpected error', reqId), 500);
});

app.route('/', healthRoute);
app.route('/', meRoute);

app.notFound((c) => c.json(errorEnvelope('NOT_FOUND', 'Route not found', c.get('requestId')), 404));

// OpenAPI document (contract source of truth for generated typed client)
app.doc('/openapi.json', {
  openapi: '3.0.0',
  info: {
    title: 'Family App API',
    version: '0.1.0',
    description: 'Family companion API contract v0.1',
  },
});

export default app;
