import { runMigrations } from './database/run-migrations';

/**
 * Runs CLI args (e.g. --migrate) and returns true if the app should exit without starting the server.
 */
export async function runExecArgs(): Promise<boolean> {
  if (process.argv.includes('--migrate')) {
    await runMigrations();
    return true;
  }
  return false;
}
