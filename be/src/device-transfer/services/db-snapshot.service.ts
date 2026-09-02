import { Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, QueryRunner } from 'typeorm';

export interface ColumnMeta {
  name: string;
  /** Postgres `udt_name` (e.g. `int4`, `bytea`, `jsonb`, `_text`, `timestamptz`). */
  udt: string;
}

export interface TableSnapshot {
  name: string;
  columns: ColumnMeta[];
  /** One entry per row; each entry is an array of values aligned to `columns`. */
  rows: unknown[][];
}

export interface RestorePayload {
  tables: TableSnapshot[];
}

export interface RestoreOptions {
  /**
   * Best-effort mode: import only the tables and columns this device shares
   * with the archive, recording the rest in {@link RestoreResult.skipped}
   * instead of throwing. The device's own `migrations` table is left intact.
   */
  partial?: boolean;
}

export interface RestoreSkipped {
  tables: { name: string; reason: string }[];
  columns: { table: string; column: string; reason: string }[];
}

export interface RestoreResult {
  /** Rows restored per table. */
  counts: Record<string, number>;
  skipped: RestoreSkipped;
}

interface TargetColumn {
  name: string;
  udt: string;
  /** Nullable, or has a default, or identity, or generated — safe to omit. */
  omittable: boolean;
}

const BYTEA = 'bytea';
const JSON_UDTS = new Set(['json', 'jsonb']);

interface B64Value {
  $b64: string;
}

function isB64Value(v: unknown): v is B64Value {
  return (
    typeof v === 'object' && v !== null && typeof (v as Record<string, unknown>).$b64 === 'string'
  );
}

/**
 * Reads and restores the entire `public` schema via raw SQL on the shared
 * TypeORM connection. Every base table is included — `migrations` on purpose, so
 * a strict restore can only land on a device with an identical migration
 * history. A partial restore (see {@link RestoreOptions}) relaxes that: it keeps
 * the device's own `migrations` table and imports only what lines up.
 */
@Injectable()
export class DbSnapshotService {
  constructor(@InjectDataSource() private readonly ds: DataSource) {}

  async listTables(): Promise<string[]> {
    const rows = await this.ds.query<{ table_name: string }[]>(
      `SELECT table_name FROM information_schema.tables
       WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
       ORDER BY table_name`,
    );
    return rows.map((r) => r.table_name);
  }

  async columnsOf(table: string): Promise<ColumnMeta[]> {
    const rows = await this.ds.query<{ column_name: string; udt_name: string }[]>(
      `SELECT column_name, udt_name FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = $1
       ORDER BY ordinal_position`,
      [table],
    );
    return rows.map((r) => ({ name: r.column_name, udt: r.udt_name }));
  }

  async readTable(table: string): Promise<TableSnapshot> {
    const columns = await this.columnsOf(table);
    const raw = await this.ds.query<Record<string, unknown>[]>(`SELECT * FROM "${table}"`);
    const rows = raw.map((record) =>
      columns.map((col) => this.encodeValue(record[col.name], col.udt)),
    );
    return { name: table, columns, rows };
  }

  async getMigrations(): Promise<string[]> {
    const rows = await this.ds.query<{ name: string }[]>(
      `SELECT name FROM migrations ORDER BY id ASC`,
    );
    return rows.map((r) => r.name);
  }

  private encodeValue(value: unknown, udt: string): unknown {
    if (value === null || value === undefined) return null;
    if (udt === BYTEA && Buffer.isBuffer(value)) {
      return { $b64: value.toString('base64') };
    }
    return value;
  }

  private decodeValue(value: unknown, udt: string): unknown {
    if (value === null || value === undefined) return null;
    if (isB64Value(value)) return Buffer.from(value.$b64, 'base64');
    // node-pg turns a JS array/object into a Postgres array literal, which is
    // wrong for json/jsonb columns — hand it a JSON string instead.
    if (JSON_UDTS.has(udt) && typeof value === 'object') {
      return JSON.stringify(value);
    }
    return value;
  }

  /**
   * Full-replace restore. MUST run inside an already-open transaction on `qr`.
   * Returns row counts per restored table and (in partial mode) what was left
   * behind.
   */
  async restore(
    payload: RestorePayload,
    qr: QueryRunner,
    opts: RestoreOptions = {},
  ): Promise<RestoreResult> {
    const partial = opts.partial ?? false;
    const targetTables = await this.listTables();
    const targetSet = new Set(targetTables);
    const skipped: RestoreSkipped = { tables: [], columns: [] };

    if (!partial) {
      for (const table of payload.tables) {
        if (!targetSet.has(table.name)) {
          throw new Error(
            `Archive table "${table.name}" does not exist on this device (schema mismatch).`,
          );
        }
      }
    }

    // Superuser-only. Disables FK checks + user triggers for this transaction so
    // tables can be truncated and reloaded in any order.
    await qr.query(`SET LOCAL session_replication_role = 'replica'`);

    // Partial mode keeps this device's own migration history — the archive's
    // schema is a different version, and overwriting `migrations` would make the
    // DB misreport which migrations actually ran against it.
    const truncatable = partial
      ? targetTables.filter((t) => t !== 'migrations')
      : targetTables;
    await qr.query(
      `TRUNCATE ${truncatable.map((t) => `"${t}"`).join(', ')} RESTART IDENTITY CASCADE`,
    );

    const counts: Record<string, number> = {};
    for (const table of payload.tables) {
      if (partial && table.name === 'migrations') {
        skipped.tables.push({
          name: 'migrations',
          reason: "kept this device's own migration history",
        });
        continue;
      }
      if (!targetSet.has(table.name)) {
        skipped.tables.push({ name: table.name, reason: 'not present on this device' });
        continue;
      }
      if (partial) {
        const columnIndices = await this.planPartialInsert(table, qr, skipped);
        if (columnIndices === null) continue; // whole table skipped (reason recorded)
        counts[table.name] = await this.insertRows(table, qr, columnIndices);
      } else {
        counts[table.name] = await this.insertRows(table, qr);
      }
    }

    await this.resetSequences(qr);
    return { counts, skipped };
  }

  /** `information_schema` columns of a live target table, with omittability. */
  private async targetColumns(table: string, qr: QueryRunner): Promise<TargetColumn[]> {
    const rows = (await qr.query(
      `SELECT column_name, udt_name, is_nullable, column_default, is_identity, is_generated
       FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = $1
       ORDER BY ordinal_position`,
      [table],
    )) as {
      column_name: string;
      udt_name: string;
      is_nullable: 'YES' | 'NO';
      column_default: string | null;
      is_identity: 'YES' | 'NO';
      is_generated: string;
    }[];
    return rows.map((r) => ({
      name: r.column_name,
      udt: r.udt_name,
      omittable:
        r.is_nullable === 'YES' ||
        r.column_default !== null ||
        r.is_identity === 'YES' ||
        r.is_generated !== 'NEVER',
    }));
  }

  /**
   * Works out which of an archive table's columns can be inserted into the live
   * target table. Returns the archive column indices to keep, or `null` when the
   * whole table has to be skipped (reason pushed onto `skipped`).
   */
  private async planPartialInsert(
    table: TableSnapshot,
    qr: QueryRunner,
    skipped: RestoreSkipped,
  ): Promise<number[] | null> {
    const targetByName = new Map(
      (await this.targetColumns(table.name, qr)).map((c) => [c.name, c]),
    );
    const archiveNames = new Set(table.columns.map((c) => c.name));

    const missingRequired = [...targetByName.values()].filter(
      (c) => !c.omittable && !archiveNames.has(c.name),
    );
    if (missingRequired.length > 0) {
      const cols = missingRequired.map((c) => `"${c.name}"`).join(', ');
      skipped.tables.push({
        name: table.name,
        reason: `backup is missing required column${missingRequired.length > 1 ? 's' : ''} ${cols}`,
      });
      return null;
    }

    const indices: number[] = [];
    table.columns.forEach((archiveCol, index) => {
      const target = targetByName.get(archiveCol.name);
      if (!target) {
        skipped.columns.push({
          table: table.name,
          column: archiveCol.name,
          reason: 'not present on this device',
        });
        return;
      }
      if (target.udt !== archiveCol.udt) {
        skipped.columns.push({
          table: table.name,
          column: archiveCol.name,
          reason: `type changed (${archiveCol.udt} → ${target.udt})`,
        });
        return;
      }
      indices.push(index);
    });

    if (indices.length === 0) {
      skipped.tables.push({ name: table.name, reason: 'no compatible columns' });
      return null;
    }
    return indices;
  }

  /**
   * Inserts an archive table's rows. `columnIndices` selects which of
   * `table.columns` to write (defaults to all of them) — partial restore passes
   * a subset.
   */
  private async insertRows(
    table: TableSnapshot,
    qr: QueryRunner,
    columnIndices?: number[],
  ): Promise<number> {
    if (table.rows.length === 0) return 0;

    const indices = columnIndices ?? table.columns.map((_, i) => i);
    if (indices.length === 0) return 0;

    const colList = indices.map((i) => `"${table.columns[i].name}"`).join(', ');
    const BATCH = 500;
    let inserted = 0;

    for (let i = 0; i < table.rows.length; i += BATCH) {
      const slice = table.rows.slice(i, i + BATCH);
      const params: unknown[] = [];
      const tuples = slice.map((row) => {
        const placeholders = indices.map((colIndex) => {
          params.push(this.decodeValue(row[colIndex], table.columns[colIndex].udt));
          return `$${params.length}`;
        });
        return `(${placeholders.join(', ')})`;
      });
      await qr.query(
        `INSERT INTO "${table.name}" (${colList}) VALUES ${tuples.join(', ')}`,
        params,
      );
      inserted += slice.length;
    }
    return inserted;
  }

  /**
   * Re-point every sequence referenced by a column default at MAX(column) + 1.
   * Parsing `column_default` catches both SERIAL/IDENTITY sequences and
   * standalone ones like `z_readings_z_counter_seq`.
   */
  private async resetSequences(qr: QueryRunner): Promise<void> {
    const cols = (await qr.query(
      `SELECT table_name, column_name, column_default FROM information_schema.columns
       WHERE table_schema = 'public' AND column_default LIKE 'nextval(%'`,
    )) as { table_name: string; column_name: string; column_default: string }[];

    for (const col of cols) {
      const match = /nextval\('"?([^'"]+)"?'::regclass\)/.exec(col.column_default);
      if (!match) continue;
      const sequence = match[1];
      await qr.query(
        `SELECT setval(
           '"${sequence}"',
           GREATEST((SELECT COALESCE(MAX("${col.column_name}"), 0) FROM "${col.table_name}"), 1),
           (SELECT COUNT(*) FROM "${col.table_name}") > 0
         )`,
      );
    }
  }
}
