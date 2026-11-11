import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';

const MeResponse = z
  .object({
    data: z.object({
      userType: z.enum(['adult', 'child']).nullable(),
      families: z.array(z.string().uuid()),
      childId: z.string().uuid().nullable(),
    }),
  })
  .openapi('MeResponse');

const errorResponse = z
  .object({
    error: z.object({
      code: z.string(),
      message: z.string(),
      requestId: z.string().optional(),
    }),
  })
  .openapi('ErrorResponse');

const meRouteSpec = createRoute({
  method: 'get',
  path: '/v1/me',
  responses: {
    200: { content: { 'application/json': { schema: MeResponse } }, description: 'Current actor' },
    401: {
      content: { 'application/json': { schema: errorResponse } },
      description: 'Unauthenticated',
    },
  },
});

export const meRoute = new OpenAPIHono();

meRoute.openapi(meRouteSpec, (c) => {
  // Phase 2 replaces this stub with real session resolution (adult JWT / child device session).
  const auth = c.req.header('Authorization');
  if (!auth) {
    return c.json(
      { error: { code: 'UNAUTHENTICATED', message: 'Missing bearer token', requestId: c.get('requestId') } },
      401,
    );
  }
  return c.json(
    { data: { userType: null, families: [], childId: null } },
    200 as const,
  );
});
