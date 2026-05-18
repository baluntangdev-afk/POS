const { execSync } = require('child_process');
const path = require('path');

const migrationName = process.argv[2];

if (!migrationName) {
  console.error('Error: Migration name is required');
  console.log('Usage: npm run migration:create <migration-name>');
  console.log('Example: npm run migration:create create-example-table');
  process.exit(1);
}

const migrationPath = path.join(__dirname, '../src/database/migrations', migrationName);

const command = `npx typeorm-ts-node-commonjs migration:create ${migrationPath}`;

try {
  execSync(command, { stdio: 'inherit' });
  require('./sync-migrations-index.js');
  execSync('npm run format', { stdio: 'inherit' });
} catch (error) {
  process.exit(1);
}
