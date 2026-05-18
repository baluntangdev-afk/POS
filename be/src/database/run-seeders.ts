import { DataSource } from 'typeorm';
import { typeOrmConfig } from './config/typeorm.config';
import { entities } from './entities-index';
import { seeders } from './seeders-index';

/**
 * Run all seeders (same as npm run seed:run).
 * Uses bundled seeder classes and explicit entities so it works in the SEA executable.
 */
export async function runSeeders(): Promise<void> {
  const dataSource = new DataSource({
    ...typeOrmConfig,
    entities,
    migrations: [],
  });
  await dataSource.initialize();
  try {
    if (seeders.length === 0) {
      console.log('No seeders registered.');
      return;
    }

    console.log(`Running ${seeders.length} seeder(s):`);

    for (const SeederClass of seeders) {
      const instance = new SeederClass();
      await instance.run(dataSource);
      console.log(`  - ${SeederClass.name}`);
    }
  } finally {
    await dataSource.destroy();
  }
}
