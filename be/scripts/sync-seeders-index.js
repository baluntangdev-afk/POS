const fs = require('fs');
const path = require('path');

const SEEDERS_DIR = path.join(__dirname, '../src/database/seeders');
const INDEX_PATH = path.join(__dirname, '../src/database/seeders-index.ts');

const CLASS_REGEX = /export\s+class\s+(\w+Seeder)\s+implements\s+Seeder/;

/**
 * Scans seeder files (*.seeder.ts) and updates seeders-index.ts with imports and the seeders array.
 */
function syncSeedersIndex() {
  if (!fs.existsSync(SEEDERS_DIR)) {
    fs.mkdirSync(SEEDERS_DIR, { recursive: true });
  }
  const files = fs.readdirSync(SEEDERS_DIR);
  const seederFiles = files.filter((f) => f.endsWith('.seeder.ts')).sort();

  const entries = [];
  for (const file of seederFiles) {
    const content = fs.readFileSync(path.join(SEEDERS_DIR, file), 'utf8');
    const match = content.match(CLASS_REGEX);
    if (match) {
      const className = match[1];
      const importPath = './seeders/' + file.replace(/\.ts$/, '');
      entries.push({ className, importPath });
    }
  }

  const imports = entries
    .map((e) => `import { ${e.className} } from '${e.importPath}';`)
    .join('\n');
  const arrayEntries = entries.map((e) => `  ${e.className}`).join(',\n');

  const content = `import type { Seeder } from './seeders/seeder.interface';
${imports}

/**
 * Seeder classes for npm run seed:run and POSBackend.exe --seed.
 * Auto-synced by scripts/sync-seeders-index.js when creating seeders.
 */
export const seeders: Array<new () => Seeder> = [
${arrayEntries}
];
`;

  fs.writeFileSync(INDEX_PATH, content, 'utf8');
  console.log('Updated src/database/seeders-index.ts with', entries.length, 'seeder(s).');
}

syncSeedersIndex();
