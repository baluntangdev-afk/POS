const fs = require('fs');
const path = require('path');

const MIGRATIONS_DIR = path.join(__dirname, '../src/database/migrations');
const INDEX_PATH = path.join(__dirname, '../src/database/migrations-index.ts');

const CLASS_REGEX = /export\s+class\s+(\w+)\s+implements\s+MigrationInterface/;

/**
 * Scans migration files and updates migrations/index.ts with imports and the migrations array.
 */
function syncMigrationsIndex() {
  const files = fs.readdirSync(MIGRATIONS_DIR);
  const migrationFiles = files.filter((f) => f.endsWith('.ts') && /^\d+-/.test(f)).sort();

  const entries = [];
  for (const file of migrationFiles) {
    const content = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8');
    const match = content.match(CLASS_REGEX);
    if (match) {
      const className = match[1];
      const importPath = './migrations/' + file.replace(/\.ts$/, '');
      entries.push({ className, importPath });
    }
  }

  const imports = entries
    .map((e) => `import { ${e.className} } from '${e.importPath}';`)
    .join('\n');
  const arrayEntries = entries.map((e) => `  ${e.className}`).join(',\n');

  const content = `import type { MigrationInterface } from 'typeorm';
${imports}

/**
 * Migration classes for POSBackend.exe --migrate (same as npm run migration:up).
 * Auto-synced by scripts/sync-migrations-index.js when creating or generating migrations.
 */
export const migrations: Array<new () => MigrationInterface> = [
${arrayEntries}
];
`;

  fs.writeFileSync(INDEX_PATH, content, 'utf8');
  console.log('Updated src/database/migrations-index.ts with', entries.length, 'migration(s).');
}

syncMigrationsIndex();
