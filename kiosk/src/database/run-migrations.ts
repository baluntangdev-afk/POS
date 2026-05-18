import { DataSource } from 'typeorm';
import { typeOrmConfig } from './config/typeorm.config';
import { migrations } from './migrations';

/**
 * Run pending migrations (same as npm run migration:up).
 * Reuses typeOrmConfig; uses bundled migration classes so it works in the exe.
 */
export async function runMigrations(): Promise<void> {
  const dataSource = new DataSource({
    ...typeOrmConfig,
    migrations,
  });
  await dataSource.initialize();
  try {
    const executed = await dataSource.runMigrations();
    if (executed.length > 0) {
      console.log(`Ran ${executed.length} migration(s):`);
      executed.forEach((m) => console.log(`  - ${m.name}`));
    } else {
      console.log('No pending migrations.');
    }
  } finally {
    await dataSource.destroy();
  }
}
