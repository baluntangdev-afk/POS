# Seeders

Database seeders for initial or test data. They run via `npm run seed:run` or from the executable with `--seed`.

## Creating a seeder

Use the generator (creates the file and updates the index):

```bash
npm run seed:create <seeder-name>
```

Example:

```bash
npm run seed:create admin-user
```

This creates `src/database/seeders/admin-user.seeder.ts` with a class `AdminUserSeeder` that implements `Seeder`, and updates `src/database/seeders-index.ts`.

## Seeder contract

Each seeder must implement the `Seeder` interface:

```typescript
import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';

export class MySeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const repo = dataSource.getRepository(MyEntity);
    await repo.save([...]);
  }
}
```

- Class name must end with `Seeder` and the file must be `*.seeder.ts`.
- The index is auto-synced when you run `seed:create` or `seed:sync-index`.

## Running seeders

- **CLI:** `npm run seed:run`
- **Executable:** `POSBackend.exe --seed` (same list of seeders, bundled in the exe)

## Manual index sync

If you add or rename a seeder file by hand, run:

```bash
npm run seed:sync-index
```
