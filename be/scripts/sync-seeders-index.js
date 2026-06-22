const fs = require('fs');
const path = require('path');

const SEEDERS_DIR = path.join(__dirname, '../src/database/seeders');
const INDEX_PATH = path.join(__dirname, '../src/database/seeders-index.ts');

const CLASS_REGEX = /export\s+class\s+(\w+Seeder)\s+implements\s+Seeder/;

/**
 * Seeders run in array order (see run-seeders.ts) and many depend on rows
 * created by earlier seeders, so they CANNOT be sorted alphabetically —
 * e.g. DiscountsSeeder needs the admin user from UsersSeeder, ProductVariants
 * needs Products, RecipeItems needs Recipes + Materials. This explicit
 * dependency order is the source of truth. Any seeder not listed here is
 * appended at the end (alphabetically) with a warning so it can be placed.
 *
 * NOTE: The product catalog (product groups/categories, products, variants) is
 * NOT seeded here — it is imported from the store's CSV at install time via
 * `POSBackend.exe --seed-csv` (see src/database/seeders/csv). The downstream
 * seeders below that reference the catalog (recipes, menu items, modifier links)
 * remain but no-op gracefully when the catalog is empty.
 */
const SEEDER_ORDER = [
  'UsersSeeder', // creates the admin user — must run first
  'CurrenciesSeeder',
  'DiscountsSeeder', // needs admin user
  'TaxCategoriesSeeder',
  'UomSeeder',
  'MaterialTypesSeeder',
  'InventoryTypesSeeder',
  'StoreMenusSeeder',
  'ModifierGroupsSeeder',
  'MaterialsSeeder', // needs UomSeeder + MaterialTypesSeeder
  'ModifierOptionsSeeder', // needs ModifierGroupsSeeder
  'ProductGroupModifierGroupsSeeder', // needs ModifierGroupsSeeder (links to CSV-seeded product groups by name)
  'ProductModifierGroupsSeeder', // needs ModifierGroupsSeeder (links to CSV-seeded products by name)
  'RecipesSeeder', // operates on CSV-seeded variants; no-ops when catalog empty
  'RecipeItemsSeeder', // needs RecipesSeeder + MaterialsSeeder
  'MenuItemsSeeder', // needs StoreMenusSeeder; operates on CSV-seeded variants
  'InventoryStocksSeeder', // seeds stock per material
  'MenuItemModifiersSeeder', // needs MenuItemsSeeder + ModifierOptionsSeeder
];

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

  // Order by the explicit dependency list. Unlisted seeders go last
  // (alphabetically) so a newly created one is never silently dropped —
  // warn so the developer slots it into SEEDER_ORDER.
  const rank = (name) => {
    const i = SEEDER_ORDER.indexOf(name);
    return i === -1 ? SEEDER_ORDER.length : i;
  };
  const unlisted = entries.filter((e) => SEEDER_ORDER.indexOf(e.className) === -1);
  if (unlisted.length > 0) {
    console.warn(
      'WARNING: these seeders are not in SEEDER_ORDER and were appended at the end — ' +
        'add them to scripts/sync-seeders-index.js in dependency order: ' +
        unlisted.map((e) => e.className).join(', '),
    );
  }
  entries.sort((a, b) => rank(a.className) - rank(b.className) || a.className.localeCompare(b.className));

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
