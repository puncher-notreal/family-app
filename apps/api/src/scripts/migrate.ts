import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import 'dotenv/config';
import { createDb } from '../db/client';

const MIGRATIONS_DIR = join(fileURLToPath(new URL('.', import.meta.url)), '..', 'supabase', 'migrations');

async function main() {
  const sql = createDb();

  await sql`CREATE TABLE IF NOT EXISTS schema_migrations (
    name TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
  )`;

  const applied = new Set<string>();
  const rows = await sql`SELECT name FROM schema_migrations`;
  for (const row of rows) applied.add(row.name);

  const files = (await readdir(MIGRATIONS_DIR)).filter((f) => f.endsWith('.sql')).sort();

  for (const file of files) {
    if (applied.has(file)) {
      console.log(`skip ${file} (already applied)`);
      continue;
    }
    const statement = await readFile(join(MIGRATIONS_DIR, file), 'utf8');
    await sql.begin(async (tx) => {
      await tx.unsafe(statement);
      await tx`INSERT INTO schema_migrations (name) VALUES (${file})`;
    });
    console.log(`applied ${file}`);
  }

  await sql.end();
  console.log('migrations done');
}

main().catch((err) => {
  console.error('migration failed:', err instanceof Error ? err.message : err);
  process.exit(1);
});
