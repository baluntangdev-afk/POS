import { runMigrations } from './database/run-migrations';
import { runSeeders } from './database/run-seeders';
import { runCsvSeeders } from './database/seeders/csv/run-csv-seeders';

/**
 * Runs CLI args (e.g. --migrate, --seed, --seed-csv) and returns true if the app should exit without starting the server.
 */
export async function runExecArgs(): Promise<boolean> {
  if (process.argv.includes('--migrate')) {
    await runMigrations();
    return true;
  }

  if (process.argv.includes('--seed')) {
    await runSeeders();
    return true;
  }

  if (process.argv.includes('--seed-csv')) {
    const idx = process.argv.indexOf('--seed-csv');
    const csvDir = process.argv[idx + 1];
    if (!csvDir) {
      throw new Error('--seed-csv requires a directory path argument');
    }
    await runCsvSeeders(csvDir);
    return true;
  }

  return false;
}
