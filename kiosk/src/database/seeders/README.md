# Seeders

This directory contains database seeder files for populating initial data.

## Creating a Seeder

Create a new file following this structure:

```typescript
import { DataSource } from 'typeorm';
import { EntityName } from '@/path/to/entity';

export class SeederName {
  public async run(dataSource: DataSource): Promise<void> {
    const repository = dataSource.getRepository(EntityName);

    // Seeder logic here
    const entities = [
      // Your seed data
    ];

    await repository.save(entities);
  }
}
```

## Running Seeders

Seeders should be run manually or through a custom script. Example:

```typescript
import { DataSource } from 'typeorm';
import { typeOrmConfig } from '@/database/config/typeorm.config';
import { SeederName } from '@/database/seeders/SeederName';

async function runSeeders() {
  const dataSource = new DataSource(typeOrmConfig);
  await dataSource.initialize();

  const seeder = new SeederName();
  await seeder.run(dataSource);

  await dataSource.destroy();
}

runSeeders();
```
