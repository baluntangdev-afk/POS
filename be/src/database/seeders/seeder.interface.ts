import type { DataSource } from 'typeorm';

/**
 * Contract for database seeders. Implement this interface so seeders can be
 * discovered and run by run-seeders (npm run seed:run and executable --seed).
 */
export interface Seeder {
  run(dataSource: DataSource): Promise<void>;
}
