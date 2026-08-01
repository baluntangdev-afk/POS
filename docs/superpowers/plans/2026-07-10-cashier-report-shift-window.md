# Cashier Report Shift Window Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Cashier Daily Report and X-Reading cover "the cashier's first not-yet-reported transaction through now," instead of the current hard `so_date::date = CURRENT_DATE` boundary that drops a shift's earlier transactions once midnight passes.

**Architecture:** Add two boolean columns to `sales_orders` (`done_daily_report`, `done_x_reading`, both default `false`, never flipped in this plan). Both report services swap their calendar-day filter for `done_* = false` (+ `so_date <= NOW()`). Both reports also start returning `periodStart`/`periodEnd` (earliest/latest covered transaction) instead of `businessDate`, and the kiosk displays that as a new "Period" line on the preview and printed receipt.

**Tech Stack:** NestJS + TypeORM + PostgreSQL (`be/`), Flutter + Riverpod + dart_mappable (`kiosk/`).

**Spec:** `docs/superpowers/specs/2026-07-10-cashier-report-shift-window-design.md`

---

### Task 1: Migration — `done_daily_report` / `done_x_reading` columns

**Files:**
- Create: `be/src/database/migrations/<generated-timestamp>-sales-orders-done-daily-report-and-x-reading.ts`
- Modify: `be/src/database/migrations-index.ts` (auto-synced, do not hand-edit)
- Modify: `be/src/sales-orders/entities/sales-order.entity.ts`

- [ ] **Step 1: Generate the migration file**

Run:
```bash
cd be
npm run migration:create sales-orders-done-daily-report-and-x-reading
```
Expected: a new file appears at `be/src/database/migrations/<timestamp>-sales-orders-done-daily-report-and-x-reading.ts` containing an empty scaffold like:
```ts
import { MigrationInterface, QueryRunner } from "typeorm";

export class SalesOrdersDoneDailyReportAndXReading<TIMESTAMP> implements MigrationInterface {

    public async up(queryRunner: QueryRunner): Promise<void> {
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
    }

}
```
The command also auto-runs `npm run migration:sync-index` and `npm run format`, so `be/src/database/migrations-index.ts` already lists the new class — don't touch that file by hand.

- [ ] **Step 2: Fill in the migration body**

Open the generated file. Keep its auto-generated `export class ...` line exactly as generated (the `<TIMESTAMP>` suffix is whatever the tool produced — copy it verbatim, do not renumber). Add a `name` property matching the class name (matches this repo's convention, e.g. `1779584000000-sales-orders-done-export.ts`), and fill in both method bodies:

```ts
import { MigrationInterface, QueryRunner } from 'typeorm';

export class SalesOrdersDoneDailyReportAndXReading<TIMESTAMP> implements MigrationInterface {
  name = 'SalesOrdersDoneDailyReportAndXReading<TIMESTAMP>';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        ADD COLUMN "done_daily_report" boolean NOT NULL DEFAULT false,
        ADD COLUMN "done_x_reading" boolean NOT NULL DEFAULT false
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        DROP COLUMN IF EXISTS "done_daily_report",
        DROP COLUMN IF EXISTS "done_x_reading"
    `);
  }
}
```

(Replace both `<TIMESTAMP>` placeholders above with the real generated suffix — e.g. if the tool generated `SalesOrdersDoneDailyReportAndXReading1789000000000`, use that exact identifier in both the class name and the `name` string.)

- [ ] **Step 3: Add the entity columns**

In `be/src/sales-orders/entities/sales-order.entity.ts`, find:

```ts
  @Column({ name: 'done_export', type: 'boolean', default: false })
  doneExport: boolean;
```

Add immediately after it:

```ts
  @Column({ name: 'done_export', type: 'boolean', default: false })
  doneExport: boolean;

  @Column({ name: 'done_daily_report', type: 'boolean', default: false })
  doneDailyReport: boolean;

  @Column({ name: 'done_x_reading', type: 'boolean', default: false })
  doneXReading: boolean;
```

- [ ] **Step 4: Apply the migration locally and verify**

Requires local Postgres running (see `be/.env` for connection config). Run:
```bash
cd be
npm run migration:up
```
Expected output ends with something like `Migration SalesOrdersDoneDailyReportAndXReading<TIMESTAMP> has been executed successfully.` Verify the columns exist:
```bash
npx typeorm-ts-node-commonjs query "SELECT column_name FROM information_schema.columns WHERE table_name = 'sales_orders' AND column_name IN ('done_daily_report','done_x_reading')" -d src/database/config/typeorm.config.ts
```
Expected: both column names listed.

- [ ] **Step 5: Commit**

```bash
git add be/src/database/migrations be/src/database/migrations-index.ts be/src/sales-orders/entities/sales-order.entity.ts
git commit -m "feat(reports): add done_daily_report and done_x_reading columns to sales_orders"
```

---

### Task 2: Backend — shared raw-row interface for period fields

**Files:**
- Modify: `be/src/reports/reports.interface.ts`

- [ ] **Step 1: Add `periodStart`/`periodEnd` to `CashierSalesTotalsRawRow`**

This interface is shared by both `CashierDailyReportService.getSalesTotals` and `CashierXReadingReportService.getSalesTotals`. Find:

```ts
export interface CashierSalesTotalsRawRow {
  totalSales?: string | number | null;
  totalDiscounts?: string | number | null;
  completedTransactions?: string | number | null;
  averageSale?: string | number | null;
  highestSale?: string | number | null;
  lowestSale?: string | number | null;
}
```

Replace with:

```ts
export interface CashierSalesTotalsRawRow {
  totalSales?: string | number | null;
  totalDiscounts?: string | number | null;
  completedTransactions?: string | number | null;
  averageSale?: string | number | null;
  highestSale?: string | number | null;
  lowestSale?: string | number | null;
  periodStart?: Date | string | null;
  periodEnd?: Date | string | null;
}
```

- [ ] **Step 2: Verify it compiles**

Run:
```bash
cd be
npx tsc --noEmit
```
Expected: no new errors (the two services haven't been updated to populate these fields yet, but adding optional properties to an interface is never a breaking change).

- [ ] **Step 3: Commit**

```bash
git add be/src/reports/reports.interface.ts
git commit -m "feat(reports): add periodStart/periodEnd to CashierSalesTotalsRawRow"
```

---

### Task 3: Backend — Cashier Daily Report service query window

**Files:**
- Modify: `be/src/reports/services/cashier-daily-report.service.ts`

- [ ] **Step 1: Replace the calendar-day filter everywhere in the file**

The exact string `.andWhere('so.so_date::date = CURRENT_DATE')` appears identically in all 7 private query methods (`getSalesTotals`, `getTax`, `getVatExemptSales`, `getQuantitySold`, `getSalesByProduct`, `getCashSales`, `getCashLedgerEntries`). Replace **every occurrence** with:

```ts
      .andWhere('so.done_daily_report = :doneDailyReport', { doneDailyReport: false })
      .andWhere('so.so_date <= NOW()')
```

(Use a find-and-replace-all across the file — the old string is byte-identical in all 7 places, so a single `replace_all` edit handles it.)

- [ ] **Step 2: Add the period range to `getSalesTotals`**

The line `.addSelect('COUNT(so.id)', 'completedTransactions')` appears exactly once in this file, inside `getSalesTotals`. Find:

```ts
      .addSelect('COUNT(so.id)', 'completedTransactions')
```

Replace with:

```ts
      .addSelect('COUNT(so.id)', 'completedTransactions')
      .addSelect('MIN(so.so_date)', 'periodStart')
      .addSelect('MAX(so.so_date)', 'periodEnd')
```

- [ ] **Step 3: Verify the full file now reads correctly**

Read `be/src/reports/services/cashier-daily-report.service.ts` and confirm:
- All 7 methods have the `done_daily_report = false` + `so_date <= NOW()` pair instead of `so_date::date = CURRENT_DATE`.
- `getSalesTotals` has the two new `addSelect` calls right after `completedTransactions`.
- No method still references `CURRENT_DATE`.

- [ ] **Step 4: Type-check**

```bash
cd be
npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add be/src/reports/services/cashier-daily-report.service.ts
git commit -m "feat(reports): scope cashier daily report to unreported transactions instead of calendar day"
```

---

### Task 4: Backend — Cashier Daily Report DTO + mapper + spec

**Files:**
- Modify: `be/src/reports/dto/cashier-daily-report-response.dto.ts`
- Modify: `be/src/reports/mapper/cashier-daily-report.mapper.ts`
- Modify: `be/src/reports/mapper/cashier-daily-report.mapper.spec.ts`

- [ ] **Step 1: Update the DTO**

In `cashier-daily-report-response.dto.ts`, find:

```ts
  @ApiProperty({ description: 'Business date (today), formatted MM/DD/YYYY', example: '07/10/2026' })
  businessDate: string;

  @ApiProperty({
    description: 'Report generation timestamp (ISO 8601)',
    example: '2026-07-10T14:32:10.000Z',
  })
  reportGeneratedAt: string;
```

Replace with:

```ts
  @ApiProperty({
    description: 'Earliest unreported transaction in this report, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-10T20:15:00.000Z',
  })
  periodStart: string | null;

  @ApiProperty({
    description: 'Latest unreported transaction in this report, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-11T03:02:00.000Z',
  })
  periodEnd: string | null;

  @ApiProperty({
    description: 'Report generation timestamp (ISO 8601)',
    example: '2026-07-10T14:32:10.000Z',
  })
  reportGeneratedAt: string;
```

- [ ] **Step 2: Update the mapper imports**

In `cashier-daily-report.mapper.ts`, find:

```ts
import dayjs from 'dayjs';
import { User } from '../../users/entities/user.entity';
import { toDecimalNumber } from '../../utils/calculation.helper';
import {
  CashierDailyReportResponseDto,
  CashLedgerEntryDto,
  ProductSalesLineDto,
} from '../dto/cashier-daily-report-response.dto';
import { DATE_FORMAT } from '../reports.constants';
import type {
```

Replace with:

```ts
import { User } from '../../users/entities/user.entity';
import { toDecimalNumber } from '../../utils/calculation.helper';
import {
  CashierDailyReportResponseDto,
  CashLedgerEntryDto,
  ProductSalesLineDto,
} from '../dto/cashier-daily-report-response.dto';
import type {
```

- [ ] **Step 3: Update the mapper body**

Find:

```ts
    return {
      cashierName,
      terminalName,
      businessDate: dayjs().format(DATE_FORMAT),
      reportGeneratedAt: new Date().toISOString(),
```

Replace with:

```ts
    return {
      cashierName,
      terminalName,
      periodStart: toIsoOrNull(raw.salesTotals?.periodStart),
      periodEnd: toIsoOrNull(raw.salesTotals?.periodEnd),
      reportGeneratedAt: new Date().toISOString(),
```

Then add this helper at the bottom of the file (after `toCashLedgerEntryDto`):

```ts
function toIsoOrNull(value: Date | string | null | undefined): string | null {
  return value ? new Date(value).toISOString() : null;
}
```

- [ ] **Step 4: Update the failing/passing spec**

In `cashier-daily-report.mapper.spec.ts`, find the `makeRaw` default fixture:

```ts
    salesTotals: { totalSales: '10839.00', completedTransactions: '73' },
```

Replace with:

```ts
    salesTotals: {
      totalSales: '10839.00',
      completedTransactions: '73',
      periodStart: new Date('2026-07-10T20:15:00.000Z'),
      periodEnd: new Date('2026-07-11T03:02:00.000Z'),
    },
```

Then in the first test (`'maps raw rows into the response DTO'`), add these two assertions right after `expect(dto.terminalName).toBe('T/M#0003');`:

```ts
    expect(dto.periodStart).toBe('2026-07-10T20:15:00.000Z');
    expect(dto.periodEnd).toBe('2026-07-11T03:02:00.000Z');
```

Finally, in the `'defaults every value when queries return nothing'` test, add these two assertions right after `expect(dto.grossSales).toBe(0);`:

```ts
    expect(dto.periodStart).toBeNull();
    expect(dto.periodEnd).toBeNull();
```

- [ ] **Step 5: Run the spec and confirm it passes**

```bash
cd be
npx jest --testPathPattern=src/reports/mapper/cashier-daily-report.mapper.spec.ts
```
Expected: `Tests: 4 passed, 4 total` (all four `it(...)` blocks green).

- [ ] **Step 6: Type-check**

```bash
cd be
npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add be/src/reports/dto/cashier-daily-report-response.dto.ts be/src/reports/mapper/cashier-daily-report.mapper.ts be/src/reports/mapper/cashier-daily-report.mapper.spec.ts
git commit -m "feat(reports): replace cashier daily report businessDate with periodStart/periodEnd"
```

---

### Task 5: Backend — Cashier X-Reading service query window

**Files:**
- Modify: `be/src/reports/services/cashier-x-reading-report.service.ts`

- [ ] **Step 1: Replace the calendar-day filter everywhere in the file**

The exact string `.andWhere('so.so_date::date = CURRENT_DATE')` appears identically in all 9 private query methods (`getPaymentBreakdown`, `getPaymentLedgerEntries`, `getDiscountBreakdown`, `getSalesTotals`, `getVoidedCount`, `getRefundedCount`, `getTax`, `getVatExemptSales`, `getQuantitySold`). Replace **every occurrence** with:

```ts
      .andWhere('so.done_x_reading = :doneXReading', { doneXReading: false })
      .andWhere('so.so_date <= NOW()')
```

- [ ] **Step 2: Add the period range to `getSalesTotals`**

The line `.addSelect('COUNT(so.id)', 'completedTransactions')` appears exactly once in this file, inside `getSalesTotals`. Find:

```ts
      .addSelect('COUNT(so.id)', 'completedTransactions')
```

Replace with:

```ts
      .addSelect('COUNT(so.id)', 'completedTransactions')
      .addSelect('MIN(so.so_date)', 'periodStart')
      .addSelect('MAX(so.so_date)', 'periodEnd')
```

- [ ] **Step 3: Update the class doc comment**

The file's top comment currently reads "read-only snapshot of the current cashier's own transactions today". Find:

```ts
/**
 * X Reading: read-only snapshot of the current cashier's own transactions today, on their
 * assigned terminal. Never resets counters, closes a shift, or mutates any data.
 */
```

Replace with:

```ts
/**
 * X Reading: read-only snapshot of the current cashier's own unreported transactions (from
 * their first not-yet-reported transaction through now), on their assigned terminal. Never
 * resets counters, closes a shift, or mutates any data.
 */
```

- [ ] **Step 4: Verify the full file now reads correctly**

Read `be/src/reports/services/cashier-x-reading-report.service.ts` and confirm all 9 methods use `done_x_reading = false` + `so_date <= NOW()`, `getSalesTotals` has the two new `addSelect` calls, and no method still references `CURRENT_DATE`.

- [ ] **Step 5: Type-check**

```bash
cd be
npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add be/src/reports/services/cashier-x-reading-report.service.ts
git commit -m "feat(reports): scope cashier X-reading to unreported transactions instead of calendar day"
```

---

### Task 6: Backend — Cashier X-Reading DTO + mapper + new spec

**Files:**
- Modify: `be/src/reports/dto/cashier-x-reading-response.dto.ts`
- Modify: `be/src/reports/mapper/cashier-x-reading-report.mapper.ts`
- Create: `be/src/reports/mapper/cashier-x-reading-report.mapper.spec.ts`

- [ ] **Step 1: Update the DTO**

In `cashier-x-reading-response.dto.ts`, find:

```ts
  @ApiProperty({ description: 'Business date (today), formatted MM/DD/YYYY', example: '07/09/2026' })
  businessDate: string;

  @ApiProperty({
    description: 'Report generation timestamp (ISO 8601)',
    example: '2026-07-09T14:32:10.000Z',
  })
  reportGeneratedAt: string;
```

Replace with:

```ts
  @ApiProperty({
    description: 'Earliest unreported transaction in this report, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-10T20:15:00.000Z',
  })
  periodStart: string | null;

  @ApiProperty({
    description: 'Latest unreported transaction in this report, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-11T03:02:00.000Z',
  })
  periodEnd: string | null;

  @ApiProperty({
    description: 'Report generation timestamp (ISO 8601)',
    example: '2026-07-09T14:32:10.000Z',
  })
  reportGeneratedAt: string;
```

- [ ] **Step 2: Update the mapper imports**

In `cashier-x-reading-report.mapper.ts`, find:

```ts
import dayjs from 'dayjs';
import { User } from '../../users/entities/user.entity';
import { toDecimalNumber } from '../../utils/calculation.helper';
import {
  CashierXReadingResponseDto,
  NameAmountDto,
  PaymentLedgerDto,
} from '../dto/cashier-x-reading-response.dto';
import { DATE_FORMAT } from '../reports.constants';
import type {
```

Replace with:

```ts
import { User } from '../../users/entities/user.entity';
import { toDecimalNumber } from '../../utils/calculation.helper';
import {
  CashierXReadingResponseDto,
  NameAmountDto,
  PaymentLedgerDto,
} from '../dto/cashier-x-reading-response.dto';
import type {
```

- [ ] **Step 3: Update the mapper body**

Find:

```ts
    return {
      cashierName,
      terminalName,
      businessDate: dayjs().format(DATE_FORMAT),
      reportGeneratedAt: new Date().toISOString(),
      salesByPaymentMethod,
```

Replace with:

```ts
    return {
      cashierName,
      terminalName,
      periodStart: toIsoOrNull(raw.salesTotals?.periodStart),
      periodEnd: toIsoOrNull(raw.salesTotals?.periodEnd),
      reportGeneratedAt: new Date().toISOString(),
      salesByPaymentMethod,
```

Then add this helper at the bottom of the file (after `toPaymentLedgers`):

```ts
function toIsoOrNull(value: Date | string | null | undefined): string | null {
  return value ? new Date(value).toISOString() : null;
}
```

- [ ] **Step 4: Write the new mapper spec**

Create `be/src/reports/mapper/cashier-x-reading-report.mapper.spec.ts`:

```ts
import { User } from '../../users/entities/user.entity';
import { CashierXReadingReportMapper, CashierXReadingRawInputs } from './cashier-x-reading-report.mapper';

function makeUser(): User {
  const user = new User();
  user.firstName = 'Juan';
  user.lastName = 'Dela Cruz';
  user.posTerminal = { legalName: 'POS-01' } as User['posTerminal'];
  return user;
}

function makeRaw(overrides: Partial<CashierXReadingRawInputs> = {}): CashierXReadingRawInputs {
  return {
    currentUser: makeUser(),
    paymentRows: [{ name: 'Cash', amount: '19050.00' }],
    paymentLedgerRows: [
      {
        name: 'Cash',
        paymentDate: new Date('2026-07-10T12:00:00.000Z'),
        transactionReference: null,
        amount: '405.00',
      },
    ],
    discountRows: [{ name: 'Senior Citizen / PWD', amount: '665.00' }],
    salesTotals: {
      totalSales: '19050.00',
      totalDiscounts: '665.00',
      completedTransactions: '42',
      averageSale: '453.57',
      highestSale: '1250.00',
      lowestSale: '85.00',
      periodStart: new Date('2026-07-10T20:15:00.000Z'),
      periodEnd: new Date('2026-07-11T03:02:00.000Z'),
    },
    voided: { voidedTransactions: '1' },
    refunded: { refundedTransactions: '1' },
    tax: { vatSales: '17000.89', vatAmount: '2041.11' },
    vatExempt: { vatExemptSales: '2008.00' },
    quantity: { totalQuantitySold: '187' },
    ...overrides,
  };
}

describe('CashierXReadingReportMapper', () => {
  it('maps raw rows into the response DTO', () => {
    const dto = CashierXReadingReportMapper.toDto(makeRaw());

    expect(dto.cashierName).toBe('Juan Dela Cruz');
    expect(dto.terminalName).toBe('POS-01');
    expect(dto.periodStart).toBe('2026-07-10T20:15:00.000Z');
    expect(dto.periodEnd).toBe('2026-07-11T03:02:00.000Z');
    expect(dto.totalSales).toBe(19050);
    expect(dto.completedTransactions).toBe(42);
    expect(dto.voidedTransactions).toBe(1);
    expect(dto.totalTransactions).toBe(43);
    expect(dto.refundedTransactions).toBe(1);
    expect(dto.cashCollected).toBe(19050);
  });

  it('defaults every value and nulls the period when queries return nothing', () => {
    const dto = CashierXReadingReportMapper.toDto(
      makeRaw({
        paymentRows: [],
        paymentLedgerRows: [],
        discountRows: [],
        salesTotals: undefined,
        voided: undefined,
        refunded: undefined,
        tax: undefined,
        vatExempt: undefined,
        quantity: undefined,
      }),
    );

    expect(dto.periodStart).toBeNull();
    expect(dto.periodEnd).toBeNull();
    expect(dto.totalSales).toBe(0);
    expect(dto.completedTransactions).toBe(0);
    expect(dto.voidedTransactions).toBe(0);
    expect(dto.totalTransactions).toBe(0);
    expect(dto.cashCollected).toBe(0);
  });
});
```

- [ ] **Step 5: Run the new spec and confirm it passes**

```bash
cd be
npx jest --testPathPattern=src/reports/mapper/cashier-x-reading-report.mapper.spec.ts
```
Expected: `Tests: 2 passed, 2 total`.

- [ ] **Step 6: Type-check**

```bash
cd be
npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add be/src/reports/dto/cashier-x-reading-response.dto.ts be/src/reports/mapper/cashier-x-reading-report.mapper.ts be/src/reports/mapper/cashier-x-reading-report.mapper.spec.ts
git commit -m "feat(reports): replace cashier X-reading businessDate with periodStart/periodEnd"
```

---

### Task 7: Backend — dev script to simulate a cross-midnight shift

**Files:**
- Create: `be/scripts/seed-late-night-shift-transactions.ts`

- [ ] **Step 1: Write the script**

This mirrors the existing `be/scripts/seed-today-transactions.ts` (raw `DataSource` + raw SQL inserts) but generates transactions for a single cashier spanning a shift that crosses midnight, and is safe to re-run (deletes only its own previously-seeded rows, identified by a dedicated `so_number` prefix — not by date, since this script deliberately spans two calendar days and must not touch unrelated same-day data).

Create `be/scripts/seed-late-night-shift-transactions.ts`:

```ts
import { DataSource } from 'typeorm';
import { uuidv7 } from 'uuidv7';
import { typeOrmConfig } from '../src/database/config/typeorm.config';
import { entities } from '../src/database/entities-index';

const TAX_RATE = 0.12;

const CASHIER_ID = 3; // cashier1
const KIOSK_PREFIX = 'SO-LATE-2026-';
const ORDERS_BEFORE_MIDNIGHT = 6;
const ORDERS_AFTER_MIDNIGHT = 6;

type Variant = { id: number; product_name: string; variant_name: string; price: string; recipe_id: number | null };

function randInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick<T>(arr: T[]): T {
  return arr[randInt(0, arr.length - 1)];
}

function randomReference(length: number): string {
  let ref = '';
  for (let i = 0; i < length; i++) ref += randInt(0, 9);
  return ref;
}

function round(n: number): number {
  return Math.round(n * 1e6) / 1e6;
}

async function main() {
  const ds = new DataSource({ ...typeOrmConfig, entities, migrations: [], logging: false });
  await ds.initialize();

  const variants: Variant[] = await ds.query(`
    select pv.id, p.name as product_name, pv.name as variant_name, pv.price, pv.status,
           (select r.id from recipes r where r.product_variant_id = pv.id limit 1) as recipe_id
    from product_variants pv
    join products p on pv.product_id = p.id
    where pv.status = 'Active' and p.status = 'Active'
  `);
  const menuVariants = variants.filter((v) => v.recipe_id !== null);

  const [{ today, yesterday }] = await ds.query(`
    select to_char(CURRENT_DATE, 'YYYY-MM-DD') as today,
           to_char(CURRENT_DATE - INTERVAL '1 day', 'YYYY-MM-DD') as yesterday
  `);

  console.log(`Deleting previously-seeded late-night-shift transactions (prefix ${KIOSK_PREFIX})...`);
  await ds.query(`
    update inventory_counts set sales_order_id = null
    where sales_order_id in (select id from sales_orders where so_number like $1 || '%')
  `, [KIOSK_PREFIX]);
  await ds.query(`delete from payments where sales_order_id in (select id from sales_orders where so_number like $1 || '%')`, [KIOSK_PREFIX]);
  await ds.query(`delete from so_items where so_id in (select id from sales_orders where so_number like $1 || '%')`, [KIOSK_PREFIX]);
  await ds.query(`delete from so_discounts where sales_order_id in (select id from sales_orders where so_number like $1 || '%')`, [KIOSK_PREFIX]);
  const deleted = await ds.query(`delete from sales_orders where so_number like $1 || '%' returning id`, [KIOSK_PREFIX]);
  console.log(`Deleted ${deleted.length} previously-seeded sales orders.`);

  type PlannedOrder = { soDate: string };
  const planned: PlannedOrder[] = [];
  const pad = (n: number) => String(n).padStart(2, '0');

  for (let i = 0; i < ORDERS_BEFORE_MIDNIGHT; i++) {
    const timeOfDay = `${pad(randInt(20, 23))}:${pad(randInt(0, 59))}:${pad(randInt(0, 59))}`;
    planned.push({ soDate: `${yesterday} ${timeOfDay}` });
  }
  for (let i = 0; i < ORDERS_AFTER_MIDNIGHT; i++) {
    const timeOfDay = `${pad(randInt(0, 3))}:${pad(randInt(0, 59))}:${pad(randInt(0, 59))}`;
    planned.push({ soDate: `${today} ${timeOfDay}` });
  }
  planned.sort((a, b) => a.soDate.localeCompare(b.soDate));

  console.log(`Creating ${planned.length} transactions for cashier ${CASHIER_ID} spanning ${yesterday} 8PM - ${today} 4AM...`);

  for (let seq = 0; seq < planned.length; seq++) {
    const order = planned[seq];
    const soNumber = `${KIOSK_PREFIX}${String(seq + 1).padStart(4, '0')}`;
    const soId = uuidv7();

    const itemCount = randInt(2, 3);
    const chosenVariants: Variant[] = [];
    for (let i = 0; i < itemCount; i++) chosenVariants.push(pick(menuVariants));

    let orderSubtotal = 0;
    let orderTax = 0;
    const itemRows: any[] = [];

    chosenVariants.forEach((variant, idx) => {
      const qty = randInt(1, 2);
      const unitPrice = Number(variant.price);
      const vatExclusiveAmount = round((qty * unitPrice) / (1 + TAX_RATE));
      const vatAmount = round(vatExclusiveAmount * TAX_RATE);
      const itemTotalAmount = round(vatExclusiveAmount + vatAmount);
      orderSubtotal = round(orderSubtotal + vatExclusiveAmount);
      orderTax = round(orderTax + vatAmount);

      itemRows.push({
        id: uuidv7(),
        itemSequence: idx + 1,
        productVariantId: variant.id,
        recipeId: variant.recipe_id,
        description: `${variant.variant_name} ${variant.product_name}`,
        qty,
        unitPrice,
        vatExclusiveAmount,
        vatAmount,
        itemSubtotal: vatExclusiveAmount,
        itemTotalAmount,
      });
    });

    const finalTotalAmount = round(orderSubtotal + orderTax);

    await ds.query(
      `insert into sales_orders (
        id, so_number, so_date, so_type, status, discount_rate, discount_amount, tax_rate, tax_amount,
        total_amount, final_total_amount, created_at, updated_at, created_by, updated_by
      ) values ($1,$2,$3,'Dine-In','Confirmed',0,0,0,0,$4,$5,$3,$3,$6,$6)`,
      [soId, soNumber, order.soDate, orderSubtotal, finalTotalAmount, CASHIER_ID],
    );

    for (const item of itemRows) {
      await ds.query(
        `insert into so_items (
          id, so_id, item_sequence, product_variant_id, recipe_id, description, qty, unit_price,
          item_discount_rate, item_discounted_price, vat_exclusive_amount, vat_amount, item_subtotal,
          item_total_amount, item_paid_amount, status, created_at, updated_at, created_by, updated_by
        ) values ($1,$2,$3,$4,$5,$6,$7,$8,0,null,$9,$10,$11,$12,$12,'Completed',$13,$13,$14,$14)`,
        [
          item.id,
          soId,
          item.itemSequence,
          item.productVariantId,
          item.recipeId,
          item.description,
          item.qty,
          item.unitPrice,
          item.vatExclusiveAmount,
          item.vatAmount,
          item.itemSubtotal,
          item.itemTotalAmount,
          order.soDate,
          CASHIER_ID,
        ],
      );
    }

    const tendered = Math.ceil(finalTotalAmount / 50) * 50 + pick([0, 20, 50]);
    const change = round(tendered - finalTotalAmount);

    await ds.query(
      `insert into payments (
        id, sales_order_id, amount_paid, change, payment_method, payment_method_name, payment_date, transaction_reference
      ) values ($1,$2,$3,$4,'Cash',null,$5,$6)`,
      [uuidv7(), soId, tendered, change, order.soDate, randomReference(13)],
    );
  }

  console.log(`Done. ${planned.length} transactions created for cashier_id ${CASHIER_ID}.`);
  console.log(`Earliest: ${planned[0].soDate}  Latest: ${planned[planned.length - 1].soDate}`);

  await ds.destroy();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

- [ ] **Step 2: Run it against a local dev database**

Requires local Postgres running with seeded products/recipes (see `npm run seed:run`). Run:
```bash
cd be
npx ts-node -T scripts/seed-late-night-shift-transactions.ts
```
Expected: log output ending with `Done. 12 transactions created for cashier_id 3.` followed by an `Earliest:`/`Latest:` line showing one date at 20:xx-23:xx and the next calendar day at 00:xx-03:xx.

- [ ] **Step 3: Commit**

```bash
git add be/scripts/seed-late-night-shift-transactions.ts
git commit -m "chore(scripts): add dev script to simulate a cross-midnight cashier shift"
```

---

### Task 8: Kiosk — Cashier Daily Report schema/entity/mapper + test

**Files:**
- Modify: `kiosk/lib/data/backend_api/schemas/cashier_daily_report_dto.dart`
- Modify: `kiosk/lib/features/cashier_report/entities/cashier_daily_report.dart`
- Modify: `kiosk/lib/features/cashier_report/mappers/cashier_daily_report_mappers.dart`
- Modify: `kiosk/test/features/cashier_report/state/cashier_daily_report_notifier_test.dart`

- [ ] **Step 1: Update the DTO schema**

In `cashier_daily_report_dto.dart`, find:

```dart
  const CashierDailyReportDto({
    required this.cashierName,
    required this.terminalName,
    required this.businessDate,
    required this.reportGeneratedAt,
```

Replace with:

```dart
  const CashierDailyReportDto({
    required this.cashierName,
    required this.terminalName,
    required this.periodStart,
    required this.periodEnd,
    required this.reportGeneratedAt,
```

Then find:

```dart
  final String cashierName;
  final String terminalName;
  final String businessDate;
  final String reportGeneratedAt;
```

Replace with:

```dart
  final String cashierName;
  final String terminalName;
  final String? periodStart;
  final String? periodEnd;
  final String reportGeneratedAt;
```

- [ ] **Step 2: Update the entity**

In `features/cashier_report/entities/cashier_daily_report.dart`, find:

```dart
  const CashierDailyReport({
    required this.cashierName,
    required this.terminalName,
    required this.businessDate,
    required this.reportGeneratedAt,
```

Replace with:

```dart
  const CashierDailyReport({
    required this.cashierName,
    required this.terminalName,
    required this.periodStart,
    required this.periodEnd,
    required this.reportGeneratedAt,
```

Then find:

```dart
  final String cashierName;
  final String terminalName;
  final String businessDate;
  final DateTime reportGeneratedAt;
```

Replace with:

```dart
  final String cashierName;
  final String terminalName;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime reportGeneratedAt;
```

- [ ] **Step 3: Update the mapper**

In `features/cashier_report/mappers/cashier_daily_report_mappers.dart`, find:

```dart
extension CashierDailyReportDTOMapper on CashierDailyReportDto {
  CashierDailyReport get toEntity => CashierDailyReport(
    cashierName: cashierName,
    terminalName: terminalName,
    businessDate: businessDate,
    reportGeneratedAt: DateTime.parse(reportGeneratedAt),
```

Replace with:

```dart
extension CashierDailyReportDTOMapper on CashierDailyReportDto {
  CashierDailyReport get toEntity => CashierDailyReport(
    cashierName: cashierName,
    terminalName: terminalName,
    periodStart: periodStart != null ? DateTime.parse(periodStart!) : null,
    periodEnd: periodEnd != null ? DateTime.parse(periodEnd!) : null,
    reportGeneratedAt: DateTime.parse(reportGeneratedAt),
```

- [ ] **Step 4: Fix the notifier test fixture**

In `kiosk/test/features/cashier_report/state/cashier_daily_report_notifier_test.dart`, find:

```dart
  businessDate: '07/10/2026',
```

Replace with:

```dart
  periodStart: DateTime(2026, 7, 10, 20, 15),
  periodEnd: DateTime(2026, 7, 11, 3, 2),
```

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/data/backend_api/schemas/cashier_daily_report_dto.dart kiosk/lib/features/cashier_report/entities/cashier_daily_report.dart kiosk/lib/features/cashier_report/mappers/cashier_daily_report_mappers.dart kiosk/test/features/cashier_report/state/cashier_daily_report_notifier_test.dart
git commit -m "feat(kiosk): replace cashier daily report businessDate with periodStart/periodEnd"
```

(Code generation and test execution happen together for both reports in Task 13, since `dart_mappable` build_runner regenerates both `.mapper.dart` files in one pass.)

---

### Task 9: Kiosk — Cashier X-Reading schema/entity/mapper + test

**Files:**
- Modify: `kiosk/lib/data/backend_api/schemas/cashier_x_reading_dto.dart`
- Modify: `kiosk/lib/features/cashier_report/entities/cashier_x_reading.dart`
- Modify: `kiosk/lib/features/cashier_report/mappers/cashier_x_reading_mappers.dart`
- Modify: `kiosk/test/features/cashier_report/state/cashier_x_reading_notifier_test.dart`

- [ ] **Step 1: Update the DTO schema**

In `cashier_x_reading_dto.dart`, find:

```dart
  const CashierXReadingDto({
    required this.cashierName,
    required this.terminalName,
    required this.businessDate,
    required this.reportGeneratedAt,
```

Replace with:

```dart
  const CashierXReadingDto({
    required this.cashierName,
    required this.terminalName,
    required this.periodStart,
    required this.periodEnd,
    required this.reportGeneratedAt,
```

Then find:

```dart
  final String cashierName;
  final String terminalName;
  final String businessDate;
  final String reportGeneratedAt;
```

Replace with:

```dart
  final String cashierName;
  final String terminalName;
  final String? periodStart;
  final String? periodEnd;
  final String reportGeneratedAt;
```

- [ ] **Step 2: Update the entity**

In `features/cashier_report/entities/cashier_x_reading.dart`, find:

```dart
  const CashierXReading({
    required this.cashierName,
    required this.terminalName,
    required this.businessDate,
    required this.reportGeneratedAt,
```

Replace with:

```dart
  const CashierXReading({
    required this.cashierName,
    required this.terminalName,
    required this.periodStart,
    required this.periodEnd,
    required this.reportGeneratedAt,
```

Then find:

```dart
  final String cashierName;
  final String terminalName;
  final String businessDate;
  final DateTime reportGeneratedAt;
```

Replace with:

```dart
  final String cashierName;
  final String terminalName;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime reportGeneratedAt;
```

- [ ] **Step 3: Update the mapper**

In `features/cashier_report/mappers/cashier_x_reading_mappers.dart`, find:

```dart
extension CashierXReadingDTOMapper on CashierXReadingDto {
  CashierXReading get toEntity => CashierXReading(
    cashierName: cashierName,
    terminalName: terminalName,
    businessDate: businessDate,
    reportGeneratedAt: DateTime.parse(reportGeneratedAt),
```

Replace with:

```dart
extension CashierXReadingDTOMapper on CashierXReadingDto {
  CashierXReading get toEntity => CashierXReading(
    cashierName: cashierName,
    terminalName: terminalName,
    periodStart: periodStart != null ? DateTime.parse(periodStart!) : null,
    periodEnd: periodEnd != null ? DateTime.parse(periodEnd!) : null,
    reportGeneratedAt: DateTime.parse(reportGeneratedAt),
```

- [ ] **Step 4: Fix the notifier test fixture**

In `kiosk/test/features/cashier_report/state/cashier_x_reading_notifier_test.dart`, find:

```dart
  businessDate: '07/09/2026',
```

Replace with:

```dart
  periodStart: DateTime(2026, 7, 9, 8, 0),
  periodEnd: DateTime(2026, 7, 9, 14, 0),
```

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/data/backend_api/schemas/cashier_x_reading_dto.dart kiosk/lib/features/cashier_report/entities/cashier_x_reading.dart kiosk/lib/features/cashier_report/mappers/cashier_x_reading_mappers.dart kiosk/test/features/cashier_report/state/cashier_x_reading_notifier_test.dart
git commit -m "feat(kiosk): replace cashier X-reading businessDate with periodStart/periodEnd"
```

---

### Task 10: Kiosk — shared Period widget and formatter

**Files:**
- Modify: `kiosk/lib/features/cashier_report/view/report_preview_widgets.dart`

- [ ] **Step 1: Add the `intl` import**

Find the import block at the top of the file:

```dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
```

Replace with:

```dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
```

- [ ] **Step 2: Add the formatter function and `ReportPeriodRow` widget**

Find the end of the `ReportKeyValueRow` class (right before the `/// Label/value row where the value is a peso-formatted amount.` comment that starts `ReportAmountRow`):

```dart
/// Label/value row where the value is a peso-formatted amount.
class ReportAmountRow extends StatelessWidget {
```

Replace with:

```dart
const noReportTransactionsYetText = 'No transactions yet';

/// Formats the earliest/latest transaction covered by a report as a single range string,
/// or a placeholder when the cashier has no unreported transactions yet.
String formatReportPeriod(DateTime? periodStart, DateTime? periodEnd) {
  if (periodStart == null || periodEnd == null) return noReportTransactionsYetText;
  final format = DateFormat.yMd().add_jm();
  return '${format.format(periodStart.toLocal())} - ${format.format(periodEnd.toLocal())}';
}

/// Label-above-value row for the report's covered-transaction period, which can be long
/// enough (spanning two calendar days) to overflow a side-by-side [ReportKeyValueRow].
class ReportPeriodRow extends StatelessWidget {
  const ReportPeriodRow(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final labelStyle = TextStyle(fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12));
    final valueStyle = labelStyle.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('Period', style: labelStyle), Text(value, style: valueStyle)],
      ),
    );
  }
}

/// Label/value row where the value is a peso-formatted amount.
class ReportAmountRow extends StatelessWidget {
```

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/cashier_report/view/report_preview_widgets.dart
git commit -m "feat(kiosk): add ReportPeriodRow and formatReportPeriod for cashier report previews"
```

---

### Task 11: Kiosk — wire the Period row into both preview screens

**Files:**
- Modify: `kiosk/lib/features/cashier_report/view/cashier_report_preview_screen.dart`
- Modify: `kiosk/lib/features/cashier_report/view/cashier_daily_report_screen.dart`

- [ ] **Step 1: X-Reading preview screen**

In `cashier_report_preview_screen.dart`, find:

```dart
              ReportKeyValueRow('Cashier', report.cashierName),
              ReportKeyValueRow('Business Date', report.businessDate),
              ReportKeyValueRow(
```

Replace with:

```dart
              ReportKeyValueRow('Cashier', report.cashierName),
              ReportPeriodRow(formatReportPeriod(report.periodStart, report.periodEnd)),
              ReportKeyValueRow(
```

- [ ] **Step 2: Cashier Daily Report preview screen**

In `cashier_daily_report_screen.dart`, find:

```dart
              ReportKeyValueRow('Terminal', report.terminalName),
              ReportKeyValueRow('Cashier', report.cashierName),
              ReportKeyValueRow('Business Date', report.businessDate),
              ReportKeyValueRow(
```

Replace with:

```dart
              ReportKeyValueRow('Terminal', report.terminalName),
              ReportKeyValueRow('Cashier', report.cashierName),
              ReportPeriodRow(formatReportPeriod(report.periodStart, report.periodEnd)),
              ReportKeyValueRow(
```

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/cashier_report/view/cashier_report_preview_screen.dart kiosk/lib/features/cashier_report/view/cashier_daily_report_screen.dart
git commit -m "feat(kiosk): show transaction period on cashier report preview screens"
```

---

### Task 12: Kiosk — wire the Period line into both ESC/POS receipts

**Files:**
- Modify: `kiosk/lib/features/cashier_report/use_cases/encode_esc_pos_cashier_report.dart`
- Modify: `kiosk/lib/features/cashier_report/use_cases/encode_esc_pos_cashier_daily_report.dart`

- [ ] **Step 1: X-Reading receipt**

In `encode_esc_pos_cashier_report.dart`, find:

```dart
      bytes += generator.text(
        'Business Date: ${report.businessDate}',
        styles: const PosStyles(align: PosAlign.left),
      );
```

Replace with:

```dart
      bytes += generator.text(
        'Period: ${_periodLabel(report.periodStart, report.periodEnd)}',
        styles: const PosStyles(align: PosAlign.left),
      );
```

Then add this private method to the `EncodeEscPosCashierReport` class, right after `_countRow`:

```dart
  String _periodLabel(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'No transactions yet';
    final format = DateFormat.yMd().add_jm();
    return '${format.format(start.toLocal())} - ${format.format(end.toLocal())}'
        .replaceAll(RegExp(r'\s'), ' ');
  }
```

- [ ] **Step 2: Cashier Daily Report receipt**

In `encode_esc_pos_cashier_daily_report.dart`, find:

```dart
      bytes += generator.row([
        PosColumn(text: report.terminalName, width: 6),
        PosColumn(text: report.businessDate, width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'CASHIER REPORT', width: 6),
        PosColumn(
          text: report.cashierName,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.text(
        'Generated: ${DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal()).replaceAll(RegExp(r'\s'), ' ')}',
      );
```

Replace with:

```dart
      bytes += generator.text(report.terminalName);
      bytes += generator.row([
        PosColumn(text: 'CASHIER REPORT', width: 6),
        PosColumn(
          text: report.cashierName,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.text('Period: ${_periodLabel(report.periodStart, report.periodEnd)}');
      bytes += generator.text(
        'Generated: ${DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal()).replaceAll(RegExp(r'\s'), ' ')}',
      );
```

Then add this private method to the `EncodeEscPosCashierDailyReport` class, right after `_countRow`:

```dart
  String _periodLabel(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'No transactions yet';
    final format = DateFormat.yMd().add_jm();
    return '${format.format(start.toLocal())} - ${format.format(end.toLocal())}'
        .replaceAll(RegExp(r'\s'), ' ');
  }
```

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/cashier_report/use_cases/encode_esc_pos_cashier_report.dart kiosk/lib/features/cashier_report/use_cases/encode_esc_pos_cashier_daily_report.dart
git commit -m "feat(kiosk): print transaction period on cashier report receipts"
```

---

### Task 13: Kiosk — regenerate code and verify

**Files:** none new — regenerates `.mapper.dart` files for the 4 touched `@MappableClass` files.

- [ ] **Step 1: Regenerate dart_mappable code**

```bash
cd kiosk
fvm dart run build_runner build --delete-conflicting-outputs
```
Expected: build succeeds and reports the 4 affected `.mapper.dart` files (for `cashier_daily_report_dto.dart`, `cashier_x_reading_dto.dart`, `cashier_daily_report.dart`, `cashier_x_reading.dart`) as regenerated, with no errors.

- [ ] **Step 2: Static analysis**

```bash
cd kiosk
fvm dart analyze
```
Expected: `No issues found!` (or only pre-existing issues unrelated to these files).

- [ ] **Step 3: Run the two notifier tests**

```bash
cd kiosk
fvm flutter test test/features/cashier_report/state/cashier_x_reading_notifier_test.dart test/features/cashier_report/state/cashier_daily_report_notifier_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 4: Commit the generated files**

```bash
git add kiosk/lib/data/backend_api/schemas/cashier_daily_report_dto.mapper.dart kiosk/lib/data/backend_api/schemas/cashier_x_reading_dto.mapper.dart kiosk/lib/features/cashier_report/entities/cashier_daily_report.mapper.dart kiosk/lib/features/cashier_report/entities/cashier_x_reading.mapper.dart
git commit -m "chore(kiosk): regenerate mapper code for cashier report period fields"
```

---

### Task 14: End-to-end manual verification

**Files:** none — verification only.

- [ ] **Step 1: Start the backend against local Postgres**

```bash
cd be
npm run start:dev
```
Expected: server starts on `http://localhost:3000`, logs show no errors connecting to Postgres.

- [ ] **Step 2: Seed a cross-midnight shift**

```bash
cd be
npx ts-node -T scripts/seed-late-night-shift-transactions.ts
```
Expected: as in Task 7 Step 2 — 12 transactions created for cashier_id 3, spanning two calendar days.

- [ ] **Step 3: Hit both report endpoints as that cashier**

Log in as cashier_id 3 via `POST /api/v1/auth/login` to get a JWT, then:
```bash
curl -H "Authorization: Bearer <token>" http://localhost:3000/api/v1/reports/cashier-x-reading
curl -H "Authorization: Bearer <token>" http://localhost:3000/api/v1/reports/cashier-daily-report
```
Expected: both responses include all 12 seeded transactions in their totals (`completedTransactions`/`transactionCount` reflects 12, or 12 plus any other pre-existing unreported transactions for that cashier), and `periodStart`/`periodEnd` reflect the earliest (yesterday ~8-11PM) and latest (today ~12-3AM) seeded `so_date` values — confirming no transactions were dropped across the midnight boundary.

- [ ] **Step 4: Confirm in the kiosk UI**

```bash
cd kiosk
fvm flutter run -d windows
```
Log in as cashier1 (cashier_id 3), open both the X-Reading and Cashier Daily Report screens from the Transactions screen. Expected: both previews render a "Period" row showing a date/time range spanning two different calendar dates (e.g. `7/9/2026 8:42 PM - 7/10/2026 2:17 AM`), and printing (if a printer is configured) shows the same range on the receipt in place of the old "Business Date" line.

- [ ] **Step 5: Report results**

No commit for this task — it's verification only. If any step fails, return to the relevant earlier task and fix before considering the plan complete.
