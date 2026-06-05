import { DataSource } from 'typeorm';
import { typeOrmConfig } from './config/typeorm.config';
import { entities } from './entities-index';
import { seeders } from './seeders-index';

/**
 * Concise one-line description of a seeder error.
 *
 * Without this, a single failing seeder dumped the entire TypeORM error object
 * (the full SQL query, every bound parameter, the nested `driverError`, and a
 * minified SEA stack) — ~900KB of unreadable noise that hid which seeder broke.
 * We surface just the human-readable message plus the Postgres `detail`/`hint`
 * when present.
 */
function describeError(err: unknown): string {
  if (err instanceof Error) {
    const driver = (err as { driverError?: { detail?: string; hint?: string } }).driverError;
    const extra = driver?.detail ? ` (${driver.detail})` : '';
    return `${err.message}${extra}`;
  }
  return String(err);
}

/**
 * Run all seeders (same as npm run seed:run).
 * Uses bundled seeder classes and explicit entities so it works in the SEA executable.
 *
 * Each seeder is isolated: one failure is logged with its name and a concise
 * message, then the runner continues so a single bad seeder (e.g. a schema gap)
 * doesn't hide the state of the rest. Seeders are idempotent, so continuing is
 * safe. If any failed, the function throws a single aggregated, concise error so
 * callers (CLI / installer) still see a non-zero exit.
 */
export async function runSeeders(): Promise<void> {
  const dataSource = new DataSource({
    ...typeOrmConfig,
    entities,
    migrations: [],
  });
  await dataSource.initialize();

  const failures: Array<{ name: string; error: string }> = [];
  try {
    if (seeders.length === 0) {
      console.log('No seeders registered.');
      return;
    }

    console.log(`Running ${seeders.length} seeder(s):`);

    for (const SeederClass of seeders) {
      try {
        const instance = new SeederClass();
        await instance.run(dataSource);
        console.log(`  ✓ ${SeederClass.name}`);
      } catch (err) {
        const message = describeError(err);
        failures.push({ name: SeederClass.name, error: message });
        console.error(`  ✗ ${SeederClass.name} failed: ${message}`);
      }
    }
  } finally {
    await dataSource.destroy();
  }

  if (failures.length > 0) {
    const summary = failures.map((f) => `  - ${f.name}: ${f.error}`).join('\n');
    throw new Error(`${failures.length} of ${seeders.length} seeder(s) failed:\n${summary}`);
  }

  console.log(`All ${seeders.length} seeder(s) completed.`);
}
