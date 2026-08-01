import { runSeeders } from './run-seeders';

runSeeders()
  .then(() => process.exit(0))
  .catch((err: unknown) => {
    // Per-seeder failures were already logged with their names above. Print only
    // the concise aggregate message here — never the raw error object, which
    // dumps the full TypeORM query/parameters/stack.
    console.error(err instanceof Error ? err.message : String(err));
    process.exit(1);
  });
