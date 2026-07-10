# Cashier Report (X Reading) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give cashiers a read-only "X Reading" snapshot of their own today's transactions (sales, discounts, tax, transaction counts) on the Transactions screen, previewed before printing, without touching checkout/payment/inventory logic.

**Architecture:** One new backend report endpoint (`GET /api/v1/reports/cashier-x-reading`, scoped to the authenticated user + today's date) added to the existing `reports/` module, following its established QueryBuilder-aggregation pattern. One new kiosk feature module (`features/cashier_report/`) with entity/repository/notifier/encoder/screen, wired into the existing router and into `TransactionsScreen`'s app bar.

**Tech Stack:** NestJS + TypeORM + PostgreSQL (backend); Flutter + Riverpod (`Notifier`/`Mutation`) + `dart_mappable` + `go_router_builder` + `esc_pos_utils_plus` (kiosk).

**Reference:** Full design rationale and scope decisions are in `docs/superpowers/specs/2026-07-09-cashier-x-reading-design.md` — read it first if anything below seems under-explained.

---

## Task 1: Export the VAT-exempt discount constant + add raw-row interfaces

**Files:**
- Modify: `be/src/sales-orders/services/sales-order-calculation.service.ts:13`
- Modify: `be/src/reports/reports.interface.ts`

- [ ] **Step 1: Export the existing VAT-exempt constant**

In `be/src/sales-orders/services/sales-order-calculation.service.ts`, change line 13 from:

```ts
const VAT_EXEMPT_DISCOUNT_NAME_PATTERNS = 'Senior Citizen / PWD';
```

to:

```ts
export const VAT_EXEMPT_DISCOUNT_NAME_PATTERNS = 'Senior Citizen / PWD';
```

This is the single source of truth for "which discount name makes an order VAT-exempt" (already used by `isVatExempt()` in the same file). The new report service reuses it instead of duplicating the string literal.

- [ ] **Step 2: Add raw row interfaces for the new report's queries**

Open `be/src/reports/reports.interface.ts` and append at the end of the file:

```ts
/**
 * Raw row shared by cashier X-Reading's payment-method and discount breakdowns (name + summed amount).
 */
export interface NameAmountRawRow {
  name: string;
  amount?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's order-level aggregates (totals, discounts, completed count, avg/high/low).
 */
export interface CashierSalesTotalsRawRow {
  totalSales?: string | number | null;
  totalDiscounts?: string | number | null;
  completedTransactions?: string | number | null;
  averageSale?: string | number | null;
  highestSale?: string | number | null;
  lowestSale?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's voided-order count.
 */
export interface CashierVoidedRawRow {
  voidedTransactions?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's refunded-order count.
 */
export interface CashierRefundedRawRow {
  refundedTransactions?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's non-exempt VAT totals.
 */
export interface CashierTaxRawRow {
  vatSales?: string | number | null;
  vatAmount?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's VAT-exempt sales total.
 */
export interface CashierVatExemptRawRow {
  vatExemptSales?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's total quantity sold.
 */
export interface CashierQuantityRawRow {
  totalQuantitySold?: string | number | null;
}
```

- [ ] **Step 3: Verify the backend still compiles**

Run: `cd be && npm run build`
Expected: Build succeeds with no TypeScript errors.

- [ ] **Step 4: Commit**

```bash
git add be/src/sales-orders/services/sales-order-calculation.service.ts be/src/reports/reports.interface.ts
git commit -m "feat(reports): export VAT-exempt constant, add cashier X-Reading raw row types"
```

---

## Task 2: Add the Cashier X-Reading response DTO

**Files:**
- Create: `be/src/reports/dto/cashier-x-reading-response.dto.ts`

- [ ] **Step 1: Write the DTO**

```ts
import { ApiProperty } from '@nestjs/swagger';

export class NameAmountDto {
  @ApiProperty({ description: 'Name (payment method or discount name)', example: 'Cash' })
  name: string;

  @ApiProperty({ description: 'Summed amount for this name', example: 12450.0 })
  amount: number;
}

export class CashierXReadingResponseDto {
  @ApiProperty({ description: 'Cashier full name', example: 'Juan Dela Cruz' })
  cashierName: string;

  @ApiProperty({ description: 'Terminal/register name', example: 'POS-01' })
  terminalName: string;

  @ApiProperty({ description: "Business date (today), formatted MM/DD/YYYY", example: '07/09/2026' })
  businessDate: string;

  @ApiProperty({
    description: 'Report generation timestamp (ISO 8601)',
    example: '2026-07-09T14:32:10.000Z',
  })
  reportGeneratedAt: string;

  @ApiProperty({ description: 'Sales grouped by payment method', type: NameAmountDto, isArray: true })
  salesByPaymentMethod: NameAmountDto[];

  @ApiProperty({ description: 'Total sales, net of refunds, excludes voided orders', example: 19050.0 })
  totalSales: number;

  @ApiProperty({ description: 'Total transactions (completed + voided)', example: 43 })
  totalTransactions: number;

  @ApiProperty({ description: 'Completed transactions', example: 42 })
  completedTransactions: number;

  @ApiProperty({ description: 'Voided (cancelled) transactions', example: 1 })
  voidedTransactions: number;

  @ApiProperty({ description: 'Transactions with at least one refund', example: 1 })
  refundedTransactions: number;

  @ApiProperty({ description: 'Discounts grouped by discount name', type: NameAmountDto, isArray: true })
  discounts: NameAmountDto[];

  @ApiProperty({ description: 'Total discounts applied', example: 665.0 })
  totalDiscounts: number;

  @ApiProperty({ description: 'VAT-applicable sales (VAT-exclusive amount)', example: 17000.89 })
  vatSales: number;

  @ApiProperty({ description: 'VAT amount collected', example: 2041.11 })
  vatAmount: number;

  @ApiProperty({ description: 'Sales from VAT-exempt orders (Senior/PWD)', example: 2008.0 })
  vatExemptSales: number;

  @ApiProperty({ description: 'Total cash collected (also the Cash entry in salesByPaymentMethod)', example: 12450.0 })
  cashCollected: number;

  @ApiProperty({ description: 'Average sale amount', example: 453.57 })
  averageSale: number;

  @ApiProperty({ description: 'Highest single sale amount', example: 1250.0 })
  highestSale: number;

  @ApiProperty({ description: 'Lowest single sale amount', example: 85.0 })
  lowestSale: number;

  @ApiProperty({ description: 'Total quantity of items sold', example: 187 })
  totalQuantitySold: number;
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd be && npm run build`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add be/src/reports/dto/cashier-x-reading-response.dto.ts
git commit -m "feat(reports): add CashierXReadingResponseDto"
```

---

## Task 3: Add the Cashier X-Reading mapper

**Files:**
- Create: `be/src/reports/mapper/cashier-x-reading-report.mapper.ts`

- [ ] **Step 1: Write the mapper**

```ts
import dayjs from 'dayjs';
import { User } from '../../users/entities/user.entity';
import { toDecimalNumber } from '../../utils/calculation.helper';
import { CashierXReadingResponseDto, NameAmountDto } from '../dto/cashier-x-reading-response.dto';
import { DATE_FORMAT } from '../reports.constants';
import type {
  CashierQuantityRawRow,
  CashierRefundedRawRow,
  CashierSalesTotalsRawRow,
  CashierTaxRawRow,
  CashierVatExemptRawRow,
  CashierVoidedRawRow,
  NameAmountRawRow,
} from '../reports.interface';

/** Inputs gathered by CashierXReadingReportService before mapping to the response DTO. */
export interface CashierXReadingRawInputs {
  currentUser: User;
  paymentRows: NameAmountRawRow[];
  discountRows: NameAmountRawRow[];
  salesTotals: CashierSalesTotalsRawRow | undefined;
  voided: CashierVoidedRawRow | undefined;
  refunded: CashierRefundedRawRow | undefined;
  tax: CashierTaxRawRow | undefined;
  vatExempt: CashierVatExemptRawRow | undefined;
  quantity: CashierQuantityRawRow | undefined;
}

/**
 * Maps the parallel query results for the cashier X-Reading report into a single response DTO.
 * All money/count fields default to 0 when the underlying query returned no rows.
 */
export class CashierXReadingReportMapper {
  static toDto(raw: CashierXReadingRawInputs): CashierXReadingResponseDto {
    const { currentUser } = raw;
    const cashierName = `${currentUser.firstName} ${currentUser.lastName}`.trim();
    const terminalName =
      currentUser.posTerminal?.legalName ?? currentUser.posTerminal?.kioskId ?? 'Unassigned';

    const salesByPaymentMethod = raw.paymentRows.map(toNameAmountDto);
    const discounts = raw.discountRows.map(toNameAmountDto);

    const completedTransactions = toDecimalNumber(raw.salesTotals?.completedTransactions, 0);
    const voidedTransactions = toDecimalNumber(raw.voided?.voidedTransactions, 0);
    const cashCollected = salesByPaymentMethod.find((row) => row.name === 'Cash')?.amount ?? 0;

    return {
      cashierName,
      terminalName,
      businessDate: dayjs().format(DATE_FORMAT),
      reportGeneratedAt: new Date().toISOString(),
      salesByPaymentMethod,
      totalSales: toDecimalNumber(raw.salesTotals?.totalSales),
      totalTransactions: completedTransactions + voidedTransactions,
      completedTransactions,
      voidedTransactions,
      refundedTransactions: toDecimalNumber(raw.refunded?.refundedTransactions, 0),
      discounts,
      totalDiscounts: toDecimalNumber(raw.salesTotals?.totalDiscounts),
      vatSales: toDecimalNumber(raw.tax?.vatSales),
      vatAmount: toDecimalNumber(raw.tax?.vatAmount),
      vatExemptSales: toDecimalNumber(raw.vatExempt?.vatExemptSales),
      cashCollected,
      averageSale: toDecimalNumber(raw.salesTotals?.averageSale),
      highestSale: toDecimalNumber(raw.salesTotals?.highestSale),
      lowestSale: toDecimalNumber(raw.salesTotals?.lowestSale),
      totalQuantitySold: toDecimalNumber(raw.quantity?.totalQuantitySold, 0),
    };
  }
}

function toNameAmountDto(row: NameAmountRawRow): NameAmountDto {
  return { name: row.name, amount: toDecimalNumber(row.amount) };
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd be && npm run build`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add be/src/reports/mapper/cashier-x-reading-report.mapper.ts
git commit -m "feat(reports): add CashierXReadingReportMapper"
```

---

## Task 4: Add the Cashier X-Reading report service

**Files:**
- Create: `be/src/reports/services/cashier-x-reading-report.service.ts`

- [ ] **Step 1: Write the service**

```ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesOrderDiscount } from '../../sales-orders/entities/sales-order-discount.entity';
import { Payment } from '../../payments/entities/payment.entity';
import { User } from '../../users/entities/user.entity';
import { SalesOrderStatus } from '../../sales-orders/sales-orders.enum';
import { VAT_EXEMPT_DISCOUNT_NAME_PATTERNS } from '../../sales-orders/services/sales-order-calculation.service';
import { STATUS_FILTER } from '../reports.constants';
import { CashierXReadingResponseDto } from '../dto/cashier-x-reading-response.dto';
import { CashierXReadingReportMapper } from '../mapper/cashier-x-reading-report.mapper';
import { BaseReportService } from './base-report.service';
import type {
  CashierQuantityRawRow,
  CashierRefundedRawRow,
  CashierSalesTotalsRawRow,
  CashierTaxRawRow,
  CashierVatExemptRawRow,
  CashierVoidedRawRow,
  NameAmountRawRow,
} from '../reports.interface';

/**
 * X Reading: read-only snapshot of the current cashier's own transactions today, on their
 * assigned terminal. Never resets counters, closes a shift, or mutates any data.
 */
@Injectable()
export class CashierXReadingReportService extends BaseReportService<
  User,
  CashierXReadingResponseDto
> {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
    @InjectRepository(SalesOrderDiscount)
    private readonly salesOrderDiscountRepository: Repository<SalesOrderDiscount>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {
    super();
  }

  async getReport(causer: User): Promise<CashierXReadingResponseDto> {
    const [currentUser, paymentRows, discountRows, salesTotals, voided, refunded, tax, vatExempt, quantity] =
      await Promise.all([
        this.userRepository.findOne({ where: { id: causer.id }, relations: ['posTerminal'] }),
        this.getPaymentBreakdown(causer.id),
        this.getDiscountBreakdown(causer.id),
        this.getSalesTotals(causer.id),
        this.getVoidedCount(causer.id),
        this.getRefundedCount(causer.id),
        this.getTax(causer.id),
        this.getVatExemptSales(causer.id),
        this.getQuantitySold(causer.id),
      ]);

    if (currentUser == null) {
      throw new Error(`User ${causer.id} not found while generating X Reading`);
    }

    return CashierXReadingReportMapper.toDto({
      currentUser,
      paymentRows,
      discountRows,
      salesTotals,
      voided,
      refunded,
      tax,
      vatExempt,
      quantity,
    });
  }

  private getPaymentBreakdown(userId: number): Promise<NameAmountRawRow[]> {
    return this.paymentRepository
      .createQueryBuilder('p')
      .innerJoin('p.salesOrder', 'so')
      .select(`COALESCE(p.payment_method_name, p.payment_method::text)`, 'name')
      .addSelect(
        `SUM(so.final_total_amount - COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'amount',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .groupBy(`COALESCE(p.payment_method_name, p.payment_method::text)`)
      .getRawMany<NameAmountRawRow>();
  }

  private getDiscountBreakdown(userId: number): Promise<NameAmountRawRow[]> {
    return this.salesOrderDiscountRepository
      .createQueryBuilder('sod')
      .innerJoin('sod.discount', 'd')
      .innerJoin('sod.salesOrder', 'so')
      .select('d.name', 'name')
      .addSelect('SUM(sod.applied_amount)', 'amount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .groupBy('d.name')
      .getRawMany<NameAmountRawRow>();
  }

  private getSalesTotals(userId: number): Promise<CashierSalesTotalsRawRow | undefined> {
    return this.salesOrderRepository
      .createQueryBuilder('so')
      .select(
        `SUM(so.final_total_amount - COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'totalSales',
      )
      .addSelect('SUM(so.discount_amount)', 'totalDiscounts')
      .addSelect('COUNT(so.id)', 'completedTransactions')
      .addSelect('AVG(so.final_total_amount)', 'averageSale')
      .addSelect('MAX(so.final_total_amount)', 'highestSale')
      .addSelect('MIN(so.final_total_amount)', 'lowestSale')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .getRawOne<CashierSalesTotalsRawRow>();
  }

  private getVoidedCount(userId: number): Promise<CashierVoidedRawRow | undefined> {
    return this.salesOrderRepository
      .createQueryBuilder('so')
      .select('COUNT(so.id)', 'voidedTransactions')
      .where('so.status = :voidedStatus', { voidedStatus: SalesOrderStatus.CANCELLED })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .getRawOne<CashierVoidedRawRow>();
  }

  private getRefundedCount(userId: number): Promise<CashierRefundedRawRow | undefined> {
    return this.salesOrderRepository
      .createQueryBuilder('so')
      .select('COUNT(so.id)', 'refundedTransactions')
      .where('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .andWhere('EXISTS (SELECT 1 FROM refunds r WHERE r.original_sales_order_id = so.id)')
      .getRawOne<CashierRefundedRawRow>();
  }

  private getTax(userId: number): Promise<CashierTaxRawRow | undefined> {
    return this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('SUM(soi.vat_exclusive_amount)', 'vatSales')
      .addSelect('SUM(soi.vat_amount)', 'vatAmount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .andWhere(
        `NOT EXISTS (SELECT 1 FROM so_discounts sod INNER JOIN discounts d ON d.id = sod.discount_id WHERE sod.sales_order_id = so.id AND d.name = :vatExemptName)`,
        { vatExemptName: VAT_EXEMPT_DISCOUNT_NAME_PATTERNS },
      )
      .getRawOne<CashierTaxRawRow>();
  }

  private getVatExemptSales(userId: number): Promise<CashierVatExemptRawRow | undefined> {
    return this.salesOrderRepository
      .createQueryBuilder('so')
      .select('SUM(so.final_total_amount)', 'vatExemptSales')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .andWhere(
        `EXISTS (SELECT 1 FROM so_discounts sod INNER JOIN discounts d ON d.id = sod.discount_id WHERE sod.sales_order_id = so.id AND d.name = :vatExemptName)`,
        { vatExemptName: VAT_EXEMPT_DISCOUNT_NAME_PATTERNS },
      )
      .getRawOne<CashierVatExemptRawRow>();
  }

  private getQuantitySold(userId: number): Promise<CashierQuantityRawRow | undefined> {
    return this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('SUM(soi.qty)', 'totalQuantitySold')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .getRawOne<CashierQuantityRawRow>();
  }
}
```

Note: `getPaymentBreakdown` deliberately mirrors `PaymentSalesReportService`'s existing formula (`SUM(so.final_total_amount - refunds)` grouped per payment method) rather than summing `payment.amount_paid`, to stay numerically consistent with how the manager dashboard already reports payment-method totals elsewhere in this codebase.

- [ ] **Step 2: Verify it compiles**

Run: `cd be && npm run build`
Expected: Build succeeds. (It will only succeed once Task 5's module wiring provides the repositories at runtime, but `npm run build` is a pure TypeScript compile check and will pass once the imports resolve — the DI wiring is verified at runtime in Task 6.)

- [ ] **Step 3: Commit**

```bash
git add be/src/reports/services/cashier-x-reading-report.service.ts
git commit -m "feat(reports): add CashierXReadingReportService"
```

---

## Task 5: Wire the controller endpoint

**Files:**
- Modify: `be/src/reports/reports.controller.ts`

- [ ] **Step 1: Add imports**

At the top of `be/src/reports/reports.controller.ts`, alongside the existing imports, add:

```ts
import { User } from '../users/entities/user.entity';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { CashierXReadingReportService } from './services/cashier-x-reading-report.service';
import { CashierXReadingResponseDto } from './dto/cashier-x-reading-response.dto';
```

- [ ] **Step 2: Inject the service**

In the constructor, add a new parameter after `exportableReportService`:

```ts
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
    private readonly cashierXReadingReportService: CashierXReadingReportService,
  ) {}
```

- [ ] **Step 3: Add the endpoint method**

Add this method to the controller, right after `getExportable`:

```ts
  @Get('cashier-x-reading')
  @ApiOperation({ summary: "Get the current cashier's X Reading (today, self, own terminal)" })
  @ApiOkResponse({ description: 'Cashier X Reading snapshot.', type: CashierXReadingResponseDto })
  getCashierXReading(@CurrentUser() causer: User): Promise<CashierXReadingResponseDto> {
    return this.cashierXReadingReportService.getReport(causer);
  }
```

- [ ] **Step 4: Verify it compiles**

Run: `cd be && npm run build`
Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
git add be/src/reports/reports.controller.ts
git commit -m "feat(reports): wire GET /reports/cashier-x-reading endpoint"
```

---

## Task 6: Wire the module and verify end-to-end

**Files:**
- Modify: `be/src/reports/reports.module.ts`

- [ ] **Step 1: Update the module**

Replace the full contents of `be/src/reports/reports.module.ts` with:

```ts
import { Module } from '@nestjs/common';
import { ReportsController } from './reports.controller';
import { TotalReportService } from './services/total-report.service';
import { HourlySalesReportService } from './services/hourly-sales-report.service';
import { DailySalesReportService } from './services/daily-sales-report.service';
import { MonthlySalesReportService } from './services/monthly-sales-report.service';
import { ProductGroupSalesReportService } from './services/product-group-sales-report.service';
import { ProductSalesReportService } from './services/product-sales-report.service';
import { UserSalesReportService } from './services/user-sales-report.service';
import { PaymentSalesReportService } from './services/payment-sales-report.service';
import { ExportableReportService } from './services/exportable-report.service';
import { CashierXReadingReportService } from './services/cashier-x-reading-report.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SalesOrder } from '../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../sales-orders/entities/sales-order-item.entity';
import { SalesOrderDiscount } from '../sales-orders/entities/sales-order-discount.entity';
import { Payment } from '../payments/entities/payment.entity';
import { User } from '../users/entities/user.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([SalesOrder, SalesOrderItem, SalesOrderDiscount, Payment, User]),
  ],
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
    CashierXReadingReportService,
  ],
})
export class ReportsModule {}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd be && npm run build`
Expected: Build succeeds.

- [ ] **Step 3: Start the dev server and verify the endpoint manually**

Run: `cd be && npm run start:dev`

Once it's up, open `http://localhost:3000/api/docs`, authenticate as a cashier user who has at least one sales order dated today (`POST /api/v1/auth/login`, then use the token via Swagger's Authorize button), and call `GET /api/v1/reports/cashier-x-reading`.

Expected: HTTP 200 with a JSON body matching `CashierXReadingResponseDto`'s shape (see the example in the design doc). Confirm `totalSales` and `totalTransactions` roughly match what's visible for that cashier on the Transactions screen for today. Stop the dev server after checking (`Ctrl+C`).

- [ ] **Step 4: Commit**

```bash
git add be/src/reports/reports.module.ts
git commit -m "feat(reports): register CashierXReadingReportService and its repositories"
```

---

## Task 7: Kiosk — add the API call and raw schema

**Files:**
- Create: `kiosk/lib/data/backend_api/schemas/cashier_x_reading_dto.dart`
- Modify: `kiosk/lib/data/backend_api/sources/reports_api.dart`

- [ ] **Step 1: Write the schema**

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'cashier_x_reading_dto.mapper.dart';

@MappableClass()
class NameAmountDto with NameAmountDtoMappable {
  const NameAmountDto({required this.name, required this.amount});

  final String name;
  final double amount;
}

@MappableClass()
class CashierXReadingDto with CashierXReadingDtoMappable {
  const CashierXReadingDto({
    required this.cashierName,
    required this.terminalName,
    required this.businessDate,
    required this.reportGeneratedAt,
    required this.salesByPaymentMethod,
    required this.totalSales,
    required this.totalTransactions,
    required this.completedTransactions,
    required this.voidedTransactions,
    required this.refundedTransactions,
    required this.discounts,
    required this.totalDiscounts,
    required this.vatSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.cashCollected,
    required this.averageSale,
    required this.highestSale,
    required this.lowestSale,
    required this.totalQuantitySold,
  });

  final String cashierName;
  final String terminalName;
  final String businessDate;
  final String reportGeneratedAt;
  final List<NameAmountDto> salesByPaymentMethod;
  final double totalSales;
  final int totalTransactions;
  final int completedTransactions;
  final int voidedTransactions;
  final int refundedTransactions;
  final List<NameAmountDto> discounts;
  final double totalDiscounts;
  final double vatSales;
  final double vatAmount;
  final double vatExemptSales;
  final double cashCollected;
  final double averageSale;
  final double highestSale;
  final double lowestSale;
  final int totalQuantitySold;

  static const fromJson = CashierXReadingDtoMapper.fromJson;
}
```

- [ ] **Step 2: Add the API method**

In `kiosk/lib/data/backend_api/sources/reports_api.dart`, add an import near the other schema imports:

```dart
import '../schemas/cashier_x_reading_dto.dart';
```

Then add this method inside the `ReportsApi` class, after `getSalesByPayment`:

```dart
  Future<CashierXReadingDto> getCashierXReading() async {
    final response = await _httpClient.get<dynamic>('/api/v1/reports/cashier-x-reading');
    return CashierXReadingDto.fromJson(jsonEncode(response.data));
  }
```

- [ ] **Step 3: Generate the mapper code**

Run: `cd kiosk && fvm dart run build_runner build --delete-conflicting-outputs`
Expected: Completes with `cashier_x_reading_dto.mapper.dart` generated alongside the schema file, no errors.

- [ ] **Step 4: Analyze**

Run: `cd kiosk && fvm dart analyze lib/data/backend_api`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/data/backend_api/schemas/cashier_x_reading_dto.dart kiosk/lib/data/backend_api/schemas/cashier_x_reading_dto.mapper.dart kiosk/lib/data/backend_api/sources/reports_api.dart
git commit -m "feat(kiosk): add cashier X-Reading API call and schema"
```

---

## Task 8: Kiosk — add the domain entity and mapper

**Files:**
- Create: `kiosk/lib/features/cashier_report/entities/cashier_x_reading.dart`
- Create: `kiosk/lib/features/cashier_report/mappers/cashier_x_reading_mappers.dart`

- [ ] **Step 1: Write the entity**

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'cashier_x_reading.mapper.dart';

@MappableClass()
class NameAmount with NameAmountMappable {
  const NameAmount({required this.name, required this.amount});

  final String name;
  final double amount;
}

@MappableClass()
class CashierXReading with CashierXReadingMappable {
  const CashierXReading({
    required this.cashierName,
    required this.terminalName,
    required this.businessDate,
    required this.reportGeneratedAt,
    required this.salesByPaymentMethod,
    required this.totalSales,
    required this.totalTransactions,
    required this.completedTransactions,
    required this.voidedTransactions,
    required this.refundedTransactions,
    required this.discounts,
    required this.totalDiscounts,
    required this.vatSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.cashCollected,
    required this.averageSale,
    required this.highestSale,
    required this.lowestSale,
    required this.totalQuantitySold,
  });

  final String cashierName;
  final String terminalName;
  final String businessDate;
  final DateTime reportGeneratedAt;
  final List<NameAmount> salesByPaymentMethod;
  final double totalSales;
  final int totalTransactions;
  final int completedTransactions;
  final int voidedTransactions;
  final int refundedTransactions;
  final List<NameAmount> discounts;
  final double totalDiscounts;
  final double vatSales;
  final double vatAmount;
  final double vatExemptSales;
  final double cashCollected;
  final double averageSale;
  final double highestSale;
  final double lowestSale;
  final int totalQuantitySold;
}
```

- [ ] **Step 2: Write the mapper extension**

```dart
import '../../../data/backend_api/schemas/cashier_x_reading_dto.dart';
import '../entities/cashier_x_reading.dart';

extension NameAmountDTOMapper on NameAmountDto {
  NameAmount get toEntity => NameAmount(name: name, amount: amount);
}

extension CashierXReadingDTOMapper on CashierXReadingDto {
  CashierXReading get toEntity => CashierXReading(
    cashierName: cashierName,
    terminalName: terminalName,
    businessDate: businessDate,
    reportGeneratedAt: DateTime.parse(reportGeneratedAt),
    salesByPaymentMethod: salesByPaymentMethod.map((e) => e.toEntity).toList(),
    totalSales: totalSales,
    totalTransactions: totalTransactions,
    completedTransactions: completedTransactions,
    voidedTransactions: voidedTransactions,
    refundedTransactions: refundedTransactions,
    discounts: discounts.map((e) => e.toEntity).toList(),
    totalDiscounts: totalDiscounts,
    vatSales: vatSales,
    vatAmount: vatAmount,
    vatExemptSales: vatExemptSales,
    cashCollected: cashCollected,
    averageSale: averageSale,
    highestSale: highestSale,
    lowestSale: lowestSale,
    totalQuantitySold: totalQuantitySold,
  );
}
```

- [ ] **Step 3: Generate the mapper code**

Run: `cd kiosk && fvm dart run build_runner build --delete-conflicting-outputs`
Expected: `cashier_x_reading.mapper.dart` generated, no errors.

- [ ] **Step 4: Analyze**

Run: `cd kiosk && fvm dart analyze lib/features/cashier_report`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/features/cashier_report/entities kiosk/lib/features/cashier_report/mappers
git commit -m "feat(kiosk): add CashierXReading entity and DTO mapper"
```

---

## Task 9: Kiosk — add the repository

**Files:**
- Create: `kiosk/lib/features/cashier_report/repositories/cashier_report_repository.dart`

- [ ] **Step 1: Write the repository**

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/reports_api.dart';
import '../entities/cashier_x_reading.dart';
import '../mappers/cashier_x_reading_mappers.dart';

abstract class CashierReportRepository {
  Future<CashierXReading> getXReading();
}

final cashierReportRepositoryProvider = Provider<CashierReportRepository>((ref) {
  final reportsApi = ref.watch(reportsApiProvider);
  return CashierReportRepositoryImpl(reportsApi: reportsApi);
});

class CashierReportRepositoryImpl implements CashierReportRepository {
  CashierReportRepositoryImpl({required ReportsApi reportsApi}) : _reportsApi = reportsApi;

  final ReportsApi _reportsApi;

  @override
  Future<CashierXReading> getXReading() async {
    final dto = await _reportsApi.getCashierXReading();
    return dto.toEntity;
  }
}
```

- [ ] **Step 2: Analyze**

Run: `cd kiosk && fvm dart analyze lib/features/cashier_report`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/cashier_report/repositories
git commit -m "feat(kiosk): add CashierReportRepository"
```

---

## Task 10: Kiosk — add the state notifier (TDD)

**Files:**
- Create: `kiosk/lib/features/cashier_report/state/cashier_x_reading_notifier.dart`
- Test: `kiosk/test/features/cashier_report/state/cashier_x_reading_notifier_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_app/features/cashier_report/entities/cashier_x_reading.dart';
import 'package:pos_app/features/cashier_report/repositories/cashier_report_repository.dart';
import 'package:pos_app/features/cashier_report/state/cashier_x_reading_notifier.dart';

CashierXReading _report() => CashierXReading(
  cashierName: 'Juan Dela Cruz',
  terminalName: 'POS-01',
  businessDate: '07/09/2026',
  reportGeneratedAt: DateTime(2026, 7, 9, 14, 32),
  salesByPaymentMethod: const [NameAmount(name: 'Cash', amount: 100)],
  totalSales: 100,
  totalTransactions: 1,
  completedTransactions: 1,
  voidedTransactions: 0,
  refundedTransactions: 0,
  discounts: const [],
  totalDiscounts: 0,
  vatSales: 89.29,
  vatAmount: 10.71,
  vatExemptSales: 0,
  cashCollected: 100,
  averageSale: 100,
  highestSale: 100,
  lowestSale: 100,
  totalQuantitySold: 2,
);

class _FakeCashierReportRepository implements CashierReportRepository {
  _FakeCashierReportRepository(this.report);

  CashierXReading report;
  int callCount = 0;

  @override
  Future<CashierXReading> getXReading() async {
    callCount++;
    return report;
  }
}

class _ThrowingCashierReportRepository implements CashierReportRepository {
  @override
  Future<CashierXReading> getXReading() async {
    throw Exception('network error');
  }
}

void main() {
  test('load() fetches the report and exposes it as data', () async {
    final repo = _FakeCashierReportRepository(_report());
    final container = ProviderContainer(
      overrides: [cashierReportRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    expect(container.read(cashierXReadingNotifierProvider).value, isNull);

    await container.read(cashierXReadingNotifierProvider.notifier).load();

    final state = container.read(cashierXReadingNotifierProvider);
    expect(state.value?.cashierName, 'Juan Dela Cruz');
    expect(repo.callCount, 1);
  });

  test('load() surfaces repository errors as AsyncError', () async {
    final container = ProviderContainer(
      overrides: [
        cashierReportRepositoryProvider.overrideWithValue(_ThrowingCashierReportRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(cashierXReadingNotifierProvider.notifier).load();

    expect(container.read(cashierXReadingNotifierProvider).hasError, isTrue);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd kiosk && fvm flutter test test/features/cashier_report/state/cashier_x_reading_notifier_test.dart`
Expected: FAIL — `cashier_x_reading_notifier.dart` and `cashierXReadingNotifierProvider` don't exist yet (compile error).

- [ ] **Step 3: Write the notifier**

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/printer/win32_printer.dart';
import '../entities/cashier_x_reading.dart';
import '../repositories/cashier_report_repository.dart';
import '../use_cases/encode_esc_pos_cashier_report.dart';

final cashierXReadingNotifierProvider =
    NotifierProvider.autoDispose<CashierXReadingNotifier, AsyncValue<CashierXReading?>>(
      CashierXReadingNotifier.new,
      name: 'cashierXReadingNotifierProvider',
    );

class CashierXReadingNotifier extends Notifier<AsyncValue<CashierXReading?>> {
  static final printAction = Mutation<void>();

  @override
  AsyncValue<CashierXReading?> build() => const AsyncValue.data(null);

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(cashierReportRepositoryProvider);
      final report = await repository.getXReading();
      state = AsyncValue.data(report);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> print() async {
    final report = state.value;
    if (report == null) return;
    if (kIsWeb || !Platform.isWindows) return;

    final encode = ref.read(encodeEscPosCashierReportProvider);
    final data = await encode(report: report);

    final printerTransport = ref.read(win32PrinterTransportProvider);
    await printerTransport.sendData(data);
  }
}
```

This depends on `encode_esc_pos_cashier_report.dart`, written in Task 12. For this task, create a minimal placeholder so the notifier compiles and the test can pass — Task 12 replaces it with the real implementation:

Create `kiosk/lib/features/cashier_report/use_cases/encode_esc_pos_cashier_report.dart`:

```dart
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/cashier_x_reading.dart';

final encodeEscPosCashierReportProvider = Provider<EncodeEscPosCashierReport>((ref) {
  return EncodeEscPosCashierReport();
});

class EncodeEscPosCashierReport {
  Future<Uint8List> call({required CashierXReading report}) async {
    throw UnimplementedError('Replaced by the full ESC/POS encoder in Task 12.');
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd kiosk && fvm flutter test test/features/cashier_report/state/cashier_x_reading_notifier_test.dart`
Expected: PASS (2 tests). The `print()` method isn't exercised by this test, so the placeholder encoder throwing `UnimplementedError` doesn't affect it.

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/features/cashier_report/state kiosk/lib/features/cashier_report/use_cases kiosk/test/features/cashier_report
git commit -m "feat(kiosk): add CashierXReadingNotifier with load/print"
```

---

## Task 11: Kiosk — register the route

**Files:**
- Create: `kiosk/lib/navigation/cashier_report_route.dart`
- Modify: `kiosk/lib/navigation/router.dart`

- [ ] **Step 1: Write the route file**

```dart
part of 'router.dart';

@TypedGoRoute<CashierReportRoute>(path: '/cashier-report')
class CashierReportRoute extends GoRouteData with $CashierReportRoute {
  const CashierReportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CashierReportPreviewScreen();
  }
}
```

- [ ] **Step 2: Register it in router.dart**

In `kiosk/lib/navigation/router.dart`, add an import alongside the other screen imports. Import order doesn't affect compilation, but to keep the existing alphabetical-by-feature-folder convention, insert it right after the `auth` imports (line 7) and before the `catalog` import (line 8):

```dart
import '../features/cashier_report/view/cashier_report_preview_screen.dart';
```

And add a `part` declaration alongside the others (alphabetically, between `catalog_route.dart` and `login_route.dart`):

```dart
part 'cashier_report_route.dart';
```

The full `part` list becomes:

```dart
part 'cashier_report_route.dart';
part 'catalog_route.dart';
part 'login_route.dart';
part 'menu_route.dart';
part 'onboarding_route.dart';
part 'router.g.dart';
part 'sales_report_route.dart';
part 'sales_route.dart';
part 'setup_pin_route.dart';
part 'startup_route.dart';
part 'transactions_route.dart';
part 'user_management_route.dart';
```

This references `CashierReportPreviewScreen`, which is created in Task 13. Router codegen (next step) will fail until that file exists with the right class name — that's expected and resolved by Task 13.

- [ ] **Step 3: Note on codegen**

Do not run `build_runner` yet — `CashierReportPreviewScreen` doesn't exist until Task 13. Running it now will fail with an unresolved import. This task's own compile/analyze check is deferred to Task 13's Step, which runs `build_runner` once both the route and the screen exist.

- [ ] **Step 4: Commit**

```bash
git add kiosk/lib/navigation/cashier_report_route.dart kiosk/lib/navigation/router.dart
git commit -m "feat(kiosk): register CashierReportRoute"
```

---

## Task 12: Kiosk — implement the real ESC/POS encoder

**Files:**
- Modify: `kiosk/lib/features/cashier_report/use_cases/encode_esc_pos_cashier_report.dart`

- [ ] **Step 1: Replace the placeholder with the real encoder**

```dart
import 'dart:isolate';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/cashier_x_reading.dart';

final encodeEscPosCashierReportProvider = Provider<EncodeEscPosCashierReport>((ref) {
  return EncodeEscPosCashierReport();
});

class EncodeEscPosCashierReport {
  Future<Uint8List> call({required CashierXReading report}) async {
    final profile = await CapabilityProfile.load();

    return Isolate.run(() async {
      var bytes = <int>[];
      final generator = Generator(PaperSize.mm80, profile);

      bytes += generator.text(
        'CASHIER REPORT (X READING)',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'Not a Z Reading - no reset',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      bytes += generator.text('Cashier: ${report.cashierName}');
      bytes += generator.text('Terminal: ${report.terminalName}');
      bytes += generator.text('Business Date: ${report.businessDate}');
      bytes += generator.text('Generated: ${report.reportGeneratedAt.toLocal()}');
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'SALES SUMMARY');
      for (final row in report.salesByPaymentMethod) {
        bytes += _amountRow(generator, row.name, row.amount);
      }
      bytes += _amountRow(generator, 'Total Sales', report.totalSales, bold: true);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'TRANSACTION SUMMARY');
      bytes += _countRow(generator, 'Total', report.totalTransactions);
      bytes += _countRow(generator, 'Completed', report.completedTransactions);
      bytes += _countRow(generator, 'Voided', report.voidedTransactions);
      bytes += _countRow(generator, 'Refunded', report.refundedTransactions);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'DISCOUNT SUMMARY');
      for (final row in report.discounts) {
        bytes += _amountRow(generator, row.name, row.amount);
      }
      bytes += _amountRow(generator, 'Total Discounts', report.totalDiscounts, bold: true);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'TAX SUMMARY');
      bytes += _amountRow(generator, 'VAT Sales', report.vatSales);
      bytes += _amountRow(generator, 'VAT Amount', report.vatAmount);
      bytes += _amountRow(generator, 'VAT-Exempt Sales', report.vatExemptSales);
      bytes += _divider(generator);

      bytes += _amountRow(generator, 'Cash Collected', report.cashCollected, bold: true);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'OTHER SUMMARY');
      bytes += _amountRow(generator, 'Average Sale', report.averageSale);
      bytes += _amountRow(generator, 'Highest Sale', report.highestSale);
      bytes += _amountRow(generator, 'Lowest Sale', report.lowestSale);
      bytes += _countRow(generator, 'Total Qty Sold', report.totalQuantitySold);

      bytes += generator.feed(3);
      bytes += generator.cut();

      return Uint8List.fromList(bytes);
    });
  }

  List<int> _sectionHeader(Generator generator, String title) {
    return generator.text(title, styles: const PosStyles(bold: true));
  }

  List<int> _divider(Generator generator) {
    return generator.text(
      '------------------------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
  }

  List<int> _amountRow(Generator generator, String label, double amount, {bool bold = false}) {
    return generator.row([
      PosColumn(text: label, width: 8, styles: PosStyles(bold: bold)),
      PosColumn(
        text: amount.toStringAsFixed(2),
        width: 4,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }

  List<int> _countRow(Generator generator, String label, int value) {
    return generator.row([
      PosColumn(text: label, width: 8),
      PosColumn(text: '$value', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
  }
}
```

No logo/image block — this is an internal operational report, not a customer-facing receipt.

- [ ] **Step 2: Re-run the notifier test to confirm nothing broke**

Run: `cd kiosk && fvm flutter test test/features/cashier_report/state/cashier_x_reading_notifier_test.dart`
Expected: PASS (2 tests) — unchanged, since these tests don't exercise `print()`.

- [ ] **Step 3: Analyze**

Run: `cd kiosk && fvm dart analyze lib/features/cashier_report`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add kiosk/lib/features/cashier_report/use_cases/encode_esc_pos_cashier_report.dart
git commit -m "feat(kiosk): implement ESC/POS encoder for cashier X-Reading"
```

---

## Task 13: Kiosk — build the preview screen

**Files:**
- Create: `kiosk/lib/features/cashier_report/view/cashier_report_preview_screen.dart`

- [ ] **Step 1: Write the screen**

```dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/cashier_x_reading.dart';
import '../state/cashier_x_reading_notifier.dart';

class CashierReportPreviewScreen extends ConsumerWidget {
  const CashierReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashierXReadingNotifierProvider);

    final body = Column(
      children: [
        const TopAppBar(title: 'Cashier Report'),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator(color: ColorSet.primary)),
            error:
                (error, _) => _ErrorView(
                  onRetry: () => ref.read(cashierXReadingNotifierProvider.notifier).load(),
                ),
            data: (report) {
              if (report == null) return const SizedBox.shrink();
              return _ReportPreview(report: report);
            },
          ),
        ),
      ],
    );

    return WindowsScaffold(backgroundColor: ColorSet.background, body: body);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: ColorSet.danger, size: 40),
          const Gap(12),
          const Text(
            'Failed to load cashier report',
            style: TextStyle(color: POSColors.textPrimary),
          ),
          const Gap(12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview({required this.report});

  final CashierXReading report;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                width: r.value<double>(kiosk: 400, tablet: 360, phone: 320),
                margin: EdgeInsets.symmetric(
                  vertical: r.value<double>(kiosk: 24, tablet: 20, phone: 14),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: r.value<double>(kiosk: 20, tablet: 18, phone: 14),
                  vertical: r.value<double>(kiosk: 24, tablet: 20, phone: 16),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(POSRadius.xs),
                  boxShadow: POSShadow.card,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CASHIER REPORT (X READING)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 16, tablet: 15, phone: 14),
                        fontWeight: FontWeight.w800,
                        color: ColorSet.primary,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'Not a Z Reading — no reset',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 11, tablet: 11, phone: 10),
                        color: POSColors.textTertiary,
                      ),
                    ),
                    const Gap(8),
                    const _Divider(),
                    const Gap(6),
                    _KeyValueRow('Cashier', report.cashierName),
                    _KeyValueRow('Terminal', report.terminalName),
                    _KeyValueRow('Business Date', report.businessDate),
                    _KeyValueRow(
                      'Generated',
                      DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal()),
                    ),
                    const Gap(6),
                    const _Divider(),
                    const Gap(6),
                    _Section(
                      title: 'SALES SUMMARY',
                      rows: [
                        for (final entry in report.salesByPaymentMethod)
                          _AmountRow(entry.name, entry.amount),
                        _AmountRow('Total Sales', report.totalSales, bold: true),
                      ],
                    ),
                    _Section(
                      title: 'TRANSACTION SUMMARY',
                      rows: [
                        _CountRow('Total', report.totalTransactions),
                        _CountRow('Completed', report.completedTransactions),
                        _CountRow('Voided', report.voidedTransactions),
                        _CountRow('Refunded', report.refundedTransactions),
                      ],
                    ),
                    _Section(
                      title: 'DISCOUNT SUMMARY',
                      rows: [
                        for (final entry in report.discounts) _AmountRow(entry.name, entry.amount),
                        _AmountRow('Total Discounts', report.totalDiscounts, bold: true),
                      ],
                    ),
                    _Section(
                      title: 'TAX SUMMARY',
                      rows: [
                        _AmountRow('VAT Sales', report.vatSales),
                        _AmountRow('VAT Amount', report.vatAmount),
                        _AmountRow('VAT-Exempt Sales', report.vatExemptSales),
                      ],
                    ),
                    _Section(
                      title: 'CASH COLLECTED',
                      rows: [_AmountRow('Cash Collected', report.cashCollected, bold: true)],
                    ),
                    _Section(
                      title: 'OTHER SUMMARY',
                      rows: [
                        _AmountRow('Average Sale', report.averageSale),
                        _AmountRow('Highest Sale', report.highestSale),
                        _AmountRow('Lowest Sale', report.lowestSale),
                        _CountRow('Total Qty Sold', report.totalQuantitySold),
                      ],
                      showDividerAfter: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            r.value<double>(kiosk: 48, tablet: 32, phone: 20),
            0,
            r.value<double>(kiosk: 48, tablet: 32, phone: 20),
            r.value<double>(kiosk: 24, tablet: 20, phone: 16),
          ),
          child: const _PrintButton(),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows, this.showDividerAfter = true});

  final String title;
  final List<Widget> rows;
  final bool showDividerAfter;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 12, tablet: 12, phone: 11),
              fontWeight: FontWeight.w700,
              color: ColorSet.primary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const Gap(4),
        ...rows,
        const Gap(6),
        if (showDividerAfter) ...[const _Divider(), const Gap(6)],
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final style = TextStyle(fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.amount, {this.bold = false});

  final String label;
  final double amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final style = TextStyle(
      fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12),
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    final decimalAmount = Decimal.parse(amount.toStringAsFixed(2));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(decimalAmount.pesoFormatted, style: style)],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final style = TextStyle(fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text('$value', style: style)],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6;
        final dashCount = (boxWidth / dashWidth).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => const Text('-', style: TextStyle(fontSize: 10)),
          ),
        );
      },
    );
  }
}

class _PrintButton extends ConsumerWidget {
  const _PrintButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final printAction = CashierXReadingNotifier.printAction;
    final printStatus = ref.watch(printAction);
    final isPending = printStatus is MutationPending;

    return SizedBox(
      width: double.infinity,
      height: r.value<double>(kiosk: 56, tablet: 50, phone: 44),
      child: FilledButton.icon(
        onPressed:
            isPending
                ? null
                : () {
                  printAction.run(ref, (txn) {
                    return txn.get(cashierXReadingNotifierProvider.notifier).print();
                  }).ignore();
                },
        icon:
            isPending
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                : const Icon(Icons.print_rounded),
        label: Text(isPending ? 'Printing...' : 'Print Report'),
        style: FilledButton.styleFrom(
          backgroundColor: ColorSet.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.full)),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Generate router codegen now that both the route (Task 11) and this screen exist**

Run: `cd kiosk && fvm dart run build_runner build --delete-conflicting-outputs`
Expected: Completes with `router.g.dart` regenerated to include `CashierReportRoute`/`$CashierReportRoute`, no errors.

- [ ] **Step 3: Analyze**

Run: `cd kiosk && fvm dart analyze lib/features/cashier_report lib/navigation`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add kiosk/lib/features/cashier_report/view kiosk/lib/navigation/router.g.dart
git commit -m "feat(kiosk): add cashier X-Reading preview screen"
```

---

## Task 14: Kiosk — wire the button on the Transactions screen

**Files:**
- Modify: `kiosk/lib/features/sales/view/transactions_screen.dart`

- [ ] **Step 1: Add the import**

In `kiosk/lib/features/sales/view/transactions_screen.dart`, add this import alongside the other feature imports (after the `void_transaction_dialog` import at line 25):

```dart
import '../../cashier_report/state/cashier_x_reading_notifier.dart';
```

- [ ] **Step 2: Wire the TopAppBar trailing slot**

Change line 67 from:

```dart
          const TopAppBar(title: 'Transactions'),
```

to:

```dart
          TopAppBar(title: 'Transactions', trailing: const _CashierReportButton()),
```

- [ ] **Step 3: Add the button widget**

Add this new class right after the closing brace of `TransactionsScreen` (after line 105, before the `// ── Pagination + filter controls` comment):

```dart
class _CashierReportButton extends ConsumerWidget {
  const _CashierReportButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final isLoading = ref.watch(cashierXReadingNotifierProvider.select((it) => it.isLoading));

    return SizedBox(
      height: r.value<double>(kiosk: 40, tablet: 36, phone: 32),
      child: FilledButton.icon(
        onPressed:
            isLoading
                ? null
                : () async {
                  await ref.read(cashierXReadingNotifierProvider.notifier).load();
                  if (context.mounted) {
                    await const CashierReportRoute().push<void>(context);
                  }
                },
        icon:
            isLoading
                ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ColorSet.primary),
                )
                : Icon(
                  Icons.receipt_long_rounded,
                  size: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
                ),
        label: Text(
          'Cashier Report',
          style: TextStyle(fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11)),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: ColorSet.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.full)),
          padding: EdgeInsets.symmetric(
            horizontal: r.value<double>(kiosk: 16, tablet: 14, phone: 10),
          ),
        ),
      ),
    );
  }
}
```

`CashierReportRoute` doesn't need a separate import — it's declared `part of 'router.dart'`, and `transactions_screen.dart` already imports `../../../navigation/router.dart` at line 9.

- [ ] **Step 4: Analyze**

Run: `cd kiosk && fvm dart analyze lib/features/sales/view/transactions_screen.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/features/sales/view/transactions_screen.dart
git commit -m "feat(kiosk): add Cashier Report button to Transactions screen"
```

---

## Task 15: End-to-end manual verification

**Files:** none (verification only)

- [ ] **Step 1: Start the backend**

Run: `cd be && npm run start:dev`
Expected: Server starts, `GET http://localhost:3000/api/v1/health` returns 200.

- [ ] **Step 2: Run the kiosk app on Windows**

Run: `cd kiosk && fvm flutter run -d windows`
Expected: App builds and launches.

- [ ] **Step 3: Walk the golden path**

1. Log in as a cashier user who has at least one sales order dated today.
2. Navigate to the Transactions screen.
3. Confirm a "Cashier Report" button is visible in the top-right of the app bar.
4. Tap it. Confirm it briefly shows a loading spinner, then navigates to the Cashier Report preview screen.
5. Confirm the preview shows: Cashier Information, Sales Summary (with a Total Sales line), Transaction Summary, Discount Summary, Tax Summary, Cash Collected, Other Summary — all populated with real numbers.
6. Cross-check `Total Sales` and the transaction counts against what's visible in the Transactions table for today for this cashier.
7. Tap "Print Report". Confirm it doesn't throw, shows a "Printing..." state, and (if a printer is configured) a receipt prints matching the on-screen preview section-for-section.
8. Go back to the Transactions screen. Confirm nothing else on that screen changed — table, pagination, search, void/refund actions all still behave exactly as before this feature was added.
9. Repeat the "Cashier Report" tap a second time. Confirm no totals reset, no error, and (if a new sale was rung up in between) the numbers reflect the new total — proving it's a live, repeatable read, not a one-time snapshot.

- [ ] **Step 4: Report results**

If any step fails, note which one and the observed vs. expected behavior before moving on — do not mark this task complete until the golden path works end-to-end.
