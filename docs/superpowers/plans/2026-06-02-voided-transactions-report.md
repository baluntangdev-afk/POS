# Voided Transactions in Sales Report — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `totalVoidedTransactions` and `totalVoidedAmount` to the sales summary report endpoint and display a "Voided" metric card in the kiosk dashboard.

**Architecture:** The existing `GET /api/v1/reports` endpoint is extended with two new fields returned from a second parallel DB query filtered to `CANCELLED` status. Net sales (`CONFIRMED` + `COMPLETED`) is unchanged. The kiosk consumes the new fields and renders a new metric card.

**Tech Stack:** NestJS · TypeORM · PostgreSQL · Jest (backend); Flutter · Riverpod · dart_mappable (kiosk)

---

## File Map

| Action | File |
|--------|------|
| Modify | `be/src/reports/reports.interface.ts` |
| Modify | `be/src/reports/dto/sales-response.dto.ts` |
| Modify | `be/src/reports/mapper/sales-report.mapper.ts` |
| Create | `be/src/reports/mapper/sales-report.mapper.spec.ts` |
| Modify | `be/src/reports/services/total-report.service.ts` |
| Modify | `kiosk/lib/data/backend_api/schemas/sales_summary_dto.dart` |
| Modify | `kiosk/lib/features/reports/entities/sales_summary.dart` |
| Modify | `kiosk/lib/features/reports/mappers/sales_summary_mappers.dart` |
| Modify | `kiosk/lib/features/reports/state/sales_report_state.dart` |
| Modify | `kiosk/lib/features/reports/view/sales_report_screen.dart` |
| Regen  | `kiosk/lib/data/backend_api/schemas/sales_summary_dto.mapper.dart` (build_runner) |
| Regen  | `kiosk/lib/features/reports/entities/sales_summary.mapper.dart` (build_runner) |

---

## Task 1: Extend the backend interface and DTO

**Files:**
- Modify: `be/src/reports/reports.interface.ts`
- Modify: `be/src/reports/dto/sales-response.dto.ts`

- [ ] **Step 1.1 — Add voided fields to `SalesReportRawRow`**

Open `be/src/reports/reports.interface.ts`. Add two optional fields to the `SalesReportRawRow` interface so the mapper can consume them from the raw DB result:

```typescript
export interface SalesReportRawRow {
  totalSales?: string | number | null;
  totalDiscount?: string | number | null;
  totalRefunds?: string | number | null;
  totalItems?: string | number | null;
  totalTransactions?: string | number | null;
  totalVoidedTransactions?: string | number | null;
  totalVoidedAmount?: string | number | null;
}
```

- [ ] **Step 1.2 — Add voided fields to `SalesResponseDto`**

Open `be/src/reports/dto/sales-response.dto.ts`. Append two new `@ApiProperty` fields after `totalTransactions`:

```typescript
import { ApiProperty } from '@nestjs/swagger';

export class SalesResponseDto {
  @ApiProperty({ description: 'Total of sales order final_total_amount', example: 200.0 })
  totalSales: number;

  @ApiProperty({ description: 'Total of sales order discount_amount', example: 100.0 })
  totalDiscount: number;

  @ApiProperty({ description: 'Total refunds.', example: 0.0 })
  totalRefunds: number;

  @ApiProperty({ description: 'Sales order item count', example: 200 })
  totalItems: number;

  @ApiProperty({ description: 'Sales order count', example: 20 })
  totalTransactions: number;

  @ApiProperty({ description: 'Count of voided (Cancelled) sales orders in range', example: 3 })
  totalVoidedTransactions: number;

  @ApiProperty({ description: 'Sum of final_total_amount for voided orders in range', example: 1200.0 })
  totalVoidedAmount: number;
}
```

- [ ] **Step 1.3 — Commit**

```bash
git add be/src/reports/reports.interface.ts be/src/reports/dto/sales-response.dto.ts
git commit -m "feat(reports): add voided fields to SalesReportRawRow and SalesResponseDto"
```

---

## Task 2: Update the mapper (TDD)

**Files:**
- Modify: `be/src/reports/mapper/sales-report.mapper.ts`
- Create: `be/src/reports/mapper/sales-report.mapper.spec.ts`

- [ ] **Step 2.1 — Write failing tests**

Create `be/src/reports/mapper/sales-report.mapper.spec.ts`:

```typescript
import { SalesReportMapper } from './sales-report.mapper';

describe('SalesReportMapper.toDto', () => {
  it('maps all fields including voided when raw data is provided', () => {
    const raw = {
      totalSales: '15000.5',
      totalDiscount: '500.0',
      totalRefunds: '200.25',
      totalItems: '120',
      totalTransactions: '45',
      totalVoidedTransactions: '3',
      totalVoidedAmount: '1200.75',
    };

    const result = SalesReportMapper.toDto(raw);

    expect(result.totalSales).toBe(15000.5);
    expect(result.totalDiscount).toBe(500);
    expect(result.totalRefunds).toBe(200.25);
    expect(result.totalItems).toBe(120);
    expect(result.totalTransactions).toBe(45);
    expect(result.totalVoidedTransactions).toBe(3);
    expect(result.totalVoidedAmount).toBe(1200.75);
  });

  it('returns zeros for voided fields when raw values are null', () => {
    const raw = {
      totalSales: '100',
      totalDiscount: null,
      totalRefunds: null,
      totalItems: '5',
      totalTransactions: '2',
      totalVoidedTransactions: null,
      totalVoidedAmount: null,
    };

    const result = SalesReportMapper.toDto(raw);

    expect(result.totalVoidedTransactions).toBe(0);
    expect(result.totalVoidedAmount).toBe(0);
  });

  it('returns all zeros when raw is null', () => {
    const result = SalesReportMapper.toDto(null);

    expect(result).toEqual({
      totalSales: 0,
      totalDiscount: 0,
      totalRefunds: 0,
      totalItems: 0,
      totalTransactions: 0,
      totalVoidedTransactions: 0,
      totalVoidedAmount: 0,
    });
  });
});
```

- [ ] **Step 2.2 — Run tests to verify they fail**

```bash
cd be && npm test -- --testPathPattern="sales-report.mapper.spec" --no-coverage
```

Expected: FAIL — `totalVoidedTransactions` and `totalVoidedAmount` are not mapped yet.

- [ ] **Step 2.3 — Update the mapper**

Replace the entire content of `be/src/reports/mapper/sales-report.mapper.ts`:

```typescript
import { SalesResponseDto } from '../dto/sales-response.dto';
import { toDecimalNumber } from '../../utils/calculation.helper';
import type { SalesReportRawRow } from '../reports.interface';

export class SalesReportMapper {
  static toDto(raw: SalesReportRawRow | null | undefined): SalesResponseDto {
    if (raw == null) {
      return {
        totalSales: 0,
        totalDiscount: 0,
        totalRefunds: 0,
        totalItems: 0,
        totalTransactions: 0,
        totalVoidedTransactions: 0,
        totalVoidedAmount: 0,
      };
    }
    return {
      totalSales: toDecimalNumber(raw.totalSales),
      totalDiscount: toDecimalNumber(raw.totalDiscount),
      totalRefunds: toDecimalNumber(raw.totalRefunds),
      totalItems: toDecimalNumber(raw.totalItems),
      totalTransactions: toDecimalNumber(raw.totalTransactions),
      totalVoidedTransactions: toDecimalNumber(raw.totalVoidedTransactions),
      totalVoidedAmount: toDecimalNumber(raw.totalVoidedAmount),
    };
  }
}
```

- [ ] **Step 2.4 — Run tests to verify they pass**

```bash
cd be && npm test -- --testPathPattern="sales-report.mapper.spec" --no-coverage
```

Expected: PASS — 3 tests pass.

- [ ] **Step 2.5 — Commit**

```bash
git add be/src/reports/mapper/sales-report.mapper.ts be/src/reports/mapper/sales-report.mapper.spec.ts
git commit -m "feat(reports): map totalVoidedTransactions and totalVoidedAmount in SalesReportMapper"
```

---

## Task 3: Update TotalReportService to query voided orders

**Files:**
- Modify: `be/src/reports/services/total-report.service.ts`

- [ ] **Step 3.1 — Refactor and add voided query**

Replace the entire content of `be/src/reports/services/total-report.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, SelectQueryBuilder } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesOrderStatus } from '../../sales-orders/sales-orders.enum';
import { SalesQueryDto } from '../dto/sales-query.dto';
import { SalesResponseDto } from '../dto/sales-response.dto';
import { SalesReportMapper } from '../mapper/sales-report.mapper';
import { BaseReportService } from './base-report.service';
import { STATUS_FILTER } from '../reports.constants';

@Injectable()
export class TotalReportService extends BaseReportService<SalesQueryDto, SalesResponseDto> {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
  ) {
    super();
  }

  async getReport(query: SalesQueryDto): Promise<SalesResponseDto> {
    const soQueryBuilder = this.salesOrderRepository
      .createQueryBuilder('so')
      .select('SUM(so.final_total_amount)', 'totalSales')
      .addSelect('SUM(so.discount_amount)', 'totalDiscount')
      .addSelect('SUM(refund.total_refund_amount)', 'totalRefunds')
      .addSelect('COUNT(so.id)', 'totalTransactions')
      .leftJoin('so.refund', 'refund')
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER });
    this.applyDateRangeFilter(soQueryBuilder, query);

    const soiQueryBuilder = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('COUNT(soi.id)', 'totalItems')
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER });
    this.applyDateRangeFilter(soiQueryBuilder, query);

    const voidedQueryBuilder = this.salesOrderRepository
      .createQueryBuilder('so')
      .select('COUNT(so.id)', 'totalVoidedTransactions')
      .addSelect('SUM(so.final_total_amount)', 'totalVoidedAmount')
      .andWhere('so.status = :voidedStatus', { voidedStatus: SalesOrderStatus.CANCELLED });
    this.applyDateRangeFilter(voidedQueryBuilder, query);

    const [soQueryResult, soiQueryResult, voidedQueryResult] = await Promise.all([
      soQueryBuilder.getRawOne(),
      soiQueryBuilder.getRawOne<{ totalItems: string }>(),
      voidedQueryBuilder.getRawOne<{ totalVoidedTransactions: string; totalVoidedAmount: string }>(),
    ]);

    return SalesReportMapper.toDto({
      ...soQueryResult,
      totalItems: soiQueryResult?.totalItems ?? '0',
      totalVoidedTransactions: voidedQueryResult?.totalVoidedTransactions ?? '0',
      totalVoidedAmount: voidedQueryResult?.totalVoidedAmount ?? '0',
    });
  }

  private applyDateRangeFilter(
    qb: SelectQueryBuilder<SalesOrder | SalesOrderItem>,
    query: SalesQueryDto,
  ): void {
    if (query.startDate && !query.endDate) {
      qb.andWhere('so.so_date >= :startDate', { startDate: query.startDate });
    } else if (query.endDate && !query.startDate) {
      qb.andWhere('so.so_date <= :endDate', { endDate: query.endDate });
    } else if (query.startDate && query.endDate) {
      qb.andWhere('so.so_date BETWEEN :startDate AND :endDate', {
        startDate: query.startDate,
        endDate: query.endDate,
      });
    }
  }
}
```

> **Note:** The old `applyDateFilter` method combined the status filter and date range in one helper. It is replaced by `applyDateRangeFilter` (date only). The status `WHERE` clauses are now inlined in each query builder — this is intentional so the voided query can use a different status filter without the helper fighting it.

- [ ] **Step 3.2 — Run the full backend test suite to confirm nothing is broken**

```bash
cd be && npm test -- --no-coverage
```

Expected: All existing tests pass. The mapper spec from Task 2 also passes.

- [ ] **Step 3.3 — Commit**

```bash
git add be/src/reports/services/total-report.service.ts
git commit -m "feat(reports): add voided orders query to TotalReportService"
```

---

## Task 4: Update Kiosk DTO and Entity

**Files:**
- Modify: `kiosk/lib/data/backend_api/schemas/sales_summary_dto.dart`
- Modify: `kiosk/lib/features/reports/entities/sales_summary.dart`

- [ ] **Step 4.1 — Add fields to `SalesSummaryDto`**

Replace the entire content of `kiosk/lib/data/backend_api/schemas/sales_summary_dto.dart`:

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'sales_summary_dto.mapper.dart';

@MappableClass()
class SalesSummaryDto with SalesSummaryDtoMappable {
  const SalesSummaryDto({
    required this.totalSales,
    required this.totalDiscount,
    required this.totalRefunds,
    required this.totalItems,
    required this.totalTransactions,
    required this.totalVoidedTransactions,
    required this.totalVoidedAmount,
  });

  final double totalSales;
  final double totalDiscount;
  final double totalRefunds;
  final int totalItems;
  final int totalTransactions;
  final int totalVoidedTransactions;
  final double totalVoidedAmount;

  static const fromJson = SalesSummaryDtoMapper.fromJson;
}
```

- [ ] **Step 4.2 — Add fields to `SalesSummary` entity**

Replace the entire content of `kiosk/lib/features/reports/entities/sales_summary.dart`:

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'sales_summary.mapper.dart';

@MappableClass()
class SalesSummary with SalesSummaryMappable {
  const SalesSummary({
    required this.totalSales,
    required this.totalDiscount,
    required this.totalRefunds,
    required this.totalItems,
    required this.totalTransactions,
    required this.totalVoidedTransactions,
    required this.totalVoidedAmount,
  });

  final double totalSales;
  final double totalDiscount;
  final double totalRefunds;
  final int totalItems;
  final int totalTransactions;
  final int totalVoidedTransactions;
  final double totalVoidedAmount;
}
```

- [ ] **Step 4.3 — Regenerate `.mapper.dart` files**

```bash
cd kiosk && fvm dart run build_runner build --delete-conflicting-outputs
```

Expected: `sales_summary_dto.mapper.dart` and `sales_summary.mapper.dart` are regenerated with the two new fields. No errors.

- [ ] **Step 4.4 — Commit**

```bash
git add kiosk/lib/data/backend_api/schemas/sales_summary_dto.dart
git add kiosk/lib/data/backend_api/schemas/sales_summary_dto.mapper.dart
git add kiosk/lib/features/reports/entities/sales_summary.dart
git add kiosk/lib/features/reports/entities/sales_summary.mapper.dart
git commit -m "feat(kiosk/reports): add totalVoidedTransactions and totalVoidedAmount to SalesSummaryDto and SalesSummary"
```

---

## Task 5: Update Kiosk Mapper

**Files:**
- Modify: `kiosk/lib/features/reports/mappers/sales_summary_mappers.dart`

- [ ] **Step 5.1 — Pass through the two new fields**

Replace the entire content of `kiosk/lib/features/reports/mappers/sales_summary_mappers.dart`:

```dart
import '../../../data/backend_api/schemas/sales_summary_dto.dart';
import '../entities/sales_summary.dart';

extension DTOMapper on SalesSummaryDto {
  SalesSummary get toEntity => SalesSummary(
        totalSales: totalSales,
        totalDiscount: totalDiscount,
        totalRefunds: totalRefunds,
        totalItems: totalItems,
        totalTransactions: totalTransactions,
        totalVoidedTransactions: totalVoidedTransactions,
        totalVoidedAmount: totalVoidedAmount,
      );
}

extension EntityMapper on SalesSummary {
  SalesSummaryDto get toModel => SalesSummaryDto(
        totalSales: totalSales,
        totalDiscount: totalDiscount,
        totalRefunds: totalRefunds,
        totalItems: totalItems,
        totalTransactions: totalTransactions,
        totalVoidedTransactions: totalVoidedTransactions,
        totalVoidedAmount: totalVoidedAmount,
      );
}
```

- [ ] **Step 5.2 — Analyze to confirm no type errors**

```bash
cd kiosk && fvm dart analyze lib/features/reports/mappers/sales_summary_mappers.dart
```

Expected: `No issues found!`

- [ ] **Step 5.3 — Commit**

```bash
git add kiosk/lib/features/reports/mappers/sales_summary_mappers.dart
git commit -m "feat(kiosk/reports): map voided fields through sales_summary_mappers"
```

---

## Task 6: Expose voided getters in SalesReportState

**Files:**
- Modify: `kiosk/lib/features/reports/state/sales_report_state.dart`

- [ ] **Step 6.1 — Add two getters after `totalItems`**

In `kiosk/lib/features/reports/state/sales_report_state.dart`, add the following two getters after the `totalItems` getter (around line 164):

```dart
  int get totalVoidedTransactions {
    return salesSummary?.totalVoidedTransactions ?? 0;
  }

  double get totalVoidedAmount {
    return salesSummary?.totalVoidedAmount ?? 0.0;
  }
```

- [ ] **Step 6.2 — Analyze**

```bash
cd kiosk && fvm dart analyze lib/features/reports/state/sales_report_state.dart
```

Expected: `No issues found!`

- [ ] **Step 6.3 — Commit**

```bash
git add kiosk/lib/features/reports/state/sales_report_state.dart
git commit -m "feat(kiosk/reports): expose totalVoidedTransactions and totalVoidedAmount getters on SalesReportState"
```

---

## Task 7: Add "Voided" metric card to the kiosk dashboard

**Files:**
- Modify: `kiosk/lib/features/reports/view/sales_report_screen.dart`

- [ ] **Step 7.1 — Add the Voided metric to `_buildMetrics()`**

In `kiosk/lib/features/reports/view/sales_report_screen.dart`, find `_buildMetrics()` (around line 382). Append a sixth `Metric` entry:

```dart
List<Metric> _buildMetrics(SalesReportState state) => [
      Metric(
        title: 'Net Sales',
        value: state.totalNetSales.toStringAsFixed(2),
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF10B981),
      ),
      Metric(
        title: 'Items Sold',
        value: state.totalItems.toString(),
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFF0EA5E9),
        isMonetary: false,
      ),
      Metric(
        title: 'Transactions',
        value: state.totalTransactions.toString(),
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF8B5CF6),
        isMonetary: false,
      ),
      Metric(
        title: 'Discounts',
        value: state.totalDiscounts.toStringAsFixed(2),
        icon: Icons.local_offer_outlined,
        color: const Color(0xFFF97316),
      ),
      Metric(
        title: 'Refunds',
        value: state.totalRefunds.toStringAsFixed(2),
        icon: Icons.money_off_rounded,
        color: const Color(0xFFEF4444),
      ),
      Metric(
        title: 'Voided',
        value: state.totalVoidedTransactions.toString(),
        icon: Icons.block_rounded,
        color: const Color(0xFF6B7280),
        isMonetary: false,
      ),
    ];
```

> **Layout note:** The Windows dashboard lays out metric cards in a single `Row` with `Expanded` children (see `_WindowsDashboard`). Adding a sixth card automatically shrinks each card proportionally — no layout code needs to change. The Android grid uses `crossAxisCount: 2`, so six cards renders as three rows of two.

- [ ] **Step 7.2 — Analyze the whole reports feature**

```bash
cd kiosk && fvm dart analyze lib/features/reports/
```

Expected: `No issues found!`

- [ ] **Step 7.3 — Commit**

```bash
git add kiosk/lib/features/reports/view/sales_report_screen.dart
git commit -m "feat(kiosk/reports): add Voided metric card to sales dashboard"
```

---

## Task 8: Full integration verify

- [ ] **Step 8.1 — Run full backend test suite**

```bash
cd be && npm test -- --no-coverage
```

Expected: All tests pass including the `sales-report.mapper.spec` from Task 2.

- [ ] **Step 8.2 — Run full kiosk analysis**

```bash
cd kiosk && fvm dart analyze
```

Expected: `No issues found!`

- [ ] **Step 8.3 — (Optional) Manual smoke test**

Start the backend (`npm run start:dev` in `be/`) and hit the endpoint:

```
GET http://localhost:3000/api/v1/reports?startDate=2026-01-01T00:00:00.000Z&endDate=2026-12-31T23:59:59.000Z
```

Expected response shape:

```json
{
  "totalSales": <number>,
  "totalDiscount": <number>,
  "totalRefunds": <number>,
  "totalItems": <number>,
  "totalTransactions": <number>,
  "totalVoidedTransactions": <number>,
  "totalVoidedAmount": <number>
}
```

Void a sales order via `POST /api/v1/sales-orders/:id/void`, re-hit the endpoint, and confirm `totalVoidedTransactions` increments by 1 and `totalVoidedAmount` increases by that order's `finalTotalAmount`.

---

## Self-Review Checklist

| Spec requirement | Covered in |
|------------------|------------|
| Add `totalVoidedTransactions` and `totalVoidedAmount` to backend DTO | Tasks 1, 2 |
| TotalReportService queries `CANCELLED` orders in the same date window | Task 3 |
| Net sales (`CONFIRMED` + `COMPLETED`) is not changed | Task 3 — `STATUS_FILTER` preserved |
| No new DB migration needed | ✓ `status` and `voided_*` columns already exist |
| Kiosk DTO / entity updated | Task 4 |
| Kiosk mapper passes new fields through | Task 5 |
| State exposes `totalVoidedTransactions` / `totalVoidedAmount` getters | Task 6 |
| "Voided" metric card added to dashboard | Task 7 |
| build_runner regeneration called after annotated-class changes | Task 4 step 3 |
