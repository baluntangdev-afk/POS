# Daily Sales XLSX Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `done_export` tracking to sales orders, auto-export a 6-sheet XLSX to Downloads every midnight, and block Reports screen access until yesterday's unexported transactions have been exported.

**Architecture:** Backend adds a boolean `done_export` column to `sales_orders`, one service (`ExportableReportService`) that aggregates unexported data and marks them exported, and two new endpoints. Flutter adds an `excel`-based export service, a midnight scheduler, a blocking modal on Reports navigation, and an export button in the TopAppBar.

**Tech Stack:** NestJS + TypeORM + PostgreSQL (backend) · Flutter + Riverpod + Hooks + `excel ^4.0.6` (kiosk)

---

## File Map

### Backend — new files
| File | Purpose |
|---|---|
| `be/src/database/migrations/1779584000000-sales-orders-done-export.ts` | Adds `done_export` column |
| `be/src/reports/dto/exportable-date-query.dto.ts` | Query DTO for `GET /exportable` |
| `be/src/reports/dto/mark-exported-body.dto.ts` | Body DTO for `PATCH /mark-exported` |
| `be/src/reports/dto/exportable-report-response.dto.ts` | Response DTO for exportable endpoint |
| `be/src/reports/services/exportable-report.service.ts` | Aggregates unexported data + marks exported |

### Backend — modified files
| File | Change |
|---|---|
| `be/src/database/migrations/index.ts` | Register new migration |
| `be/src/sales-orders/entities/sales-order.entity.ts` | Add `doneExport` column |
| `be/src/reports/reports.controller.ts` | Add 2 endpoints |
| `be/src/reports/reports.module.ts` | Register `ExportableReportService` |

### Flutter — new files
| File | Purpose |
|---|---|
| `kiosk/lib/data/backend_api/schemas/exportable_report_dto.dart` | Dart DTO for the exportable response |
| `kiosk/lib/features/reports/entities/exportable_report.dart` | Domain entity |
| `kiosk/lib/features/reports/mappers/exportable_report_mappers.dart` | DTO → entity mapper |
| `kiosk/lib/features/reports/state/export_notifier.dart` | `ExportState` + `ExportNotifier` |
| `kiosk/lib/features/reports/services/report_export_service.dart` | XLSX build + save + mark-exported |
| `kiosk/lib/features/reports/services/daily_export_scheduler.dart` | Midnight timer + startup catch-up |
| `kiosk/lib/features/reports/view/unexported_export_dialog.dart` | Blocking modal |

### Flutter — modified files
| File | Change |
|---|---|
| `kiosk/pubspec.yaml` | Add `excel: ^4.0.6` |
| `kiosk/lib/data/backend_api/sources/reports_api.dart` | Add `getExportable` + `markExported` |
| `kiosk/lib/features/reports/repositories/reports_repository.dart` | Add abstract + impl methods |
| `kiosk/lib/features/reports/view/sales_report_screen.dart` | Add export button + unexported check |
| `kiosk/lib/app.dart` | Initialize scheduler on app start |

---

## Task 1 — BE: Migration + Entity

**Files:**
- Create: `be/src/database/migrations/1779584000000-sales-orders-done-export.ts`
- Modify: `be/src/database/migrations/index.ts`
- Modify: `be/src/sales-orders/entities/sales-order.entity.ts`

- [ ] **Step 1: Create migration file**

```typescript
// be/src/database/migrations/1779584000000-sales-orders-done-export.ts
import { MigrationInterface, QueryRunner } from 'typeorm';

export class SalesOrdersDoneExport1779584000000 implements MigrationInterface {
  name = 'SalesOrdersDoneExport1779584000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD COLUMN "done_export" boolean NOT NULL DEFAULT false`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "sales_orders" DROP COLUMN "done_export"`);
  }
}
```

- [ ] **Step 2: Register migration in index**

Replace the last line of `be/src/database/migrations/index.ts`:

```typescript
import type { MigrationInterface } from 'typeorm';
import { TestInit1770175003018 } from './1770175003018-test-init';
import { UsersRole1779583700000 } from './1779583700000-users-role';
import { SalesOrdersVoidFields1779583800000 } from './1779583800000-sales-orders-void-fields';
import { SalesOrdersDoneExport1779584000000 } from './1779584000000-sales-orders-done-export';

export const migrations: Array<new () => MigrationInterface> = [
  TestInit1770175003018,
  UsersRole1779583700000,
  SalesOrdersVoidFields1779583800000,
  SalesOrdersDoneExport1779584000000,
];
```

- [ ] **Step 3: Add `doneExport` column to entity**

In `be/src/sales-orders/entities/sales-order.entity.ts`, add after the `voidedAt` column (line ~169):

```typescript
  @Column({ name: 'done_export', type: 'boolean', default: false })
  doneExport: boolean;
```

- [ ] **Step 4: Run migration**

```bash
cd be
npm run migration:up
```

Expected: `query: ALTER TABLE "sales_orders" ADD COLUMN "done_export" boolean NOT NULL DEFAULT false`

- [ ] **Step 5: Commit**

```bash
git add be/src/database/migrations/1779584000000-sales-orders-done-export.ts \
        be/src/database/migrations/index.ts \
        be/src/sales-orders/entities/sales-order.entity.ts
git commit -m "feat(be): add done_export column to sales_orders"
```

---

## Task 2 — BE: DTOs

**Files:**
- Create: `be/src/reports/dto/exportable-date-query.dto.ts`
- Create: `be/src/reports/dto/mark-exported-body.dto.ts`
- Create: `be/src/reports/dto/exportable-report-response.dto.ts`

- [ ] **Step 1: Create `ExportableDateQueryDto`**

```typescript
// be/src/reports/dto/exportable-date-query.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsDateString } from 'class-validator';

export class ExportableDateQueryDto {
  @ApiProperty({ description: 'Date to check (YYYY-MM-DD)', example: '2026-06-02' })
  @IsDateString()
  date: string;
}
```

- [ ] **Step 2: Create `MarkExportedBodyDto`**

```typescript
// be/src/reports/dto/mark-exported-body.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsDateString } from 'class-validator';

export class MarkExportedBodyDto {
  @ApiProperty({ description: 'Date to mark as exported (YYYY-MM-DD)', example: '2026-06-02' })
  @IsDateString()
  date: string;
}
```

- [ ] **Step 3: Create `ExportableReportResponseDto`**

```typescript
// be/src/reports/dto/exportable-report-response.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { SalesResponseDto } from './sales-response.dto';
import { HourlySalesDataItemDto } from './hourly-sales-response.dto';
import { ProductSalesDataItemDto } from './product-sales-response.dto';
import { ProductGroupSalesDataItemDto } from './product-group-sales-response.dto';
import { PaymentMethodSalesDataItemDto } from './payment-sales-response.dto';
import { UserSalesDataItemDto } from './user-sales-response.dto';

export class ExportableReportResponseDto {
  @ApiProperty({ example: '2026-06-02' })
  date: string;

  @ApiProperty({ example: 45 })
  count: number;

  @ApiProperty({ type: SalesResponseDto })
  summary: SalesResponseDto;

  @ApiProperty({ type: HourlySalesDataItemDto, isArray: true })
  hourlyBreakdown: HourlySalesDataItemDto[];

  @ApiProperty({ type: ProductSalesDataItemDto, isArray: true })
  byProduct: ProductSalesDataItemDto[];

  @ApiProperty({ type: ProductGroupSalesDataItemDto, isArray: true })
  byProductGroup: ProductGroupSalesDataItemDto[];

  @ApiProperty({ type: PaymentMethodSalesDataItemDto, isArray: true })
  byPayment: PaymentMethodSalesDataItemDto[];

  @ApiProperty({ type: UserSalesDataItemDto, isArray: true })
  byCashier: UserSalesDataItemDto[];
}
```

- [ ] **Step 4: Commit**

```bash
git add be/src/reports/dto/exportable-date-query.dto.ts \
        be/src/reports/dto/mark-exported-body.dto.ts \
        be/src/reports/dto/exportable-report-response.dto.ts
git commit -m "feat(be): add DTOs for exportable report endpoints"
```

---

## Task 3 — BE: `ExportableReportService`

**Files:**
- Create: `be/src/reports/services/exportable-report.service.ts`

- [ ] **Step 1: Create the service**

```typescript
// be/src/reports/services/exportable-report.service.ts
import dayjs from 'dayjs';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { Payment } from '../../payments/entities/payment.entity';
import { SalesOrderStatus } from '../../sales-orders/sales-orders.enum';
import { STATUS_FILTER } from '../reports.constants';
import { SalesReportMapper } from '../mapper/sales-report.mapper';
import { toHourlySalesDataItemDto } from '../mapper/hourly-sales-report.mapper';
import { toProductSalesItemDto } from '../mapper/product-sales-report.mapper';
import { toProductGroupSalesItemDto } from '../mapper/product-group-sales-report.mapper';
import { toPaymentMethodSalesItemDto } from '../mapper/payment-sales-report.mapper';
import { toUserSalesItemDto } from '../mapper/user-sales-report.mapper';
import { ExportableReportResponseDto } from '../dto/exportable-report-response.dto';
import { SalesResponseDto } from '../dto/sales-response.dto';
import { HourlySalesDataItemDto } from '../dto/hourly-sales-response.dto';
import { ProductSalesDataItemDto } from '../dto/product-sales-response.dto';
import { ProductGroupSalesDataItemDto } from '../dto/product-group-sales-response.dto';
import { PaymentMethodSalesDataItemDto } from '../dto/payment-sales-response.dto';
import { UserSalesDataItemDto } from '../dto/user-sales-response.dto';
import type { SalesByPeriodRawRow, SalesReportRawRow, IdNameTotalSalesRawRow, PaymentMethodSalesRawRow } from '../reports.interface';

const HOUR_KEY_FORMAT = 'YYYY-MM-DDTHH:mm';

@Injectable()
export class ExportableReportService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
  ) {}

  async getExportable(date: string): Promise<ExportableReportResponseDto> {
    const startDate = dayjs(date).startOf('day').toDate();
    const endDate = dayjs(date).endOf('day').toDate();

    const count = await this.salesOrderRepository
      .createQueryBuilder('so')
      .where('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .getCount();

    if (count === 0) {
      return {
        date,
        count: 0,
        summary: SalesReportMapper.toDto(null),
        hourlyBreakdown: [],
        byProduct: [],
        byProductGroup: [],
        byPayment: [],
        byCashier: [],
      };
    }

    const [summary, hourlyBreakdown, byProduct, byProductGroup, byPayment, byCashier] =
      await Promise.all([
        this._getSummary(startDate, endDate),
        this._getHourlyBreakdown(startDate, endDate),
        this._getByProduct(startDate, endDate),
        this._getByProductGroup(startDate, endDate),
        this._getByPayment(startDate, endDate),
        this._getByCashier(startDate, endDate),
      ]);

    return { date, count, summary, hourlyBreakdown, byProduct, byProductGroup, byPayment, byCashier };
  }

  async markExported(date: string): Promise<{ updatedCount: number }> {
    const startDate = dayjs(date).startOf('day').toDate();
    const endDate = dayjs(date).endOf('day').toDate();

    const result = await this.salesOrderRepository
      .createQueryBuilder()
      .update(SalesOrder)
      .set({ doneExport: true })
      .where('done_export = :doneExport', { doneExport: false })
      .andWhere('so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .execute();

    return { updatedCount: result.affected ?? 0 };
  }

  private async _getSummary(startDate: Date, endDate: Date): Promise<SalesResponseDto> {
    const soQb = this.salesOrderRepository
      .createQueryBuilder('so')
      .select('SUM(so.final_total_amount)', 'totalSales')
      .addSelect('SUM(so.discount_amount)', 'totalDiscount')
      .addSelect(
        `SUM(COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'totalRefunds',
      )
      .addSelect('COUNT(so.id)', 'totalTransactions')
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate });

    const soiQb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('COUNT(soi.id)', 'totalItems')
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate });

    const voidedQb = this.salesOrderRepository
      .createQueryBuilder('so')
      .select('COUNT(so.id)', 'totalVoidedTransactions')
      .addSelect('SUM(so.final_total_amount)', 'totalVoidedAmount')
      .andWhere('so.status = :voidedStatus', { voidedStatus: SalesOrderStatus.CANCELLED })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate });

    const [soResult, soiResult, voidedResult] = await Promise.all([
      soQb.getRawOne<SalesReportRawRow>(),
      soiQb.getRawOne<{ totalItems: string }>(),
      voidedQb.getRawOne(),
    ]);

    return SalesReportMapper.toDto({
      ...soResult,
      totalItems: soiResult?.totalItems ?? '0',
      totalVoidedTransactions: voidedResult?.totalVoidedTransactions ?? '0',
      totalVoidedAmount: voidedResult?.totalVoidedAmount ?? '0',
    });
  }

  private async _getHourlyBreakdown(startDate: Date, endDate: Date): Promise<HourlySalesDataItemDto[]> {
    const dateExpr = "date_trunc('hour', so.so_date)";

    const soQb = this.salesOrderRepository
      .createQueryBuilder('so')
      .select(dateExpr, 'date')
      .addSelect('SUM(so.final_total_amount)', 'total')
      .addSelect('COUNT(so.id)', 'transactions')
      .addSelect('SUM(so.discount_amount)', 'discount')
      .where('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .groupBy(dateExpr)
      .orderBy('date', 'ASC');

    const soiQb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select(dateExpr, 'date')
      .addSelect('COUNT(soi.id)', 'items')
      .where('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .groupBy(dateExpr)
      .orderBy('date', 'ASC');

    const [soRows, soiRows] = await Promise.all([
      soQb.getRawMany<SalesByPeriodRawRow>(),
      soiQb.getRawMany<{ date: string | Date; items: string }>(),
    ]);

    const toHourKey = (v: string | Date): string =>
      dayjs(v).isValid() ? dayjs(v).format(HOUR_KEY_FORMAT) : String(v);
    const itemsByHour = new Map<string, string>();
    for (const row of soiRows) {
      itemsByHour.set(toHourKey(row.date), row.items ?? '0');
    }

    return [...soRows]
      .sort((a, b) => dayjs(a.date).valueOf() - dayjs(b.date).valueOf())
      .map((row) =>
        toHourlySalesDataItemDto({ ...row, items: itemsByHour.get(toHourKey(row.date)) ?? '0' }),
      );
  }

  private async _getByProduct(startDate: Date, endDate: Date): Promise<ProductSalesDataItemDto[]> {
    const qb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .innerJoin('soi.productVariant', 'pv')
      .innerJoin('pv.product', 'p')
      .select('p.id', 'id')
      .addSelect('p.name', 'name')
      .addSelect(
        `SUM(soi.item_total_amount - COALESCE((SELECT SUM(ri.refund_amount) FROM refund_items ri WHERE ri.sales_order_item_id = soi.id), 0))`,
        'totalSales',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .groupBy('p.id')
      .addGroupBy('p.name')
      .orderBy('SUM(soi.item_total_amount)', 'DESC');

    const rawRows = await qb.getRawMany<IdNameTotalSalesRawRow>();
    return rawRows.map((row) => toProductSalesItemDto(row));
  }

  private async _getByProductGroup(startDate: Date, endDate: Date): Promise<ProductGroupSalesDataItemDto[]> {
    const qb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .innerJoin('soi.productVariant', 'pv')
      .innerJoin('pv.product', 'p')
      .innerJoin('p.productGroup', 'pg')
      .select('pg.id', 'id')
      .addSelect('pg.name', 'name')
      .addSelect(
        `SUM(soi.item_total_amount - COALESCE((SELECT SUM(ri.refund_amount) FROM refund_items ri WHERE ri.sales_order_item_id = soi.id), 0))`,
        'totalSales',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .groupBy('pg.id')
      .addGroupBy('pg.name')
      .orderBy('SUM(soi.item_total_amount)', 'DESC');

    const rawRows = await qb.getRawMany<IdNameTotalSalesRawRow>();
    return rawRows.map((row) => toProductGroupSalesItemDto(row));
  }

  private async _getByPayment(startDate: Date, endDate: Date): Promise<PaymentMethodSalesDataItemDto[]> {
    const qb = this.paymentRepository
      .createQueryBuilder('p')
      .innerJoin('p.salesOrder', 'so')
      .select('p.payment_method', 'name')
      .addSelect(
        `SUM(so.final_total_amount - COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'totalSales',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .groupBy('p.payment_method')
      .orderBy('SUM(so.final_total_amount)', 'DESC');

    const rawRows = await qb.getRawMany<PaymentMethodSalesRawRow>();
    return rawRows.map((row) => toPaymentMethodSalesItemDto(row));
  }

  private async _getByCashier(startDate: Date, endDate: Date): Promise<UserSalesDataItemDto[]> {
    const qb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .innerJoin('so.createdBy', 'u')
      .select('u.id', 'id')
      .addSelect("u.first_name || ' ' || u.last_name", 'name')
      .addSelect(
        `SUM(soi.item_total_amount - COALESCE((SELECT SUM(ri.refund_amount) FROM refund_items ri WHERE ri.sales_order_item_id = soi.id), 0))`,
        'totalSales',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .groupBy('u.id')
      .addGroupBy('u.first_name')
      .addGroupBy('u.last_name')
      .orderBy('SUM(soi.item_total_amount)', 'DESC');

    const rawRows = await qb.getRawMany<IdNameTotalSalesRawRow>();
    return rawRows.map((row) => toUserSalesItemDto(row));
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add be/src/reports/services/exportable-report.service.ts
git commit -m "feat(be): add ExportableReportService with getExportable and markExported"
```

---

## Task 4 — BE: Controller + Module

**Files:**
- Modify: `be/src/reports/reports.controller.ts`
- Modify: `be/src/reports/reports.module.ts`

- [ ] **Step 1: Add endpoints to controller**

Add imports at top of `be/src/reports/reports.controller.ts`:

```typescript
import { Body, Patch } from '@nestjs/common';
import { ExportableReportService } from './services/exportable-report.service';
import { ExportableDateQueryDto } from './dto/exportable-date-query.dto';
import { MarkExportedBodyDto } from './dto/mark-exported-body.dto';
import { ExportableReportResponseDto } from './dto/exportable-report-response.dto';
```

Add `ExportableReportService` to the constructor:

```typescript
constructor(
  private readonly totalReportService: TotalReportService,
  private readonly hourlySalesReportService: HourlySalesReportService,
  private readonly dailySalesReportService: DailySalesReportService,
  private readonly monthlySalesReportService: MonthlySalesReportService,
  private readonly productGroupSalesReportService: ProductGroupSalesReportService,
  private readonly productSalesReportService: ProductSalesReportService,
  private readonly userSalesReportService: UserSalesReportService,
  private readonly paymentSalesReportService: PaymentSalesReportService,
  private readonly exportableReportService: ExportableReportService,
) {}
```

Add two endpoints after the existing `getPaymentSales` method:

```typescript
  @Get('exportable')
  @ApiOperation({ summary: 'Get aggregated report for unexported transactions on a date' })
  @ApiOkResponse({ type: ExportableReportResponseDto })
  getExportable(@Query() query: ExportableDateQueryDto): Promise<ExportableReportResponseDto> {
    return this.exportableReportService.getExportable(query.date);
  }

  @Patch('mark-exported')
  @ApiOperation({ summary: 'Mark all unexported transactions on a date as exported' })
  @ApiOkResponse({ schema: { example: { updatedCount: 45 } } })
  markExported(@Body() body: MarkExportedBodyDto): Promise<{ updatedCount: number }> {
    return this.exportableReportService.markExported(body.date);
  }
```

- [ ] **Step 2: Register service in module**

In `be/src/reports/reports.module.ts`, add `ExportableReportService` to providers:

```typescript
import { ExportableReportService } from './services/exportable-report.service';

@Module({
  imports: [TypeOrmModule.forFeature([SalesOrder, SalesOrderItem, Payment])],
  controllers: [ReportsController],
  providers: [
    TotalReportService,
    HourlySalesReportService,
    DailySalesReportService,
    MonthlySalesReportService,
    ProductGroupSalesReportService,
    ProductSalesReportService,
    UserSalesReportService,
    PaymentSalesReportService,
    ExportableReportService,
  ],
})
export class ReportsModule {}
```

- [ ] **Step 3: Verify backend compiles**

```bash
cd be
npm run build
```

Expected: Build succeeds with no errors.

- [ ] **Step 4: Commit**

```bash
git add be/src/reports/reports.controller.ts be/src/reports/reports.module.ts
git commit -m "feat(be): add GET /reports/exportable and PATCH /reports/mark-exported endpoints"
```

---

## Task 5 — Flutter: Package + `ExportableReportDto` schema

**Files:**
- Modify: `kiosk/pubspec.yaml`
- Create: `kiosk/lib/data/backend_api/schemas/exportable_report_dto.dart`

- [ ] **Step 1: Add `excel` to pubspec.yaml**

In `kiosk/pubspec.yaml`, add under `dependencies:` (after `fl_chart`):

```yaml
  excel: ^4.0.6
```

- [ ] **Step 2: Run pub get**

```bash
cd kiosk
fvm flutter pub get
```

Expected: `Resolving dependencies... Got dependencies!`

- [ ] **Step 3: Create `ExportableReportDto`**

```dart
// kiosk/lib/data/backend_api/schemas/exportable_report_dto.dart
import 'package:dart_mappable/dart_mappable.dart';

import 'sales_data_item_dto.dart';
import 'sales_report_type_dto.dart';
import 'sales_summary_dto.dart';

part 'exportable_report_dto.mapper.dart';

@MappableClass()
class ExportableReportDto with ExportableReportDtoMappable {
  const ExportableReportDto({
    required this.date,
    required this.count,
    required this.summary,
    required this.hourlyBreakdown,
    required this.byProduct,
    required this.byProductGroup,
    required this.byPayment,
    required this.byCashier,
  });

  final String date;
  final int count;
  final SalesSummaryDto summary;
  final List<SalesReportTypeDto> hourlyBreakdown;
  final List<SalesDataItemDto> byProduct;
  final List<SalesDataItemDto> byProductGroup;
  final List<SalesDataItemDto> byPayment;
  final List<SalesDataItemDto> byCashier;

  static const fromJson = ExportableReportDtoMapper.fromJson;
}
```

- [ ] **Step 4: Run build_runner**

```bash
cd kiosk
fvm dart run build_runner build --delete-conflicting-outputs
```

Expected: `[INFO] Build completed successfully!`  
This generates `exportable_report_dto.mapper.dart`.

- [ ] **Step 5: Commit**

```bash
git add kiosk/pubspec.yaml kiosk/pubspec.lock \
        kiosk/lib/data/backend_api/schemas/exportable_report_dto.dart \
        kiosk/lib/data/backend_api/schemas/exportable_report_dto.mapper.dart
git commit -m "feat(kiosk): add excel package and ExportableReportDto schema"
```

---

## Task 6 — Flutter: API + Entity + Repository

**Files:**
- Create: `kiosk/lib/features/reports/entities/exportable_report.dart`
- Create: `kiosk/lib/features/reports/mappers/exportable_report_mappers.dart`
- Modify: `kiosk/lib/data/backend_api/sources/reports_api.dart`
- Modify: `kiosk/lib/features/reports/repositories/reports_repository.dart`

- [ ] **Step 1: Create `ExportableReport` domain entity**

```dart
// kiosk/lib/features/reports/entities/exportable_report.dart
import 'sales_data_item.dart';
import 'sales_report_type.dart';
import 'sales_summary.dart';

class ExportableReport {
  const ExportableReport({
    required this.date,
    required this.count,
    required this.summary,
    required this.hourlyBreakdown,
    required this.byProduct,
    required this.byProductGroup,
    required this.byPayment,
    required this.byCashier,
  });

  final String date;
  final int count;
  final SalesSummary summary;
  final List<SalesReportType> hourlyBreakdown;
  final List<SalesDataItem> byProduct;
  final List<SalesDataItem> byProductGroup;
  final List<SalesDataItem> byPayment;
  final List<SalesDataItem> byCashier;
}
```

- [ ] **Step 2: Create mapper**

```dart
// kiosk/lib/features/reports/mappers/exportable_report_mappers.dart
import '../../../data/backend_api/schemas/exportable_report_dto.dart';
import '../entities/exportable_report.dart';
import '../enums/sales_data_item_type.dart';
import 'sales_data_item_mappers.dart';
import 'sales_report_type_mappers.dart';
import 'sales_summary_mappers.dart';

extension ExportableReportDTOMapper on ExportableReportDto {
  ExportableReport get toEntity => ExportableReport(
    date: date,
    count: count,
    summary: summary.toEntity,
    hourlyBreakdown: hourlyBreakdown.map((e) => e.toEntity).toList(),
    byProduct: byProduct
        .map((e) => e.toEntity.copyWith(type: SalesDataItemType.product))
        .toList(),
    byProductGroup: byProductGroup
        .map((e) => e.toEntity.copyWith(type: SalesDataItemType.productGroup))
        .toList(),
    byPayment: byPayment
        .map((e) => e.toEntity.copyWith(type: SalesDataItemType.payment))
        .toList(),
    byCashier: byCashier
        .map((e) => e.toEntity.copyWith(type: SalesDataItemType.user))
        .toList(),
  );
}
```

- [ ] **Step 3: Add API methods to `ReportsApi`**

Add the following imports to `kiosk/lib/data/backend_api/sources/reports_api.dart`:

```dart
import '../schemas/exportable_report_dto.dart';
```

Add these two methods at the bottom of the `ReportsApi` class:

```dart
  Future<ExportableReportDto> getExportable({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final date = '${startDate.year.toString().padLeft(4, '0')}'
        '-${startDate.month.toString().padLeft(2, '0')}'
        '-${startDate.day.toString().padLeft(2, '0')}';
    final response = await _httpClient.get<dynamic>(
      '/api/v1/reports/exportable',
      queryParameters: {'date': date},
    );
    return ExportableReportDto.fromJson(jsonEncode(response.data));
  }

  Future<void> markExported({required DateTime date}) async {
    final dateStr = '${date.year.toString().padLeft(4, '0')}'
        '-${date.month.toString().padLeft(2, '0')}'
        '-${date.day.toString().padLeft(2, '0')}';
    await _httpClient.patch<dynamic>(
      '/api/v1/reports/mark-exported',
      data: {'date': dateStr},
    );
  }
```

- [ ] **Step 4: Add repository methods to abstract + impl**

In `kiosk/lib/features/reports/repositories/reports_repository.dart`:

Add import at top:
```dart
import '../entities/exportable_report.dart';
import '../mappers/exportable_report_mappers.dart';
```

Add to abstract class `ReportsRepository`:
```dart
  Future<ExportableReport> getExportable({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> markExported(DateTime date);
```

Add implementations to `ReportsRepositoryImpl`:
```dart
  @override
  Future<ExportableReport> getExportable({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dto = await _reportsApi.getExportable(
      startDate: startDate,
      endDate: endDate,
    );
    return dto.toEntity;
  }

  @override
  Future<void> markExported(DateTime date) async {
    await _reportsApi.markExported(date: date);
  }
```

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/features/reports/entities/exportable_report.dart \
        kiosk/lib/features/reports/mappers/exportable_report_mappers.dart \
        kiosk/lib/data/backend_api/sources/reports_api.dart \
        kiosk/lib/features/reports/repositories/reports_repository.dart
git commit -m "feat(kiosk): add ExportableReport entity, mapper, API and repository methods"
```

---

## Task 7 — Flutter: `ExportState` + `ExportNotifier`

**Files:**
- Create: `kiosk/lib/features/reports/state/export_notifier.dart`

- [ ] **Step 1: Create state + notifier**

```dart
// kiosk/lib/features/reports/state/export_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/report_export_service.dart';

@immutable
class ExportState {
  const ExportState({
    this.isExporting = false,
    this.lastExportPath,
    this.exportError,
  });

  final bool isExporting;
  final String? lastExportPath;
  final String? exportError;

  ExportState copyWith({
    bool? isExporting,
    String? lastExportPath,
    String? exportError,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      lastExportPath: lastExportPath ?? this.lastExportPath,
      exportError: exportError ?? this.exportError,
    );
  }
}

final exportNotifierProvider = NotifierProvider<ExportNotifier, ExportState>(
  ExportNotifier.new,
);

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  Future<bool> export(DateTime date) async {
    state = const ExportState(isExporting: true);
    try {
      final service = ref.read(reportExportServiceProvider);
      final path = await service.exportDay(date);
      state = ExportState(lastExportPath: path);
      return true;
    } catch (e) {
      state = ExportState(exportError: e.toString());
      return false;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add kiosk/lib/features/reports/state/export_notifier.dart
git commit -m "feat(kiosk): add ExportState and ExportNotifier"
```

---

## Task 8 — Flutter: `ReportExportService`

**Files:**
- Create: `kiosk/lib/features/reports/services/report_export_service.dart`

- [ ] **Step 1: Create the XLSX service**

```dart
// kiosk/lib/features/reports/services/report_export_service.dart
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../entities/exportable_report.dart';
import '../entities/sales_data_item.dart';
import '../entities/sales_report_type.dart';
import '../entities/sales_summary.dart';
import '../repositories/reports_repository.dart';

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  return ReportExportService(repository: ref.watch(reportsRepositoryProvider));
});

class ReportExportService {
  const ReportExportService({required ReportsRepository repository})
      : _repository = repository;

  final ReportsRepository _repository;

  Future<String> exportDay(DateTime date) async {
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final data = await _repository.getExportable(
      startDate: startDate,
      endDate: endDate,
    );

    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _buildSummarySheet(excel, data, date);
    _buildHourlySheet(excel, data.hourlyBreakdown);
    _buildGroupedSheet(excel, 'By Product', 'Product', data.byProduct);
    _buildGroupedSheet(excel, 'By Product Group', 'Product Group', data.byProductGroup);
    _buildGroupedSheet(excel, 'By Payment Method', 'Payment Method', data.byPayment);
    _buildGroupedSheet(excel, 'By Cashier', 'Cashier', data.byCashier);

    final dateStr = _formatDate(date);
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    final downloadsPath = '$userProfile\\Downloads';
    final savePath = Directory(downloadsPath).existsSync() ? downloadsPath : '.';
    final filePath = '$savePath\\sales_report_$dateStr.xlsx';

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to encode XLSX');
    await File(filePath).writeAsBytes(bytes);

    await _repository.markExported(date);

    return filePath;
  }

  // ── Sheet builders ──────────────────────────────────────────────────────────

  void _buildSummarySheet(Excel excel, ExportableReport data, DateTime date) {
    final sheet = excel['Summary'];
    final money = NumberFormat('#,##0.00');
    final s = data.summary;
    final netSales = s.totalSales - s.totalDiscount - s.totalRefunds;

    final rows = [
      ['Report Date', DateFormat('MMM d, yyyy').format(date)],
      ['Generated At', DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())],
      ['', ''],
      ['Gross Sales', 'P${money.format(s.totalSales)}'],
      ['Total Discounts', 'P${money.format(s.totalDiscount)}'],
      ['Net Sales', 'P${money.format(netSales)}'],
      ['Total Refunds', 'P${money.format(s.totalRefunds)}'],
      ['Voided Transactions', s.totalVoidedTransactions.toString()],
      ['Voided Amount', 'P${money.format(s.totalVoidedAmount)}'],
      ['Total Transactions', s.totalTransactions.toString()],
      ['Total Items Sold', s.totalItems.toString()],
    ];

    for (final row in rows) {
      sheet.appendRow([TextCellValue(row[0]), TextCellValue(row[1])]);
    }

    sheet.setColWidth(0, 24);
    sheet.setColWidth(1, 20);
  }

  void _buildHourlySheet(Excel excel, List<SalesReportType> rows) {
    final sheet = excel['Hourly Breakdown'];
    final money = NumberFormat('#,##0.00');
    const headers = ['Hour', 'Gross Sales', 'Discounts', 'Transactions', 'Items'];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    _styleHeaderRow(sheet, 0, headers.length);

    double totalSales = 0, totalDiscount = 0;
    int totalTx = 0, totalItems = 0;

    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.hour),
        TextCellValue('P${money.format(row.total)}'),
        TextCellValue('P${money.format(row.discount)}'),
        IntCellValue(row.transactions),
        IntCellValue(row.items),
      ]);
      totalSales += row.total;
      totalDiscount += row.discount;
      totalTx += row.transactions;
      totalItems += row.items;
    }

    final totalRow = rows.length + 1;
    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue('P${money.format(totalSales)}'),
      TextCellValue('P${money.format(totalDiscount)}'),
      IntCellValue(totalTx),
      IntCellValue(totalItems),
    ]);
    for (int col = 0; col < headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: totalRow))
          .cellStyle = CellStyle(bold: true);
    }

    sheet.setColWidth(0, 12);
    sheet.setColWidth(1, 16);
    sheet.setColWidth(2, 16);
    sheet.setColWidth(3, 14);
    sheet.setColWidth(4, 12);
  }

  void _buildGroupedSheet(
    Excel excel,
    String sheetName,
    String labelHeader,
    List<SalesDataItem> items,
  ) {
    final sheet = excel[sheetName];
    final money = NumberFormat('#,##0.00');
    final headers = [labelHeader, 'Total Sales', '% Share'];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    _styleHeaderRow(sheet, 0, headers.length);

    final total = items.fold<double>(0.0, (sum, i) => sum + i.totalSales);

    for (final item in items) {
      final pct = total > 0 ? item.totalSales / total * 100 : 0.0;
      sheet.appendRow([
        TextCellValue(item.name),
        TextCellValue('P${money.format(item.totalSales)}'),
        TextCellValue('${pct.toStringAsFixed(1)}%'),
      ]);
    }

    sheet.setColWidth(0, 28);
    sheet.setColWidth(1, 16);
    sheet.setColWidth(2, 10);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _styleHeaderRow(Sheet sheet, int rowIndex, int colCount) {
    for (int col = 0; col < colCount; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1B7A8C'),
        fontColorHex: ExcelColor.white,
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 2: Commit**

```bash
git add kiosk/lib/features/reports/services/report_export_service.dart
git commit -m "feat(kiosk): add ReportExportService with 6-sheet XLSX builder"
```

---

## Task 9 — Flutter: `DailyExportScheduler` + `app.dart` wiring

**Files:**
- Create: `kiosk/lib/features/reports/services/daily_export_scheduler.dart`
- Modify: `kiosk/lib/app.dart`

- [ ] **Step 1: Create scheduler**

```dart
// kiosk/lib/features/reports/services/daily_export_scheduler.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/shared_preferences/shared_preferences.dart';
import '../state/export_notifier.dart';

final dailyExportSchedulerProvider = NotifierProvider<DailyExportScheduler, void>(
  DailyExportScheduler.new,
);

class DailyExportScheduler extends Notifier<void> {
  static const _prefKey = 'daily_export_last_date';

  Timer? _timer;

  @override
  void build() {
    ref.onDispose(() => _timer?.cancel());
    Future.microtask(_initialize);
  }

  Future<void> _initialize() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final lastExportStr = await prefs.getString(_prefKey);
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    if (lastExportStr == null || lastExportStr != todayStr) {
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      await _runExport(yesterday);
    }

    _scheduleNextMidnight();
  }

  void _scheduleNextMidnight() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    _timer = Timer(duration, _onMidnight);
  }

  Future<void> _onMidnight() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await _runExport(yesterday);
    _scheduleNextMidnight();
  }

  Future<void> _runExport(DateTime date) async {
    try {
      final success = await ref.read(exportNotifierProvider.notifier).export(date);
      if (success) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString(
          _prefKey,
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );
      }
    } catch (e) {
      debugPrint('[DailyExportScheduler] Auto-export failed: $e');
    }
  }
}
```

- [ ] **Step 2: Initialize scheduler in `app.dart`**

In `kiosk/lib/app.dart`, add the import and initialization in `_WindowCloseGuardState.initState()`:

Add import at top:
```dart
import 'features/reports/services/daily_export_scheduler.dart';
```

Modify `_WindowCloseGuardState.initState()`:
```dart
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    widget.container.read(dailyExportSchedulerProvider);
  }
```

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/reports/services/daily_export_scheduler.dart \
        kiosk/lib/app.dart
git commit -m "feat(kiosk): add DailyExportScheduler with midnight timer and startup catch-up"
```

---

## Task 10 — Flutter: `UnexportedExportDialog`

**Files:**
- Create: `kiosk/lib/features/reports/view/unexported_export_dialog.dart`

- [ ] **Step 1: Create blocking modal**

```dart
// kiosk/lib/features/reports/view/unexported_export_dialog.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/color_set.dart';
import '../../../theme/pos_design.dart';
import '../state/export_notifier.dart';

class UnexportedExportDialog extends ConsumerWidget {
  const UnexportedExportDialog({
    super.key,
    required this.date,
    required this.count,
  });

  final DateTime date;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportNotifierProvider);

    ref.listen<ExportState>(exportNotifierProvider, (prev, next) {
      if ((prev?.isExporting ?? false) && !next.isExporting && next.exportError == null) {
        Navigator.of(context).pop();
      }
    });

    final dateLabel = DateFormat('MMM d').format(date);
    final isExporting = exportState.isExporting;
    final hasError = exportState.exportError != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(POSRadius.xl),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorSet.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(POSRadius.sm),
            ),
            child: Icon(Icons.warning_amber_rounded, color: ColorSet.danger, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'Unexported Transactions',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$dateLabel has $count transaction${count == 1 ? '' : 's'} that '
            'have not been exported yet.',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'You must export yesterday\'s report before accessing the Reports screen.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (hasError) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorSet.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(POSRadius.sm),
              ),
              child: Text(
                'Export failed: ${exportState.exportError}',
                style: TextStyle(color: ColorSet.danger, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
      actions: [
        FilledButton.icon(
          onPressed: isExporting
              ? null
              : () => ref.read(exportNotifierProvider.notifier).export(date),
          icon: isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.file_download_outlined),
          label: Text(
            isExporting
                ? 'Exporting…'
                : (hasError ? 'Retry Export' : 'Export Now'),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: ColorSet.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add kiosk/lib/features/reports/view/unexported_export_dialog.dart
git commit -m "feat(kiosk): add UnexportedExportDialog blocking modal"
```

---

## Task 11 — Flutter: `SalesReportScreen` updates

**Files:**
- Modify: `kiosk/lib/features/reports/view/sales_report_screen.dart`

- [ ] **Step 1: Replace class declaration and add imports**

Replace the import block at the top of `sales_report_screen.dart` — add the new imports:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/resposive_wrap_container.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/metric.dart';
import '../repositories/reports_repository.dart';
import '../state/export_notifier.dart';
import '../state/sales_report_notifier.dart';
import '../state/sales_report_state.dart';
import 'report_tab_selector.dart';
import 'sales_bar_chart.dart';
import 'sales_health_page.dart';
import 'unexported_export_dialog.dart';
```

- [ ] **Step 2: Convert `SalesReportScreen` to `HookConsumerWidget`**

Replace the class declaration and `build` method signature:

```dart
class SalesReportScreen extends HookConsumerWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesReportProvider);
    final exportState = ref.watch(exportNotifierProvider);
    final selectedTab = state.selectedTab;
    final isAndroid = context.breakpoint.isAndroid;
    final r = context.responsive;

    // Show snackbar when export completes or fails
    ref.listen<ExportState>(exportNotifierProvider, (prev, next) {
      if ((prev?.isExporting ?? false) && !next.isExporting) {
        if (next.exportError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: ${next.exportError}'),
              backgroundColor: ColorSet.danger,
            ),
          );
        } else if (next.lastExportPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report saved to ${next.lastExportPath}'),
              backgroundColor: ColorSet.primary,
            ),
          );
        }
      }
    });

    // Check yesterday's unexported transactions once on first render
    useEffect(() {
      Future.microtask(() async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        try {
          final repo = ref.read(reportsRepositoryProvider);
          final result = await repo.getExportable(startDate: start, endDate: end);
          if (result.count > 0 && context.mounted) {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => UnexportedExportDialog(
                date: yesterday,
                count: result.count,
              ),
            );
          }
        } catch (_) {
          // Do not block the screen if the check itself fails
        }
      });
      return null;
    }, const []);

    // Export button for the TopAppBar trailing slot
    final exportButton = IconButton(
      onPressed: exportState.isExporting
          ? null
          : () => ref.read(exportNotifierProvider.notifier).export(DateTime.now()),
      tooltip: 'Export Today\'s Report',
      icon: exportState.isExporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.file_download_outlined, color: Colors.white),
    );

    Widget content = ColoredBox(
      color: ColorSet.background,
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TopAppBar(
                onBackPressed: () {
                  if (context.canPop()) context.pop();
                },
                title: 'Sales Report',
                trailing: exportButton,
              ),
            ),
            ColoredBox(
              color: Colors.white,
              child: Container(
                padding: r.value<EdgeInsets>(
                  phone: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  kiosk: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: ReportTabSelector(
                  selectedTab: selectedTab,
                  onTabChanged: (tab) =>
                      ref.read(salesReportProvider.notifier).updateTab(tab),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: selectedTab == ReportTab.dashboard
                    ? _DashboardContent(
                        key: const ValueKey('dashboard'),
                        state: state,
                        isAndroid: isAndroid,
                        onRetry: () => ref.invalidate(salesReportProvider),
                      )
                    : const SalesHealthPage(key: ValueKey('health')),
              ),
            ),
          ],
        ),
      ),
    );

    if (isAndroid) {
      content = RefreshIndicator(
        onRefresh: () async => ref.invalidate(salesReportProvider),
        color: ColorSet.primary,
        child: content,
      );
    }

    if (isAndroid) {
      return AndroidScaffold(backgroundColor: ColorSet.background, body: content);
    }
    return WindowsScaffold(backgroundColor: ColorSet.background, body: content);
  }
}
```

- [ ] **Step 3: Analyze for errors**

```bash
cd kiosk
fvm dart analyze lib/features/reports/
```

Expected: No errors. Fix any reported issues before continuing.

- [ ] **Step 4: Commit**

```bash
git add kiosk/lib/features/reports/view/sales_report_screen.dart
git commit -m "feat(kiosk): add export button and unexported-check to SalesReportScreen"
```

---

## Self-Review Checklist

- [x] **Migration** adds `done_export` column and is registered in index
- [x] **Entity** has `doneExport: boolean` TypeORM column
- [x] **`ExportableReportService.getExportable`** short-circuits and returns zero-filled response when `count == 0`
- [x] **`ExportableReportService.markExported`** uses update query builder with date range
- [x] **All 5 private query methods** in `ExportableReportService` add `done_export = false` filter
- [x] **`ReportExportService.exportDay`** calls `markExported` only after successful file write
- [x] **`DailyExportScheduler`** persists date only on successful export
- [x] **`UnexportedExportDialog`** has `barrierDismissible: false` and no cancel/skip button
- [x] **`SalesReportScreen`** uses `useEffect` with empty deps `const []` so the check runs once
- [x] **`exportNotifierProvider`** is not autoDispose (survives tab navigation)
- [x] **`dailyExportSchedulerProvider`** is not autoDispose (stays alive for app session)
- [x] Scheduler initialized in `app.dart` via `widget.container.read(...)`
- [x] All type names consistent across tasks (e.g. `ExportableReport`, `ExportState`, `ExportableReportDto`)
