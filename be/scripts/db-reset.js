'use strict';

require('dotenv').config();
const { Pool } = require('pg');
const { execSync } = require('child_process');

const pool = new Pool({
  host:     process.env.POSTGRES_HOST     || 'localhost',
  port:     parseInt(process.env.POSTGRES_PORT || '5432', 10),
  user:     process.env.POSTGRES_USER     || 'postgres',
  password: process.env.POSTGRES_PASSWORD || 'postgres',
  database: process.env.POSTGRES_DB       || 'pos_db',
});

// Tables that must NOT be wiped (schema tracking)
const PRESERVE = new Set(['migrations']);

async function reset() {
  const client = await pool.connect();
  try {
    const { rows } = await client.query(
      `SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename`,
    );

    const targets = rows
      .map((r) => r.tablename)
      .filter((t) => !PRESERVE.has(t));

    console.log(`Truncating ${targets.length} tables...`);
    await client.query('BEGIN');
    // Single statement — CASCADE handles FK order automatically
    await client.query(
      `TRUNCATE TABLE ${targets.map((t) => `"${t}"`).join(', ')} RESTART IDENTITY CASCADE`,
    );
    await client.query('COMMIT');
    console.log('All tables cleared and sequences reset.\n');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Reset failed:', err.message);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

reset()
  .then(() => {
    console.log('Running seeders...\n');
    execSync('npm run seed:run', { stdio: 'inherit', cwd: process.cwd() });
  })
  .catch(() => process.exit(1));
