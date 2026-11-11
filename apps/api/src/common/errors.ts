import type { ContentfulStatusCode } from 'hono/utils/http-status';

export const ERROR_CODES = [
  'VALIDATION_ERROR',
  'UNAUTHENTICATED',
  'FORBIDDEN',
  'NOT_FOUND',
  'CONFLICT',
  'EXPIRED',
  'INVALID_STATE',
  'RATE_LIMITED',
  'INTERNAL',
] as const;

export type ErrorCode = (typeof ERROR_CODES)[number];

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly status: ContentfulStatusCode;

  constructor(code: ErrorCode, status: ContentfulStatusCode, message: string) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

export const badRequest = (message: string) => new AppError('VALIDATION_ERROR', 400, message);
export const unauthorized = (message: string) => new AppError('UNAUTHENTICATED', 401, message);
export const forbidden = (message: string) => new AppError('FORBIDDEN', 403, message);
export const notFound = (message: string) => new AppError('NOT_FOUND', 404, message);

export function errorEnvelope(code: string, message: string, requestId?: string) {
  return { error: { code, message, requestId } };
}
