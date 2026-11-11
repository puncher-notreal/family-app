import { PGlite } from '@electric-sql/pglite';
import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

// Validates that every migration applies cleanly to a fresh in-process Postgres.
// This is a schema correctness gate; real integration runs against Supabase.
const MIGRATIONS_DIR = join(
  fileURLToPath(new URL('.', import.meta.url)),
  '..',
  'supabase',
  'migrations',
);

async function main() {
  const db = new PGlite();
  const files = (await readdir(MIGRATIONS_DIR)).filter((f) => f.endsWith('.sql')).sort();

  for (const file of files) {
    let statement = await readFile(join(MIGRATIONS_DIR, file), 'utf8');
    // pgcrypto ships with Supabase but not with PGlite; gen_random_uuid() is built-in since PG13.
    statement = statement.replace(/CREATE EXTENSION IF NOT EXISTS pgcrypto;\s*/i, '');
    await db.exec(statement);
    console.log(`ok ${file}`);
  }

  const tables = await db.query<{ table_name: string }>(
    `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name`,
  );
  console.log(`tables created: ${tables.rows.length}`);
  for (const row of tables.rows) {
    console.log(` - ${row.table_name}`);
  }

  await db.close();
  console.log('schema validation passed');
}

main().catch((err) => {
  console.error('schema validation failed:', err instanceof Error ? err.message : err);
  process.exit(1);
});
