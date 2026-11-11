import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';

const HealthResponse = z
  .object({
    data: z.object({
      status: z.literal('ok'),
      version: z.string(),
    }),
  })
  .openapi('HealthResponse');

const healthRouteSpec = createRoute({
  method: 'get',
  path: '/health',
  responses: {
    200: {
      content: { 'application/json': { schema: HealthResponse } },
      description: 'API is healthy',
    },
  },
});

export const healthRoute = new OpenAPIHono();

healthRoute.openapi(healthRouteSpec, (c) =>
  c.json({ data: { status: 'ok' as const, version: '0.1.0' } }),
);
