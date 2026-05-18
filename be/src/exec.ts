import { runMigrations } from './database/run-migrations';
import { runSeeders } from './database/run-seeders';

/**
 * Runs CLI args (e.g. --migrate, --seed) and returns true if the app should exit without starting the server.
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

  return false;
}
