import postgres from 'postgres';
import { AppError } from '../common/errors.js';

export type Database = postgres.Sql;

export function getDatabaseUrl(): string {
  const url =
    process.env.DATABASE_URL ?? process.env.POSTGRES_PRISMA_URL ?? process.env.POSTGRES_URL;
  if (!url) {
    throw new AppError(
      'INTERNAL',
      500,
      'Missing database connection string (DATABASE_URL or Supabase integration POSTGRES_URL)',
    );
  }
  return url;
}

export function createDb(): Database {
  return postgres(getDatabaseUrl(), { onnotice: () => {} });
}
