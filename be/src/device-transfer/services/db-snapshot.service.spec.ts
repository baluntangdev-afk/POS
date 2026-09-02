import { DbSnapshotService } from './db-snapshot.service';
import type { TableSnapshot } from './db-snapshot.service';

interface InfoColumn {
  column_name: string;
  udt_name: string;
  is_nullable: 'YES' | 'NO';
  column_default: string | null;
  is_identity: 'YES' | 'NO';
  is_generated: string;
}

function col(
  name: string,
  udt: string,
  nullable: 'YES' | 'NO' = 'YES',
  columnDefault: string | null = null,
): InfoColumn {
  return {
    column_name: name,
    udt_name: udt,
    is_nullable: nullable,
    column_default: columnDefault,
    is_identity: 'NO',
    is_generated: 'NEVER',
  };
}

function setup(opts: { targetTables: string[]; targetColumns: Record<string, InfoColumn[]> }) {
  const ds = {
    query: jest.fn((sql: string) => {
      if (sql.includes('information_schema.tables')) {
        return Promise.resolve(opts.targetTables.map((t) => ({ table_name: t })));
      }
      return Promise.resolve([]);
    }),
  };

  const queries: { sql: string; params: unknown[] }[] = [];
  const qr = {
    query: jest.fn((sql: string, params?: unknown[]) => {
      queries.push({ sql, params: params ?? [] });
      if (/information_schema\.columns/.test(sql) && /table_name = \$1/.test(sql)) {
        const table = (params ?? [])[0] as string;
        return Promise.resolve(opts.targetColumns[table] ?? []);
      }
      return Promise.resolve([]);
    }),
  };

  const svc = new DbSnapshotService(ds as never);
  return {
    svc,
    qr: qr as never,
    queries,
    inserts: () => queries.filter((q) => /^\s*INSERT INTO/.test(q.sql)),
    truncate: () => queries.find((q) => /^\s*TRUNCATE/.test(q.sql)),
  };
}

function snap(name: string, columns: [string, string][], rows: unknown[][]): TableSnapshot {
  return { name, columns: columns.map(([n, udt]) => ({ name: n, udt })), rows };
}

describe('DbSnapshotService — partial restore', () => {
  it('skips an archive table that does not exist on the target', async () => {
    const t = setup({
      targetTables: ['users'],
      targetColumns: { users: [col('id', 'int4', 'NO', "nextval('users_id_seq')"), col('name', 'text')] },
    });

    const result = await t.svc.restore(
      {
        tables: [
          snap('users', [['id', 'int4'], ['name', 'text']], [[1, 'Ann']]),
          snap('ghost', [['x', 'text']], [['y']]),
        ],
      },
      t.qr,
      { partial: true },
    );

    expect(result.counts).toEqual({ users: 1 });
    expect(result.skipped.tables).toContainEqual({
      name: 'ghost',
      reason: 'not present on this device',
    });
  });

  it('drops an archive-only column and inserts the rest', async () => {
    const t = setup({
      targetTables: ['users'],
      targetColumns: { users: [col('id', 'int4', 'NO', "nextval('x')"), col('name', 'text')] },
    });

    const result = await t.svc.restore(
      {
        tables: [snap('users', [['id', 'int4'], ['name', 'text'], ['nickname', 'text']], [[1, 'Ann', 'A']])],
      },
      t.qr,
      { partial: true },
    );

    expect(result.skipped.columns).toContainEqual({
      table: 'users',
      column: 'nickname',
      reason: 'not present on this device',
    });
    const insert = t.inserts()[0];
    expect(insert.sql).toContain('("id", "name")');
    expect(insert.params).toEqual([1, 'Ann']);
  });

  it('drops a column whose type changed between devices', async () => {
    const t = setup({
      targetTables: ['products'],
      targetColumns: { products: [col('id', 'int4', 'NO', "nextval('x')"), col('image_url', 'text')] },
    });

    const result = await t.svc.restore(
      { tables: [snap('products', [['id', 'int4'], ['image_url', 'bytea']], [[1, { $b64: 'AA==' }]])] },
      t.qr,
      { partial: true },
    );

    expect(result.skipped.columns).toContainEqual({
      table: 'products',
      column: 'image_url',
      reason: 'type changed (bytea → text)',
    });
    expect(t.inserts()[0].sql).toContain('("id")');
  });

  it('skips the whole table when the target has a required column the backup lacks', async () => {
    const t = setup({
      targetTables: ['users'],
      targetColumns: {
        users: [col('id', 'int4', 'NO', "nextval('x')"), col('name', 'text'), col('email', 'text', 'NO')],
      },
    });

    const result = await t.svc.restore(
      { tables: [snap('users', [['id', 'int4'], ['name', 'text']], [[1, 'Ann']])] },
      t.qr,
      { partial: true },
    );

    expect(result.counts.users).toBeUndefined();
    expect(result.skipped.tables).toContainEqual({
      name: 'users',
      reason: 'backup is missing required column "email"',
    });
    expect(t.inserts()).toHaveLength(0);
  });

  it("keeps the device's own migrations table", async () => {
    const t = setup({
      targetTables: ['migrations', 'users'],
      targetColumns: {
        migrations: [col('id', 'int4', 'NO', "nextval('x')"), col('name', 'varchar')],
        users: [col('id', 'int4', 'NO', "nextval('x')")],
      },
    });

    const result = await t.svc.restore(
      {
        tables: [
          snap('migrations', [['id', 'int4'], ['name', 'varchar']], [[1, 'InitialMigration']]),
          snap('users', [['id', 'int4']], [[1]]),
        ],
      },
      t.qr,
      { partial: true },
    );

    expect(t.truncate()!.sql).toContain('"users"');
    expect(t.truncate()!.sql).not.toContain('"migrations"');
    expect(result.skipped.tables).toContainEqual({
      name: 'migrations',
      reason: "kept this device's own migration history",
    });
    expect(t.inserts().every((q) => !q.sql.includes('INTO "migrations"'))).toBe(true);
  });
});

describe('DbSnapshotService — strict restore', () => {
  it('throws when an archive table is missing on the target', async () => {
    const t = setup({ targetTables: ['users'], targetColumns: { users: [col('id', 'int4')] } });

    await expect(
      t.svc.restore({ tables: [snap('ghost', [['x', 'text']], [['y']])] }, t.qr),
    ).rejects.toThrow(/does not exist on this device/);
  });
});
