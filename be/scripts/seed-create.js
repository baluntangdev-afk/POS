const fs = require('fs');
const path = require('path');

const seederName = process.argv[2];

if (!seederName) {
  console.error('Error: Seeder name is required');
  console.log('Usage: npm run seed:create <seeder-name>');
  console.log('Example: npm run seed:create admin-user');
  process.exit(1);
}

const kebab = seederName
  .replace(/\s+/g, '-')
  .replace(/[^a-z0-9-]/gi, '')
  .toLowerCase();
const pascal = kebab
  .split('-')
  .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
  .join('');
const className = pascal + 'Seeder';
const fileName = kebab + '.seeder.ts';

const SEEDERS_DIR = path.join(__dirname, '../src/database/seeders');
const filePath = path.join(SEEDERS_DIR, fileName);

if (fs.existsSync(filePath)) {
  console.error(`Error: Seeder file already exists: ${fileName}`);
  process.exit(1);
}

if (!fs.existsSync(SEEDERS_DIR)) {
  fs.mkdirSync(SEEDERS_DIR, { recursive: true });
}

const template = `import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';

/**
 * Seeder: ${className}
 */
export class ${className} implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    // Add seeding logic here, e.g.:
    // const repo = dataSource.getRepository(Entity);
    // await repo.save([...]);
  }
}
`;

fs.writeFileSync(filePath, template, 'utf8');
console.log('Created', filePath);

require('./sync-seeders-index.js');
const { execSync } = require('child_process');
execSync('npm run format', { stdio: 'inherit' });
