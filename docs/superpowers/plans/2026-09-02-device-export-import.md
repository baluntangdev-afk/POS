# Device Export / Import (Full Migration) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an Admin/Supervisor export the entire kiosk backend database as one encrypted file and restore it verbatim onto another kiosk device (device migration).

**Architecture:** A new backend `device-transfer` NestJS module dumps every `public` base table via the existing TypeORM `DataSource` into a gzipped JSON document, then AES-256-GCM-encrypts it with a scrypt key derived from an operator passphrase. Import decrypts, checks the migration list matches, then in one transaction disables FK triggers (`session_replication_role = replica`), truncates every table, bulk-inserts the archive rows preserving primary keys, and resets all sequences. A new kiosk `device_transfer` Flutter feature drives both flows from the admin menu with passphrase + supervisor-PIN + type-to-confirm gates.

**Tech Stack:** NestJS 11, TypeORM 0.3 (Postgres), Node `crypto`/`zlib` (no new backend deps), Flutter, Riverpod, `file_picker`, Dio.

---

## Format of the archive file (`.posbackup`)

Binary layout (single file, no zip lib needed):

```
magic   "POSKBK01"            8 bytes ASCII
salt                          16 bytes  (scrypt)
iv                            12 bytes  (AES-GCM nonce)
authTag                       16 bytes  (AES-GCM tag)
ciphertext                    rest      = AES-256-GCM( gzip( JSON payload ) )
```

JSON payload (before gzip):

```jsonc
{
  "manifest": {
    "formatVersion": 1,
    "createdAt": "2026-09-02T12:00:00.000Z",
    "backendPackageVersion": "0.0.1",
    "database": "pos_db",
    "sourceKioskNo": "1",
    "migrations": ["TestInit1770175003018", "..."],   // SELECT name FROM migrations ORDER BY id
    "tableRowCounts": { "users": 4, "sales_orders": 120, "...": 0 }
  },
  "tables": [
    {
      "name": "users",
      "columns": [ { "name": "id", "udt": "int4" }, { "name": "image", "udt": "bytea" } ],
      "rows": [ [1, {"$b64":"..."}], [2, null] ]        // row = array aligned to columns[]
    }
  ]
}
```

Value encoding rules (applied per column `udt`):
- `bytea` -> `{ "$b64": "<base64>" }`, `null` stays `null`
- everything else -> native JSON. `pg` returns `Date` for timestamps (JSON serialises to ISO string), `string` for `numeric`/`bigint`, arrays for `text[]`, parsed object/array for `jsonb`.

Decode rules on import (per target column `udt`):
- `{ "$b64": x }` -> `Buffer.from(x, 'base64')`
- `jsonb`/`json` + value is array or object -> `JSON.stringify(value)` (pg sends the string, Postgres casts)
- otherwise pass the value as-is (ISO strings insert fine into `timestamptz`, numeric strings into `numeric`)

---

## File Structure

### Backend — all under `be/src/device-transfer/`

| File | Responsibility |
|---|---|
| `device-transfer.module.ts` | Wires controller + services, imports `TypeOrmModule` (for `DataSource`) |
| `device-transfer.controller.ts` | `POST export`, `POST import` (multipart). Guarded by `AdminOrSupervisorGuard` |
| `device-transfer.constants.ts` | `ARCHIVE_MAGIC`, `ARCHIVE_FORMAT_VERSION`, `SCRYPT_*`, min passphrase length |
| `services/archive-crypto.service.ts` | `encrypt(plain: Buffer, passphrase): Buffer`, `decrypt(file: Buffer, passphrase): Buffer` (+ gzip/gunzip) |
| `services/db-snapshot.service.ts` | `listTables()`, `readTable(name)`, `getMigrations()`, `restore(payload, queryRunner)` — all raw SQL via `DataSource` |
| `services/device-export.service.ts` | Builds payload -> gzip -> encrypt. Returns `{ buffer, manifest }` |
| `services/device-import.service.ts` | decrypt -> parse -> compatibility gate -> transactional restore -> summary |
| `dto/export-device.dto.ts` | `{ passphrase: string }` (min length) |
| `dto/import-device.dto.ts` | `{ passphrase: string; confirmReplace: 'true' }` (multipart strings) |
| `dto/device-transfer-result.dto.ts` | `ImportSummaryDto`, `ManifestDto`, `CompatibilityErrorDto` shapes for Swagger + kiosk parity |
| `device-transfer.controller.spec.ts` / `services/*.spec.ts` | unit tests (crypto round-trip, encode/decode, compatibility gate) |

Modified: `be/src/app.module.ts` (register `DeviceTransferModule`), `CLAUDE.md` (module list + schema notes).

### Kiosk — under `kiosk/lib/`

| File | Responsibility |
|---|---|
| `data/backend_api/sources/device_transfer_api.dart` | `DeviceTransferApi`: `export()` -> `Uint8List`, `import()` multipart -> `ImportSummaryDto` |
| `data/backend_api/schemas/device_transfer_manifest_dto.dart` | `@MappableClass` manifest |
| `data/backend_api/schemas/device_import_summary_dto.dart` | `@MappableClass` import summary |
| `features/device_transfer/repositories/device_transfer_repository.dart` | interface + impl over the API source |
| `features/device_transfer/state/device_transfer_notifier.dart` | `Mutation`s: `exportAction`, `importAction` |
| `features/device_transfer/view/device_transfer_screen.dart` | Hub screen: Export card + Import card |
| `features/device_transfer/view/export_backup_dialog.dart` | passphrase + confirm + supervisor auth -> save file |
| `features/device_transfer/view/import_backup_dialog.dart` | pick file + passphrase + supervisor auth + type `REPLACE` |
| `navigation/device_transfer_route.dart` | `DeviceTransferRoute` (`/device-transfer`) `part` file |

Modified: `kiosk/lib/features/menu/enums/menu_type.dart` (+`backupTransfer`), `kiosk/lib/features/menu/view/menu_grid.dart` (tile + admin/supervisor gate + nav), `kiosk/lib/navigation/router.dart` (import screen + `part`), `kiosk/CLAUDE.md` (feature list).

New doc: `docs/runbooks/kiosk-device-migration.md`.

---

## Task 1: Backend — archive crypto service

**Files:**
- Create: `be/src/device-transfer/device-transfer.constants.ts`
- Create: `be/src/device-transfer/services/archive-crypto.service.ts`
- Test: `be/src/device-transfer/services/archive-crypto.service.spec.ts`

- [ ] **Step 1 — constants**

```ts
// be/src/device-transfer/device-transfer.constants.ts
export const ARCHIVE_MAGIC = Buffer.from('POSKBK01', 'ascii'); // 8 bytes
export const ARCHIVE_FORMAT_VERSION = 1;
export const MIN_PASSPHRASE_LENGTH = 12;
export const SCRYPT_SALT_BYTES = 16;
export const SCRYPT_KEYLEN = 32;
export const SCRYPT_COST = 16384; // N (2^14)
export const GCM_IV_BYTES = 12;
export const GCM_TAG_BYTES = 16;
```

- [ ] **Step 2 — failing test**

```ts
// archive-crypto.service.spec.ts
import { ArchiveCryptoService } from './archive-crypto.service';

describe('ArchiveCryptoService', () => {
  const svc = new ArchiveCryptoService();
  const pass = 'correct horse battery';

  it('round-trips a payload', async () => {
    const plain = Buffer.from(JSON.stringify({ hello: 'world', n: 42 }));
    const file = await svc.encrypt(plain, pass);
    expect(file.subarray(0, 8).toString('ascii')).toBe('POSKBK01');
    const out = await svc.decrypt(file, pass);
    expect(out.toString()).toBe(plain.toString());
  });

  it('rejects a wrong passphrase', async () => {
    const file = await svc.encrypt(Buffer.from('x'), pass);
    await expect(svc.decrypt(file, 'wrong pass phrase!!')).rejects.toThrow(/passphrase|corrupt/i);
  });

  it('rejects a bad magic header', async () => {
    await expect(svc.decrypt(Buffer.alloc(60), pass)).rejects.toThrow(/not a valid/i);
  });
});
```

Run: `cd be && npx jest --testPathPattern=device-transfer/services/archive-crypto -c package.json`
Expected: FAIL (module not found).

- [ ] **Step 3 — implement**

```ts
// be/src/device-transfer/services/archive-crypto.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { promisify } from 'node:util';
import {
  randomBytes,
  scrypt as scryptCb,
  createCipheriv,
  createDecipheriv,
} from 'node:crypto';
import { gzip as gzipCb, gunzip as gunzipCb } from 'node:zlib';
import {
  ARCHIVE_MAGIC,
  GCM_IV_BYTES,
  GCM_TAG_BYTES,
  SCRYPT_COST,
  SCRYPT_KEYLEN,
  SCRYPT_SALT_BYTES,
} from '../device-transfer.constants';

const scrypt = promisify(scryptCb) as (p: string | Buffer, s: Buffer, k: number, o: { N: number }) => Promise<Buffer>;
const gzip = promisify(gzipCb);
const gunzip = promisify(gunzipCb);

@Injectable()
export class ArchiveCryptoService {
  /** gzip(plain) then AES-256-GCM. Layout: magic|salt|iv|tag|ciphertext. */
  async encrypt(plain: Buffer, passphrase: string): Promise<Buffer> {
    const compressed = await gzip(plain);
    const salt = randomBytes(SCRYPT_SALT_BYTES);
    const key = await scrypt(passphrase, salt, SCRYPT_KEYLEN, { N: SCRYPT_COST });
    const iv = randomBytes(GCM_IV_BYTES);
    const cipher = createCipheriv('aes-256-gcm', key, iv);
    const ciphertext = Buffer.concat([cipher.update(compressed), cipher.final()]);
    const tag = cipher.getAuthTag();
    return Buffer.concat([ARCHIVE_MAGIC, salt, iv, tag, ciphertext]);
  }

  async decrypt(file: Buffer, passphrase: string): Promise<Buffer> {
    const headerLen = ARCHIVE_MAGIC.length + SCRYPT_SALT_BYTES + GCM_IV_BYTES + GCM_TAG_BYTES;
    if (file.length < headerLen || !file.subarray(0, ARCHIVE_MAGIC.length).equals(ARCHIVE_MAGIC)) {
      throw new BadRequestException('This file is not a valid POS backup archive.');
    }
    let o = ARCHIVE_MAGIC.length;
    const salt = file.subarray(o, (o += SCRYPT_SALT_BYTES));
    const iv = file.subarray(o, (o += GCM_IV_BYTES));
    const tag = file.subarray(o, (o += GCM_TAG_BYTES));
    const ciphertext = file.subarray(o);
    const key = await scrypt(passphrase, salt, SCRYPT_KEYLEN, { N: SCRYPT_COST });
    const decipher = createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(tag);
    let compressed: Buffer;
    try {
      compressed = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
    } catch {
      throw new BadRequestException('Wrong passphrase, or the backup file is corrupted.');
    }
    return gunzip(compressed);
  }
}
```

- [ ] **Step 4 — run tests**: `cd be && npx jest --testPathPattern=device-transfer/services/archive-crypto` → PASS.

- [ ] **Step 5 — commit** (only if the user has asked for commits; otherwise skip all commit steps in this plan).

---

## Task 2: Backend — DB snapshot service (read side)

**Files:**
- Create: `be/src/device-transfer/services/db-snapshot.service.ts`
- Test: `be/src/device-transfer/services/db-snapshot.service.spec.ts` (integration — needs Postgres; skip-guard if `POSTGRES_HOST` unset)

- [ ] **Step 1 — implement the read half**

```ts
// be/src/device-transfer/services/db-snapshot.service.ts
import { Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, QueryRunner } from 'typeorm';

export interface ColumnMeta { name: string; udt: string; }
export interface TableSnapshot { name: string; columns: ColumnMeta[]; rows: unknown[][]; }

const BYTEA = 'bytea';

@Injectable()
export class DbSnapshotService {
  constructor(@InjectDataSource() private readonly ds: DataSource) {}

  /** All public base tables, excluding nothing — `migrations` is included on purpose. */
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
    const rows = raw.map((rec) =>
      columns.map((c) => {
        const v = rec[c.name];
        if (v === null || v === undefined) return null;
        if (c.udt === BYTEA && Buffer.isBuffer(v)) return { $b64: v.toString('base64') };
        return v;
      }),
    );
    return { name: table, columns, rows };
  }

  async getMigrations(): Promise<string[]> {
    const rows = await this.ds.query<{ name: string }[]>(
      `SELECT name FROM migrations ORDER BY id ASC`,
    );
    return rows.map((r) => r.name);
  }
}
```

- [ ] **Step 2 — integration test (guarded)**

```ts
// db-snapshot.service.spec.ts
import { Test } from '@nestjs/testing';
import { TypeOrmModule, getDataSourceToken } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { typeOrmConfig } from '../../database/config/typeorm.config';
import { DbSnapshotService } from './db-snapshot.service';

const maybe = process.env.POSTGRES_HOST || process.env.CI ? describe : describe.skip;

maybe('DbSnapshotService (integration)', () => {
  let svc: DbSnapshotService;
  let ds: DataSource;
  beforeAll(async () => {
    const mod = await Test.createTestingModule({
      imports: [TypeOrmModule.forRoot({ ...typeOrmConfig, autoLoadEntities: false })],
      providers: [DbSnapshotService],
    }).compile();
    svc = mod.get(DbSnapshotService);
    ds = mod.get(getDataSourceToken());
  });
  afterAll(async () => ds?.destroy());

  it('lists tables including migrations', async () => {
    const t = await svc.listTables();
    expect(t).toContain('migrations');
    expect(t).toContain('users');
  });
});
```

Verify path to `typeOrmConfig` export name against `be/src/database/config/` (`typeorm.config.ts` per package.json migration scripts).

- [ ] **Step 3 — run** `cd be && npx jest --testPathPattern=device-transfer/services/db-snapshot` (skips cleanly without a DB).

---

## Task 3: Backend — DB snapshot service (restore side)

**Files:**
- Modify: `be/src/device-transfer/services/db-snapshot.service.ts`

- [ ] **Step 1 — add `restore()` + sequence reset**

```ts
// add to DbSnapshotService

export interface RestorePayload {
  tables: TableSnapshot[];
}

const JSON_UDTS = new Set(['json', 'jsonb']);

// inside the class:

  private decodeValue(v: unknown, udt: string): unknown {
    if (v === null || v === undefined) return null;
    if (typeof v === 'object' && v !== null && '$b64' in (v as Record<string, unknown>)) {
      return Buffer.from((v as { $b64: string }).$b64, 'base64');
    }
    if (JSON_UDTS.has(udt) && typeof v === 'object') return JSON.stringify(v);
    return v;
  }

  /** Full replace. MUST be called inside an open queryRunner transaction. */
  async restore(payload: RestorePayload, qr: QueryRunner): Promise<Record<string, number>> {
    const targetTables = new Set(await this.listTables());
    for (const t of payload.tables) {
      if (!targetTables.has(t.name)) {
        throw new Error(`Archive table "${t.name}" does not exist on this device (schema mismatch).`);
      }
    }
    // superuser-only; disables FK + user triggers for this transaction
    await qr.query(`SET LOCAL session_replication_role = 'replica'`);

    const allTables = [...targetTables].map((n) => `"${n}"`).join(', ');
    await qr.query(`TRUNCATE ${allTables} RESTART IDENTITY CASCADE`);

    const counts: Record<string, number> = {};
    for (const t of payload.tables) {
      if (t.rows.length === 0) { counts[t.name] = 0; continue; }
      const colList = t.columns.map((c) => `"${c.name}"`).join(', ');
      const BATCH = 500;
      for (let i = 0; i < t.rows.length; i += BATCH) {
        const slice = t.rows.slice(i, i + BATCH);
        const params: unknown[] = [];
        const tuples = slice.map((row) => {
          const ph = row.map((val, ci) => {
            params.push(this.decodeValue(val, t.columns[ci].udt));
            return `$${params.length}`;
          });
          return `(${ph.join(', ')})`;
        });
        await qr.query(`INSERT INTO "${t.name}" (${colList}) VALUES ${tuples.join(', ')}`, params);
      }
      counts[t.name] = t.rows.length;
    }

    await this.resetSequences(qr);
    return counts;
  }

  /** Reset every sequence referenced by a column default (covers SERIAL and standalone seqs). */
  private async resetSequences(qr: QueryRunner): Promise<void> {
    const cols = await qr.query<{ table_name: string; column_name: string; column_default: string }[]>(
      `SELECT table_name, column_name, column_default FROM information_schema.columns
       WHERE table_schema = 'public' AND column_default LIKE 'nextval(%'`,
    );
    for (const c of cols) {
      const m = /nextval\('"?([^'"]+)"?'::regclass\)/.exec(c.column_default);
      if (!m) continue;
      const seq = m[1];
      await qr.query(
        `SELECT setval('"${seq}"', GREATEST((SELECT COALESCE(MAX("${c.column_name}"), 0) FROM "${c.table_name}"), 1),
         (SELECT COUNT(*) FROM "${c.table_name}") > 0)`,
      );
    }
  }
```

- [ ] **Step 2** — no isolated unit test here (needs a DB); covered by the e2e round-trip in Task 7.

---

## Task 4: Backend — export & import services

**Files:**
- Create: `be/src/device-transfer/services/device-export.service.ts`
- Create: `be/src/device-transfer/services/device-import.service.ts`
- Create: `be/src/device-transfer/dto/device-transfer-result.dto.ts`
- Test: `be/src/device-transfer/services/device-import.service.spec.ts` (compatibility gate — unit, mock snapshot service)

- [ ] **Step 1 — result DTOs**

```ts
// be/src/device-transfer/dto/device-transfer-result.dto.ts
import { ApiProperty } from '@nestjs/swagger';

export class ManifestDto {
  @ApiProperty() formatVersion: number;
  @ApiProperty() createdAt: string;
  @ApiProperty() backendPackageVersion: string;
  @ApiProperty() database: string;
  @ApiProperty({ nullable: true }) sourceKioskNo: string | null;
  @ApiProperty({ type: [String] }) migrations: string[];
  @ApiProperty({ type: 'object', additionalProperties: { type: 'number' } })
  tableRowCounts: Record<string, number>;
}

export class ImportSummaryDto {
  @ApiProperty() restartRecommended: boolean;
  @ApiProperty({ type: ManifestDto }) manifest: ManifestDto;
  @ApiProperty({ type: 'object', additionalProperties: { type: 'number' } })
  rowsRestored: Record<string, number>;
  @ApiProperty({ type: [String] }) warnings: string[];
}
```

- [ ] **Step 2 — export service**

```ts
// be/src/device-transfer/services/device-export.service.ts
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { ArchiveCryptoService } from './archive-crypto.service';
import { DbSnapshotService } from './db-snapshot.service';
import { ARCHIVE_FORMAT_VERSION } from '../device-transfer.constants';
import { ManifestDto } from '../dto/device-transfer-result.dto';

@Injectable()
export class DeviceExportService {
  constructor(
    private readonly snapshot: DbSnapshotService,
    private readonly crypto: ArchiveCryptoService,
    private readonly config: ConfigService,
  ) {}

  private pkgVersion(): string {
    try {
      return (JSON.parse(readFileSync(join(process.cwd(), 'package.json'), 'utf8')) as { version?: string }).version ?? 'unknown';
    } catch {
      return 'unknown';
    }
  }

  async export(passphrase: string): Promise<{ buffer: Buffer; manifest: ManifestDto }> {
    const tableNames = await this.snapshot.listTables();
    const tables = [];
    const tableRowCounts: Record<string, number> = {};
    for (const name of tableNames) {
      const snap = await this.snapshot.readTable(name);
      tables.push(snap);
      tableRowCounts[name] = snap.rows.length;
    }
    const manifest: ManifestDto = {
      formatVersion: ARCHIVE_FORMAT_VERSION,
      createdAt: new Date().toISOString(),
      backendPackageVersion: this.pkgVersion(),
      database: this.config.get<string>('POSTGRES_DB', 'pos_db'),
      sourceKioskNo: this.config.get<string>('KIOSK_NO') ?? null,
      migrations: await this.snapshot.getMigrations(),
      tableRowCounts,
    };
    const payload = Buffer.from(JSON.stringify({ manifest, tables }));
    const buffer = await this.crypto.encrypt(payload, passphrase);
    return { buffer, manifest };
  }
}
```

- [ ] **Step 3 — import service**

```ts
// be/src/device-transfer/services/device-import.service.ts
import { Injectable, BadRequestException, ConflictException } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ArchiveCryptoService } from './archive-crypto.service';
import { DbSnapshotService, TableSnapshot } from './db-snapshot.service';
import { ARCHIVE_FORMAT_VERSION } from '../device-transfer.constants';
import { ImportSummaryDto, ManifestDto } from '../dto/device-transfer-result.dto';

interface ArchivePayload { manifest: ManifestDto; tables: TableSnapshot[]; }

@Injectable()
export class DeviceImportService {
  constructor(
    @InjectDataSource() private readonly ds: DataSource,
    private readonly snapshot: DbSnapshotService,
    private readonly crypto: ArchiveCryptoService,
  ) {}

  async import(file: Buffer, passphrase: string): Promise<ImportSummaryDto> {
    const json = await this.crypto.decrypt(file, passphrase);
    let payload: ArchivePayload;
    try {
      payload = JSON.parse(json.toString()) as ArchivePayload;
    } catch {
      throw new BadRequestException('The backup archive is unreadable.');
    }
    if (!payload?.manifest || !Array.isArray(payload.tables)) {
      throw new BadRequestException('The backup archive is missing required sections.');
    }
    if (payload.manifest.formatVersion !== ARCHIVE_FORMAT_VERSION) {
      throw new ConflictException(
        `This backup uses format v${payload.manifest.formatVersion}; this device supports v${ARCHIVE_FORMAT_VERSION}.`,
      );
    }
    const current = await this.snapshot.getMigrations();
    const incoming = payload.manifest.migrations ?? [];
    if (current.join('|') !== incoming.join('|')) {
      throw new ConflictException(
        'This backup was made on an incompatible app version (database migration history differs). ' +
          'Update both devices to the same version and try again.',
      );
    }

    const warnings: string[] = [];
    const targetTables = new Set(await this.snapshot.listTables());
    for (const name of targetTables) {
      if (!payload.tables.some((t) => t.name === name)) {
        warnings.push(`Table "${name}" was empty in the backup and is now cleared.`);
      }
    }

    const qr = this.ds.createQueryRunner();
    await qr.connect();
    await qr.startTransaction();
    let rowsRestored: Record<string, number>;
    try {
      rowsRestored = await this.snapshot.restore({ tables: payload.tables }, qr);
      await qr.commitTransaction();
    } catch (err) {
      await qr.rollbackTransaction();
      throw new BadRequestException(
        `Import failed and no data was changed: ${err instanceof Error ? err.message : String(err)}`,
      );
    } finally {
      await qr.release();
    }

    return { restartRecommended: true, manifest: payload.manifest, rowsRestored, warnings };
  }
}
```

- [ ] **Step 4 — unit test the compatibility gate**

```ts
// device-import.service.spec.ts
import { ConflictException } from '@nestjs/common';
import { DeviceImportService } from './device-import.service';
import { ArchiveCryptoService } from './archive-crypto.service';

describe('DeviceImportService compatibility gate', () => {
  const crypto = new ArchiveCryptoService();
  const snapshot = { getMigrations: jest.fn(), listTables: jest.fn().mockResolvedValue([]), restore: jest.fn() };
  const svc = new DeviceImportService({} as never, snapshot as never, crypto);

  it('rejects a mismatched migration history', async () => {
    snapshot.getMigrations.mockResolvedValue(['A', 'B']);
    const payload = { manifest: { formatVersion: 1, migrations: ['A'] }, tables: [] };
    const file = await crypto.encrypt(Buffer.from(JSON.stringify(payload)), 'passphrase1234');
    await expect(svc.import(file, 'passphrase1234')).rejects.toBeInstanceOf(ConflictException);
  });
});
```

Run: `cd be && npx jest --testPathPattern=device-transfer/services/device-import` → PASS.

---

## Task 5: Backend — controller + module + app wiring

**Files:**
- Create: `be/src/device-transfer/dto/export-device.dto.ts`, `dto/import-device.dto.ts`
- Create: `be/src/device-transfer/device-transfer.controller.ts`
- Create: `be/src/device-transfer/device-transfer.module.ts`
- Modify: `be/src/app.module.ts`
- Test: `be/src/device-transfer/device-transfer.controller.spec.ts`

- [ ] **Step 1 — DTOs**

```ts
// export-device.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';
import { MIN_PASSPHRASE_LENGTH } from '../device-transfer.constants';

export class ExportDeviceDto {
  @ApiProperty({ minLength: MIN_PASSPHRASE_LENGTH })
  @IsString()
  @MinLength(MIN_PASSPHRASE_LENGTH)
  passphrase: string;
}
```

```ts
// import-device.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength, IsIn } from 'class-validator';
import { MIN_PASSPHRASE_LENGTH } from '../device-transfer.constants';

export class ImportDeviceDto {
  @ApiProperty({ minLength: MIN_PASSPHRASE_LENGTH })
  @IsString()
  @MinLength(MIN_PASSPHRASE_LENGTH)
  passphrase: string;

  @ApiProperty({ enum: ['true'], description: 'Must be the string "true" to proceed' })
  @IsIn(['true'])
  confirmReplace: 'true';
}
```

- [ ] **Step 2 — controller**

```ts
// device-transfer.controller.ts
import {
  Controller, Post, Body, UseGuards, UseInterceptors, UploadedFile,
  Res, StreamableFile, BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { File } from 'multer';
import type { Response } from 'express';
import { ApiTags, ApiOperation, ApiConsumes, ApiOkResponse } from '@nestjs/swagger';
import { AdminOrSupervisorGuard } from '../auth/guards/admin-or-supervisor.guard';
import { ExportDeviceDto } from './dto/export-device.dto';
import { ImportDeviceDto } from './dto/import-device.dto';
import { ImportSummaryDto } from './dto/device-transfer-result.dto';
import { DeviceExportService } from './services/device-export.service';
import { DeviceImportService } from './services/device-import.service';

@ApiTags('Device Transfer')
@Controller('device-transfer')
@UseGuards(AdminOrSupervisorGuard)
export class DeviceTransferController {
  constructor(
    private readonly exportService: DeviceExportService,
    private readonly importService: DeviceImportService,
  ) {}

  @Post('export')
  @ApiOperation({ summary: 'Export the full device dataset as an encrypted archive' })
  async export(@Body() dto: ExportDeviceDto, @Res({ passthrough: true }) res: Response): Promise<StreamableFile> {
    const { buffer, manifest } = await this.exportService.export(dto.passphrase);
    const stamp = manifest.createdAt.slice(0, 19).replace(/[:T]/g, '-');
    res.set({
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="pos-kiosk-backup-${stamp}.posbackup"`,
      'X-Backup-Row-Counts': Buffer.from(JSON.stringify(manifest.tableRowCounts)).toString('base64'),
    });
    return new StreamableFile(buffer);
  }

  @Post('import')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Replace the full device dataset from an encrypted archive' })
  @ApiOkResponse({ type: ImportSummaryDto })
  async import(@UploadedFile() file: File | undefined, @Body() dto: ImportDeviceDto): Promise<ImportSummaryDto> {
    if (!file?.buffer?.length) throw new BadRequestException('No backup file was uploaded.');
    return this.importService.import(file.buffer, dto.passphrase);
  }
}
```

- [ ] **Step 3 — module**

```ts
// device-transfer.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '../config/config.module';
import { DeviceTransferController } from './device-transfer.controller';
import { ArchiveCryptoService } from './services/archive-crypto.service';
import { DbSnapshotService } from './services/db-snapshot.service';
import { DeviceExportService } from './services/device-export.service';
import { DeviceImportService } from './services/device-import.service';

@Module({
  imports: [ConfigModule],
  controllers: [DeviceTransferController],
  providers: [ArchiveCryptoService, DbSnapshotService, DeviceExportService, DeviceImportService],
})
export class DeviceTransferModule {}
```

Note: `@InjectDataSource()` resolves from the global `DatabaseModule` (already `TypeOrmModule.forRoot`ed). Confirm `DatabaseModule` exports/── that `getDataSourceToken()` is injectable app-wide (it is with `forRoot`). Add `TypeOrmModule` to imports only if injection fails.

- [ ] **Step 4 — register in `app.module.ts`**: add `import { DeviceTransferModule } from './device-transfer/device-transfer.module';` and put `DeviceTransferModule` in the `imports` array after `PosTerminalsModule`.

- [ ] **Step 5 — multipart size limit**: the import archive can be several MB. In `be/src/main.ts` after `app.useGlobalPipes(...)` there is no body limit set for multipart (multer default is unlimited for disk, but memory storage caps). `FileInterceptor` uses memory storage by default; set `FileInterceptor('file', { limits: { fileSize: 200 * 1024 * 1024 } })` in the controller. Update Step 2 accordingly.

- [ ] **Step 6 — controller spec** (mock both services, assert guard + headers + no-file error).

```ts
// device-transfer.controller.spec.ts
import { BadRequestException } from '@nestjs/common';
import { DeviceTransferController } from './device-transfer.controller';

describe('DeviceTransferController', () => {
  const exportService = { export: jest.fn() };
  const importService = { import: jest.fn() };
  const ctrl = new DeviceTransferController(exportService as never, importService as never);

  it('rejects import with no file', async () => {
    await expect(ctrl.import(undefined, { passphrase: 'x'.repeat(12), confirmReplace: 'true' }))
      .rejects.toBeInstanceOf(BadRequestException);
  });

  it('sets attachment headers on export', async () => {
    exportService.export.mockResolvedValue({ buffer: Buffer.from('x'), manifest: { createdAt: '2026-09-02T10:00:00.000Z', tableRowCounts: {} } });
    const res = { set: jest.fn() } as never;
    await ctrl.export({ passphrase: 'x'.repeat(12) }, res);
    expect((res as { set: jest.Mock }).set).toHaveBeenCalledWith(expect.objectContaining({ 'Content-Type': 'application/octet-stream' }));
  });
});
```

Run: `cd be && npx jest --testPathPattern=device-transfer` → PASS. Then `npm run lint` and `npm run build`.

---

## Task 6: Backend — e2e round-trip test

**Files:**
- Create: `be/test/device-transfer.e2e-spec.ts`

- [ ] **Step 1 — test** (guarded on `POSTGRES_HOST`; needs a seeded dev DB)

```ts
import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

const maybe = process.env.POSTGRES_HOST ? describe : describe.skip;

maybe('Device transfer (e2e)', () => {
  let app: INestApplication;
  let token: string;

  beforeAll(async () => {
    const mod = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = mod.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.init();
    // log in as a seeded admin — adjust credentials to the seed data
    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'admin@example.com', password: 'admin' });
    token = res.body?.accessToken;
  });
  afterAll(async () => app?.close());

  it('exports, then imports the same archive without error', async () => {
    const pass = 'e2e-passphrase-1234';
    const exp = await request(app.getHttpServer())
      .post('/api/v1/device-transfer/export')
      .set('Authorization', `Bearer ${token}`)
      .send({ passphrase: pass })
      .buffer(true)
      .parse((res, cb) => {
        const chunks: Buffer[] = [];
        res.on('data', (c) => chunks.push(c as Buffer));
        res.on('end', () => cb(null, Buffer.concat(chunks)));
      });
    expect(exp.status).toBe(201);
    const archive: Buffer = exp.body;

    const imp = await request(app.getHttpServer())
      .post('/api/v1/device-transfer/import')
      .set('Authorization', `Bearer ${token}`)
      .field('passphrase', pass)
      .field('confirmReplace', 'true')
      .attach('file', archive, 'backup.posbackup');
    expect(imp.status).toBe(200);
    expect(imp.body.rowsRestored.users).toBeGreaterThan(0);
  });
});
```

- [ ] **Step 2 — run** `cd be && npm run test:e2e` (skips without a DB; document that a seeded dev DB + real admin creds are required to exercise it).

---

## Task 7: Kiosk — API source + schemas

**Files:**
- Create: `kiosk/lib/data/backend_api/schemas/device_transfer_manifest_dto.dart`
- Create: `kiosk/lib/data/backend_api/schemas/device_import_summary_dto.dart`
- Create: `kiosk/lib/data/backend_api/sources/device_transfer_api.dart`

- [ ] **Step 1 — manifest schema**

```dart
// device_transfer_manifest_dto.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'device_transfer_manifest_dto.mapper.dart';

@MappableClass()
class DeviceTransferManifestDto with DeviceTransferManifestDtoMappable {
  const DeviceTransferManifestDto({
    required this.formatVersion,
    required this.createdAt,
    required this.backendPackageVersion,
    required this.database,
    required this.tableRowCounts,
    this.sourceKioskNo,
  });

  final int formatVersion;
  final String createdAt;
  final String backendPackageVersion;
  final String database;
  final String? sourceKioskNo;
  final Map<String, int> tableRowCounts;

  int get totalRows => tableRowCounts.values.fold(0, (a, b) => a + b);
}
```

- [ ] **Step 2 — import summary schema**

```dart
// device_import_summary_dto.dart
import 'package:dart_mappable/dart_mappable.dart';

import 'device_transfer_manifest_dto.dart';

part 'device_import_summary_dto.mapper.dart';

@MappableClass()
class DeviceImportSummaryDto with DeviceImportSummaryDtoMappable {
  const DeviceImportSummaryDto({
    required this.restartRecommended,
    required this.manifest,
    required this.rowsRestored,
    required this.warnings,
  });

  final bool restartRecommended;
  final DeviceTransferManifestDto manifest;
  final Map<String, int> rowsRestored;
  final List<String> warnings;

  int get totalRowsRestored => rowsRestored.values.fold(0, (a, b) => a + b);
}
```

- [ ] **Step 3 — API source** (mirrors `reports_api.dart` / CSV import)

```dart
// device_transfer_api.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/device_import_summary_dto.dart';

final deviceTransferApiProvider = Provider<DeviceTransferApi>((ref) {
  return DeviceTransferApi(ref.watch(secureApiClientProvider));
});

class DeviceTransferApi {
  const DeviceTransferApi(this._client);

  final Dio _client;

  Future<Uint8List> export({required String passphrase}) async {
    final response = await _client.post<List<int>>(
      '/api/v1/device-transfer/export',
      data: {'passphrase': passphrase},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(minutes: 2),
      ),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  Future<DeviceImportSummaryDto> import({
    required Uint8List archiveBytes,
    required String fileName,
    required String passphrase,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(archiveBytes, filename: fileName),
      'passphrase': passphrase,
      'confirmReplace': 'true',
    });
    final response = await _client.post<dynamic>(
      '/api/v1/device-transfer/import',
      data: formData,
      options: Options(
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(minutes: 10),
      ),
    );
    return DeviceImportSummaryDto.fromJson(jsonEncode(response.data));
  }
}
```

- [ ] **Step 4** — `cd kiosk && dart run build_runner build --delete-conflicting-outputs` then `dart analyze lib/data/backend_api` → no issues.

---

## Task 8: Kiosk — repository + state

**Files:**
- Create: `kiosk/lib/features/device_transfer/repositories/device_transfer_repository.dart`
- Create: `kiosk/lib/features/device_transfer/state/device_transfer_notifier.dart`

- [ ] **Step 1 — repository**

```dart
// device_transfer_repository.dart
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/device_import_summary_dto.dart';
import '../../../data/backend_api/sources/device_transfer_api.dart';

final deviceTransferRepositoryProvider = Provider<DeviceTransferRepository>((ref) {
  return DeviceTransferRepository(ref.watch(deviceTransferApiProvider));
});

class DeviceTransferRepository {
  const DeviceTransferRepository(this._api);

  final DeviceTransferApi _api;

  Future<Uint8List> exportArchive(String passphrase) =>
      _api.export(passphrase: passphrase);

  Future<DeviceImportSummaryDto> importArchive({
    required Uint8List bytes,
    required String fileName,
    required String passphrase,
  }) =>
      _api.import(archiveBytes: bytes, fileName: fileName, passphrase: passphrase);
}
```

- [ ] **Step 2 — notifier with mutations**

```dart
// device_transfer_notifier.dart
import 'dart:typed_data';

import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/device_import_summary_dto.dart';
import '../repositories/device_transfer_repository.dart';

class DeviceTransferNotifier {
  static final exportAction = Mutation<Uint8List>();
  static final importAction = Mutation<DeviceImportSummaryDto>();
}

final deviceTransferControllerProvider = Provider<DeviceTransferController>((ref) {
  return DeviceTransferController(ref);
});

class DeviceTransferController {
  DeviceTransferController(this._ref);

  final Ref _ref;

  Future<Uint8List> export(String passphrase) =>
      _ref.read(deviceTransferRepositoryProvider).exportArchive(passphrase);

  Future<DeviceImportSummaryDto> import({
    required Uint8List bytes,
    required String fileName,
    required String passphrase,
  }) =>
      _ref.read(deviceTransferRepositoryProvider).importArchive(
            bytes: bytes,
            fileName: fileName,
            passphrase: passphrase,
          );
}
```

- [ ] **Step 3** — `dart analyze lib/features/device_transfer`.

---

## Task 9: Kiosk — hub screen + route + menu entry

**Files:**
- Modify: `kiosk/lib/features/menu/enums/menu_type.dart` (add `backupTransfer`)
- Create: `kiosk/lib/features/device_transfer/view/device_transfer_screen.dart`
- Create: `kiosk/lib/navigation/device_transfer_route.dart`
- Modify: `kiosk/lib/navigation/router.dart` (add `part` + import screen)
- Modify: `kiosk/lib/features/menu/view/menu_grid.dart` (tile + gate + nav)

- [ ] **Step 1 — menu type**: add `backupTransfer,` to the enum (before `logout`).

- [ ] **Step 2 — route file**

```dart
// kiosk/lib/navigation/device_transfer_route.dart
part of 'router.dart';

@TypedGoRoute<DeviceTransferRoute>(path: '/device-transfer')
class DeviceTransferRoute extends GoRouteData with $DeviceTransferRoute {
  const DeviceTransferRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DeviceTransferScreen();
  }
}
```

- [ ] **Step 3 — router.dart**: add `import '../features/device_transfer/view/device_transfer_screen.dart';` and `part 'device_transfer_route.dart';` alongside the others.

- [ ] **Step 4 — hub screen** (`WindowsScaffold` + two large cards, follows `kiosk/CLAUDE.md`). Cards: "Export Backup" (icon `Icons.download_rounded`) opens `showExportBackupDialog`; "Import & Restore" (icon `Icons.settings_backup_restore_rounded`, danger accent) opens `showImportBackupDialog`. Include a short explainer paragraph and a "sensitive data" warning chip. Use `context.responsive.value` for all sizes, `POSColors` / `POSRadius` tokens, min tap target 56.

- [ ] **Step 5 — menu_grid.dart**:
  - Add to `_getMenuItems()` base list: `MenuItem(label: 'Backup & Transfer', icon: const Icon(Icons.settings_backup_restore_rounded), type: MenuType.backupTransfer)`.
  - It is already excluded for `Role.user` (the `role == Role.user` branch whitelists only newOrder/orders/logout/transactions), so admins + supervisors get it automatically.
  - In the `onTap` switch add: `if (type == MenuType.backupTransfer) { const DeviceTransferRoute().push<void>(context); return; }`.

- [ ] **Step 6** — `cd kiosk && dart run build_runner build --delete-conflicting-outputs` (regenerates `router.g.dart`), then `dart analyze`.

---

## Task 10: Kiosk — export dialog

**Files:**
- Create: `kiosk/lib/features/device_transfer/view/export_backup_dialog.dart`

- [ ] **Step 1 — flow**: `HookConsumerWidget` dialog.
  1. Explainer + "the file contains PINs and customer/sales data — store it securely; it cannot be opened without the passphrase".
  2. Two obscured `TextField`s: passphrase + confirm. Validate: length >= 12, both match.
  3. On submit: `SupervisorAuthorizationDialog.show(context, title: 'Authorize Backup Export', warningMessage: 'Exporting the full device dataset requires admin or supervisor authorization.', ctaLabel: 'Authorize Export', ctaIcon: Icons.download_rounded)`. Abort if it returns null.
  4. Run `DeviceTransferNotifier.exportAction.run(ref, (txn) => txn.get(deviceTransferControllerProvider).export(passphrase))`.
  5. On `MutationSuccess`: `FilePicker.platform.saveFile(dialogTitle: 'Save backup', fileName: 'pos-kiosk-backup-<yyyyMMdd-HHmm>.posbackup', bytes: value)` — on Windows desktop `saveFile` returns a path; then `File(path).writeAsBytes(value)`. (Match the CSV dialog's `downloadTemplate` pattern.)
  6. Success `showMessageDialog` with the saved path.
  7. On `MutationError`: `showNetworkErrorDialog(context, error: error)`.

- [ ] **Step 2** — `dart analyze`.

---

## Task 11: Kiosk — import dialog

**Files:**
- Create: `kiosk/lib/features/device_transfer/view/import_backup_dialog.dart`

- [ ] **Step 1 — flow**: `HookConsumerWidget` dialog, danger-styled (mirror the CSV `replace` warning box).
  1. Big red warning: "This permanently replaces ALL data on this device — every user, transaction, product, report and setting. The current data cannot be recovered afterwards."
  2. `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['posbackup'], withData: true)` → keep `bytes` + `name`.
  3. Obscured passphrase `TextField`.
  4. Type-to-confirm `TextField`: button stays disabled until the text equals `REPLACE`.
  5. On submit: `SupervisorAuthorizationDialog.show(...)` (title 'Authorize Restore', ctaLabel 'Authorize Restore', ctaIcon Icons.settings_backup_restore_rounded). Abort on null.
  6. `DeviceTransferNotifier.importAction.run(ref, (txn) => txn.get(deviceTransferControllerProvider).import(bytes: bytes, fileName: name, passphrase: passphrase))`. Show an indeterminate progress state ("Restoring — do not close the app…").
  7. On `MutationError`: if the Dio error response status is 409, show a calm `showMessageDialog(type: warning, title: 'Incompatible Backup', message: <server message>)`; else `showNetworkErrorDialog`.
  8. On `MutationSuccess`: `showMessageDialog(type: success, title: 'Restore Complete', message: '<totalRowsRestored> records restored.\n\nYou will be signed out now. Restart the device if data looks incomplete.')` then `const LoginRoute().go(context)`.

- [ ] **Step 2** — `dart analyze` (whole project) clean; `flutter analyze` if available.

---

## Task 12: Docs

**Files:**
- Modify: `CLAUDE.md` — under "Backend / Architecture", add `device-transfer` to the module list and a schema note: *"`device-transfer` exports/imports the entire `public` schema as an encrypted archive; import is a full-replace restore gated on an identical migration history."*
- Modify: `kiosk/CLAUDE.md` — add `device_transfer` to "Implemented features".
- Create: `docs/runbooks/kiosk-device-migration.md` — operator steps: export on old machine → copy `.posbackup` file → install app on new machine + register/point at its own backend → Import & Restore → restart both services → verify users/inventory/transactions/receipt number.

- [ ] **Step 1** — write the three doc changes.
- [ ] **Step 2** — final `cd be && npm run lint && npm run build` and `cd kiosk && dart analyze`.

---

## Self-Review

- **Spec coverage:** export (Task 4/5), import full-replace (Task 3/4/5), encryption (Task 1), manifest + compatibility gate (Task 4), admin/supervisor gate (Task 5 guard + Task 9 menu + Task 10/11 supervisor dialog), fiscal sequence continuity (Task 3 `resetSequences` — covers `z_readings_z_counter_seq` and all serials), kiosk UI (Tasks 9–11), docs (Task 12). Covered.
- **Placeholder scan:** Task 9 Step 4 and Task 10/11 describe UI in prose rather than full code — acceptable because they must follow `kiosk/CLAUDE.md` design tokens and mirror `import_products_csv_dialog.dart`; the flow steps are explicit. All backend code is complete.
- **Type consistency:** `ImportSummaryDto` / `DeviceImportSummaryDto` fields (`restartRecommended`, `manifest`, `rowsRestored`, `warnings`) match across backend DTO, kiosk schema, and both dialogs. `export()` returns `Uint8List` everywhere. Archive magic `POSKBK01` consistent.
- **Risks:** `SET session_replication_role` needs a superuser DB role (true for bundled + dev `postgres`). `saveFile(bytes:)` support on Windows desktop — fall back to `saveFile()` path + `File.writeAsBytes` (Task 10 Step 1.5 already does this).
