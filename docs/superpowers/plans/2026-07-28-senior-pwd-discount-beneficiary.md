# Senior/PWD Discount Beneficiary Name Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a required "Name of ID Holder" field to the Senior/PWD discount flow, persist both the ID number and name end-to-end (kiosk → backend → receipt) instead of the ID number being silently dropped as it is today, and make multiple beneficiaries per order a visible, reviewable cashier workflow.

**Architecture:** The beneficiary fields ride on the existing per-`SalesOrderItem`/per-`LineItem` discount mechanism — no new table. Each item independently carries its own `discountBeneficiaryIdNumber`/`discountBeneficiaryName`, so multiple beneficiaries in one order fall out of the existing "apply discount to a subset of items" flow with zero new data-model risk. The kiosk gains a grouping UI that surfaces which beneficiary covers which items.

**Tech Stack:** NestJS + TypeORM + PostgreSQL (backend), Flutter + Riverpod + dart_mappable (kiosk).

**Spec:** `docs/superpowers/specs/2026-07-28-senior-pwd-discount-beneficiary-design.md`

---

## Task 1: Backend migration — add beneficiary columns to `so_items`

**Files:**
- Create: `be/src/database/migrations/1785000000000-so-items-discount-beneficiary.ts`
- Modify: `be/src/database/migrations/index.ts`

- [ ] **Step 1: Check the current end of `index.ts` to see the existing export pattern**

Run: `tail -5 be/src/database/migrations/index.ts` (or open the file) — confirm it's a flat array/object of migration class exports keyed or listed in timestamp order, matching the existing `ZReadings1784000000000` entry.

- [ ] **Step 2: Write the migration**

```ts
import { MigrationInterface, QueryRunner } from 'typeorm';

export class SoItemsDiscountBeneficiary1785000000000 implements MigrationInterface {
  name = 'SoItemsDiscountBeneficiary1785000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "so_items"
        ADD COLUMN "discount_beneficiary_id_number" varchar(100),
        ADD COLUMN "discount_beneficiary_name" varchar(255)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "so_items"
        DROP COLUMN "discount_beneficiary_name",
        DROP COLUMN "discount_beneficiary_id_number"
    `);
  }
}
```

- [ ] **Step 3: Register the migration in `index.ts`**

Add the import and export entry following the exact same pattern as the existing `ZReadings1784000000000` entry (same file, same list/array/object shape — copy the surrounding syntax exactly).

- [ ] **Step 4: Apply the migration against the dev database**

Run: `cd be && npm run migration:up`
Expected: output confirms `SoItemsDiscountBeneficiary1785000000000` executed successfully, no errors.

- [ ] **Step 5: Verify the down migration also works**

Run: `cd be && npm run migration:down` then `npm run migration:up` again (to leave the DB in the up state).
Expected: both commands succeed with no errors; column drop/add round-trips cleanly.

- [ ] **Step 6: Commit**

```bash
cd be
git add src/database/migrations/1785000000000-so-items-discount-beneficiary.ts src/database/migrations/index.ts
git commit -m "feat: add discount beneficiary columns to so_items"
```

---

## Task 2: `SalesOrderItem` entity — add beneficiary fields

**Files:**
- Modify: `be/src/sales-orders/entities/sales-order-item.entity.ts:95` (right after the `itemDiscountedPrice` column)

- [ ] **Step 1: Add the two new columns to the entity**

Insert immediately after the `itemDiscountedPrice` column block (currently lines 97-104):

```ts
  @Column({
    type: 'varchar',
    length: 100,
    nullable: true,
    name: 'discount_beneficiary_id_number',
  })
  discountBeneficiaryIdNumber: string | null;

  @Column({
    type: 'varchar',
    length: 255,
    nullable: true,
    name: 'discount_beneficiary_name',
  })
  discountBeneficiaryName: string | null;
```

- [ ] **Step 2: Confirm the backend still builds**

Run: `cd be && npm run build`
Expected: build succeeds with no TypeScript errors.

- [ ] **Step 3: Commit**

```bash
cd be
git add src/sales-orders/entities/sales-order-item.entity.ts
git commit -m "feat: add discount beneficiary fields to SalesOrderItem entity"
```

---

## Task 3: `ApplyDiscountItemDiscountDto` — add optional beneficiary fields

**Files:**
- Modify: `be/src/sales-orders/dto/add-discount/apply-discount-item-discount.dto.ts`
- Test: `be/src/sales-orders/dto/add-discount/apply-discount-item-discount.dto.spec.ts`

- [ ] **Step 1: Write the failing validation test**

```ts
import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { ApplyDiscountItemDiscountDto } from './apply-discount-item-discount.dto';

describe('ApplyDiscountItemDiscountDto', () => {
  it('accepts idNumber and beneficiaryName as optional strings', async () => {
    const dto = plainToInstance(ApplyDiscountItemDiscountDto, {
      id: 1,
      name: 'Senior Citizen / PWD',
      value: 20,
      idNumber: 'SC-2024-00001',
      beneficiaryName: 'Juan Dela Cruz',
    });

    const errors = await validate(dto);

    expect(errors).toHaveLength(0);
    expect(dto.idNumber).toBe('SC-2024-00001');
    expect(dto.beneficiaryName).toBe('Juan Dela Cruz');
  });

  it('is still valid when idNumber and beneficiaryName are omitted', async () => {
    const dto = plainToInstance(ApplyDiscountItemDiscountDto, {
      id: 2,
      name: 'Promo Code',
      value: 10,
    });

    const errors = await validate(dto);

    expect(errors).toHaveLength(0);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd be && npx jest --testPathPattern=src/sales-orders/dto/add-discount/apply-discount-item-discount.dto.spec.ts`
Expected: FAIL — `dto.idNumber`/`dto.beneficiaryName` are `undefined` because the properties don't exist yet (or TypeScript compile error referencing unknown properties).

- [ ] **Step 3: Add the two optional fields to the DTO**

```ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Discount applied to a sales order item (e.g. Senior Citizen / PWD).
 */
export class ApplyDiscountItemDiscountDto {
  @ApiProperty({ description: 'Discount ID', example: 1 })
  @IsNumber()
  @Type(() => Number)
  id: number;

  @ApiProperty({ description: 'Discount name', example: 'Senior Citizen / PWD' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Discount value (e.g. percentage)', example: 20 })
  @IsNumber()
  @Type(() => Number)
  value: number;

  @ApiPropertyOptional({
    description: 'Beneficiary ID number (Senior Citizen/PWD discounts only)',
    example: 'SC-2024-00001',
  })
  @IsOptional()
  @IsString()
  idNumber?: string;

  @ApiPropertyOptional({
    description: "Beneficiary's name (Senior Citizen/PWD discounts only)",
    example: 'Juan Dela Cruz',
  })
  @IsOptional()
  @IsString()
  beneficiaryName?: string;
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd be && npx jest --testPathPattern=src/sales-orders/dto/add-discount/apply-discount-item-discount.dto.spec.ts`
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
cd be
git add src/sales-orders/dto/add-discount/apply-discount-item-discount.dto.ts src/sales-orders/dto/add-discount/apply-discount-item-discount.dto.spec.ts
git commit -m "feat: accept optional beneficiary id/name on ApplyDiscountItemDiscountDto"
```

---

## Task 4: `ApplyDiscountToItemMapper.applyDiscountAmountsToItem` — persist beneficiary fields

**Files:**
- Modify: `be/src/sales-orders/mapper/apply-discount-to-item.mapper.ts:41-54`
- Create: `be/src/sales-orders/mapper/apply-discount-to-item.mapper.spec.ts`

- [ ] **Step 1: Write the failing test**

```ts
import { ApplyDiscountToItemMapper } from './apply-discount-to-item.mapper';
import { SalesOrderItem } from '../entities/sales-order-item.entity';
import { User } from '../../users/entities/user.entity';
import { ItemDiscountAmounts } from '../sales-order.interface';

describe('ApplyDiscountToItemMapper.applyDiscountAmountsToItem', () => {
  const amounts: ItemDiscountAmounts = {
    discountedUnitPrice: '80.000000',
    subTotalAmount: '80.000000',
    totalAmount: '80.000000',
    vatAmount: '0.000000',
  };
  const causer = { id: 'user-1' } as User;

  it('persists beneficiary id number and name when provided', () => {
    const item = new SalesOrderItem();

    ApplyDiscountToItemMapper.applyDiscountAmountsToItem(item, 20, amounts, causer, {
      idNumber: 'SC-2024-00001',
      beneficiaryName: 'Juan Dela Cruz',
    });

    expect(item.discountBeneficiaryIdNumber).toBe('SC-2024-00001');
    expect(item.discountBeneficiaryName).toBe('Juan Dela Cruz');
  });

  it('leaves beneficiary fields null when not provided', () => {
    const item = new SalesOrderItem();

    ApplyDiscountToItemMapper.applyDiscountAmountsToItem(item, 10, amounts, causer);

    expect(item.discountBeneficiaryIdNumber).toBeNull();
    expect(item.discountBeneficiaryName).toBeNull();
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd be && npx jest --testPathPattern=src/sales-orders/mapper/apply-discount-to-item.mapper.spec.ts`
Expected: FAIL — either a TypeScript error (extra 5th argument not accepted) or `item.discountBeneficiaryIdNumber` is `undefined` instead of the expected value.

- [ ] **Step 3: Update the mapper method signature and body**

Replace `applyDiscountAmountsToItem` (currently lines 41-54):

```ts
  /**
   * Applies discount fields to a sales order item (mutates the item). Beneficiary fields are only
   * set when provided (Senior Citizen/PWD discounts); otherwise they're left null.
   */
  static applyDiscountAmountsToItem(
    item: SalesOrderItem,
    itemDiscountRate: number,
    amounts: ItemDiscountAmounts,
    causer: User,
    beneficiary?: { idNumber?: string; beneficiaryName?: string },
  ): void {
    item.itemDiscountRate = itemDiscountRate.toFixed(DECIMAL_PLACES);
    item.itemDiscountedPrice = amounts.discountedUnitPrice;
    item.itemTotalAmount = amounts.totalAmount;
    item.vatAmount = amounts.vatAmount;
    item.itemSubtotal = amounts.subTotalAmount;
    item.itemTotalAmount = amounts.totalAmount;
    item.discountBeneficiaryIdNumber = beneficiary?.idNumber ?? null;
    item.discountBeneficiaryName = beneficiary?.beneficiaryName ?? null;
    item.updatedBy = causer;
  }
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd be && npx jest --testPathPattern=src/sales-orders/mapper/apply-discount-to-item.mapper.spec.ts`
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
cd be
git add src/sales-orders/mapper/apply-discount-to-item.mapper.ts src/sales-orders/mapper/apply-discount-to-item.mapper.spec.ts
git commit -m "feat: persist discount beneficiary id/name in ApplyDiscountToItemMapper"
```

---

## Task 5: `SalesOrderItemBuildService` — wire beneficiary data through all call sites

**Files:**
- Modify: `be/src/sales-orders/services/sales-order-item-build.service.ts:97-102,125-130,254-259,274-279`
- Test: `be/src/sales-orders/services/sales-order-item-build.service.spec.ts` (existing file — add cases, don't replace it)

- [ ] **Step 1: Write the failing test (append to the existing spec file)**

Add a new `describe` block to `be/src/sales-orders/services/sales-order-item-build.service.spec.ts`, reusing the existing `buildService`/`buildProductDto` helpers already defined in that file:

```ts
describe('SalesOrderItemBuildService.generateSalesOrderItems (Senior/PWD beneficiary)', () => {
  function buildServiceWithDiscount(variant: ProductVariant, discount: { id: number; name: string; value: string; type: string }) {
    const recipesService = {
      findRecipeIdsByProductVariantIds: jest.fn().mockResolvedValue(new Map()),
    };
    const productsService = {
      findProductVariantsByIds: jest.fn().mockResolvedValue(new Map([[variant.id, variant]])),
    };
    const modifierGroupsService = {
      findModifierOptionWithRelationById: jest.fn().mockResolvedValue(new Map()),
    };
    const discountsService = {
      findByIdsToMap: jest.fn().mockResolvedValue(new Map([[discount.id, discount]])),
    };

    return new SalesOrderItemBuildService(
      recipesService as never,
      productsService as never,
      modifierGroupsService as never,
      {} as never,
      {} as never,
      discountsService as never,
    );
  }

  const variant = {
    id: 9,
    name: 'Large',
    product: { name: 'Latte' },
  } as unknown as ProductVariant;

  const discount = { id: 1, name: 'Senior Citizen / PWD', value: '20', type: 'PERCENTAGE' };

  it('persists the beneficiary id number and name onto the sales order item', async () => {
    const service = buildServiceWithDiscount(variant, discount);
    const productDto = {
      productVariantId: 9,
      quantity: 4,
      price: 337,
      modifierGroups: [],
      discount: {
        id: 1,
        name: 'Senior Citizen / PWD',
        value: 20,
        idNumber: 'SC-2024-00001',
        beneficiaryName: 'Juan Dela Cruz',
      },
    } as unknown as CreateSalesOrderItemDto;

    const { salesOrderItems } = await service.generateSalesOrderItems([productDto], {} as User);

    expect(salesOrderItems[0].discountBeneficiaryIdNumber).toBe('SC-2024-00001');
    expect(salesOrderItems[0].discountBeneficiaryName).toBe('Juan Dela Cruz');
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd be && npx jest --testPathPattern=src/sales-orders/services/sales-order-item-build.service.spec.ts`
Expected: FAIL — `discountBeneficiaryIdNumber`/`discountBeneficiaryName` are `undefined` because nothing passes them through yet.

- [ ] **Step 3: Update the 4 `applyDiscountAmountsToItem` call sites**

In `generateSalesOrderItems` (around line 97), pass the beneficiary object from `product.discount`:

```ts
        ApplyDiscountToItemMapper.applyDiscountAmountsToItem(
          salesOrderItem,
          parseFloat(discount.value),
          amounts,
          causer,
          { idNumber: product.discount.idNumber, beneficiaryName: product.discount.beneficiaryName },
        );
```

And the add-on call site right after it (around line 125), using the same `product.discount`:

```ts
          ApplyDiscountToItemMapper.applyDiscountAmountsToItem(
            addOnItem,
            parseFloat(discount.value),
            amounts,
            causer,
            { idNumber: product.discount.idNumber, beneficiaryName: product.discount.beneficiaryName },
          );
```

In `applyDiscountAndGetItemsToPush` (the child-item branch, around line 254), using `itemDto.discounts`:

```ts
      ApplyDiscountToItemMapper.applyDiscountAmountsToItem(
        childItem,
        ctx.discountValue,
        ctx.amounts,
        causer,
        { idNumber: itemDto.discounts.idNumber, beneficiaryName: itemDto.discounts.beneficiaryName },
      );
```

And the non-split branch right after it (around line 274):

```ts
    ApplyDiscountToItemMapper.applyDiscountAmountsToItem(
      ctx.existingItem,
      ctx.discountValue,
      ctx.amounts,
      causer,
      { idNumber: itemDto.discounts.idNumber, beneficiaryName: itemDto.discounts.beneficiaryName },
    );
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd be && npx jest --testPathPattern=src/sales-orders/services/sales-order-item-build.service.spec.ts`
Expected: PASS, all tests including the pre-existing "variant without recipe" cases.

- [ ] **Step 5: Commit**

```bash
cd be
git add src/sales-orders/services/sales-order-item-build.service.ts src/sales-orders/services/sales-order-item-build.service.spec.ts
git commit -m "feat: wire discount beneficiary id/name through sales order item build service"
```

---

## Task 6: Kiosk `ApplyDiscountItemDiscountDto` schema — add beneficiary fields

**Files:**
- Modify: `kiosk/lib/data/backend_api/schemas/apply_discount_item_discount_dto.dart`

- [ ] **Step 1: Add the two optional fields**

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'apply_discount_item_discount_dto.mapper.dart';

@MappableClass()
class ApplyDiscountItemDiscountDto with ApplyDiscountItemDiscountDtoMappable {
  const ApplyDiscountItemDiscountDto({
    required this.id,
    required this.name,
    required this.value,
    this.idNumber,
    this.beneficiaryName,
  });

  final int id;
  final String name;
  final double value;
  final String? idNumber;
  final String? beneficiaryName;

  static const fromJson = ApplyDiscountItemDiscountDtoMapper.fromJson;
}
```

- [ ] **Step 2: Regenerate mapper code**

Run: `cd kiosk && dart run build_runner build --delete-conflicting-outputs`
Expected: completes with `apply_discount_item_discount_dto.mapper.dart` regenerated, no errors.

- [ ] **Step 3: Commit**

```bash
cd kiosk
git add lib/data/backend_api/schemas/apply_discount_item_discount_dto.dart lib/data/backend_api/schemas/apply_discount_item_discount_dto.mapper.dart
git commit -m "feat: add optional beneficiary id/name to ApplyDiscountItemDiscountDto schema"
```

---

## Task 7: Kiosk `SeniorPwdDiscount` entity — add `beneficiaryName`

**Files:**
- Modify: `kiosk/lib/features/sales/entities/discount.dart:20-40`

- [ ] **Step 1: Add the required `beneficiaryName` field**

```dart
@MappableClass()
class SeniorPwdDiscount extends Discount with SeniorPwdDiscountMappable {
  const SeniorPwdDiscount({required this.beneficiaryId, required this.beneficiaryName});

  @override
  bool get isVatExempt => true;

  @override
  String get code => 'Senior Citizen / PWD';

  Decimal get rate => Decimal.fromInt(20);

  final String beneficiaryId;
  final String beneficiaryName;

  @override
  Decimal calculateAmount(Decimal originalAmount) {
    return (originalAmount.vatableAmount * rate / Decimal.fromInt(100))
        .toDecimal(scaleOnInfinitePrecision: 2)
        .toPrecision(2);
  }
}
```

- [ ] **Step 2: Regenerate mapper code**

Run: `cd kiosk && dart run build_runner build --delete-conflicting-outputs`
Expected: fails to fully complete OR completes but leaves the codebase with compile errors at every existing `SeniorPwdDiscount(beneficiaryId: ...)` call site (missing required `beneficiaryName` argument) — this is expected at this point in the plan; those call sites are fixed in Tasks 8-11. Confirm the mapper file itself (`discount.mapper.dart`) regenerated with a `beneficiaryName` reference.

- [ ] **Step 3: Commit**

```bash
cd kiosk
git add lib/features/sales/entities/discount.dart lib/features/sales/entities/discount.mapper.dart
git commit -m "feat: add required beneficiaryName to SeniorPwdDiscount"
```

---

## Task 8: Kiosk `sale_repository.dart` — send beneficiary fields to backend

**Files:**
- Modify: `kiosk/lib/features/sales/repositories/sale_repository.dart:85-93`

- [ ] **Step 1: Update `_applyDiscountItemDiscountDtoFromDiscount`**

```dart
  ApplyDiscountItemDiscountDto? _applyDiscountItemDiscountDtoFromDiscount(Discount? discount) {
    return switch (discount) {
      SeniorPwdDiscount(:final code, :final rate, :final beneficiaryId, :final beneficiaryName) =>
        ApplyDiscountItemDiscountDto(
          id: 1,
          name: code,
          value: rate.toDouble(),
          idNumber: beneficiaryId,
          beneficiaryName: beneficiaryName,
        ),
      _ => null,
    };
  }
```

This method currently has exactly these two arms (`SeniorPwdDiscount` and the `_ => null` fallback) — only the `SeniorPwdDiscount` arm's destructuring and constructor call change; the fallback is untouched.

- [ ] **Step 2: Confirm analyzer passes for this file**

Run: `cd kiosk && dart analyze lib/features/sales/repositories/sale_repository.dart`
Expected: no new errors introduced by this change (pre-existing unrelated errors, if any, are out of scope).

- [ ] **Step 3: Commit**

```bash
cd kiosk
git add lib/features/sales/repositories/sale_repository.dart
git commit -m "feat: send Senior/PWD beneficiary id and name to backend"
```

---

## Task 9: Kiosk `ReceiptItem` entity — add beneficiary fields

**Files:**
- Modify: `kiosk/lib/features/sales/entities/receipt_item.dart`

- [ ] **Step 1: Add the two nullable fields**

```dart
import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

import '../enums/sale_type.dart';

part 'receipt_item.mapper.dart';

@MappableClass()
class ReceiptItem with ReceiptItemMappable {
  const ReceiptItem({
    required this.id,
    required this.sequence,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.grossAmount,
    required this.discountCode,
    required this.discountRate,
    required this.discountAmount,
    required this.vatExclusiveAmount,
    required this.vatAmount,
    required this.totalAmount,
    required this.isMain,
    this.saleType,
    this.note,
    this.category,
    this.discountBeneficiaryIdNumber,
    this.discountBeneficiaryName,
  });

  final String id;
  final int sequence;
  final String description;
  final int quantity;
  final Decimal unitPrice;
  final Decimal grossAmount;
  final String discountCode;
  final Decimal discountRate;
  final Decimal discountAmount;
  final Decimal vatExclusiveAmount;
  final Decimal vatAmount;
  final Decimal totalAmount;
  final bool isMain;
  final SaleType? saleType;
  final String? note;
  final String? category;
  final String? discountBeneficiaryIdNumber;
  final String? discountBeneficiaryName;
}
```

- [ ] **Step 2: Regenerate mapper code**

Run: `cd kiosk && dart run build_runner build --delete-conflicting-outputs`
Expected: `receipt_item.mapper.dart` regenerated, no errors (all existing fields were optional/positional-safe, so no call sites break).

- [ ] **Step 3: Commit**

```bash
cd kiosk
git add lib/features/sales/entities/receipt_item.dart lib/features/sales/entities/receipt_item.mapper.dart
git commit -m "feat: add beneficiary id/name fields to ReceiptItem"
```

---

## Task 10: Kiosk `finalize_sale.dart` — populate beneficiary fields on the receipt

**Files:**
- Modify: `kiosk/lib/features/sales/use_cases/finalize_sale.dart:66-152`

- [ ] **Step 1: Update `_receiptItemFromLineItem` to populate the new fields**

In the method body (currently lines 66-103), add beneficiary extraction alongside the existing `discountCode`/`discountRate` computation and pass it into the returned `ReceiptItem`:

```dart
  ReceiptItem _receiptItemFromLineItem(LineItem lineItem, {required int sequence}) {
    final id = lineItem.id;
    final description = '${lineItem.variant.name} ${lineItem.productName}';

    final quantity = lineItem.quantity;
    final unitPrice = lineItem.variant.price;
    final grossAmount = Decimal.fromInt(quantity) * unitPrice;

    final discountCode = lineItem.discount?.code ?? '';
    final discountRate = switch (lineItem.discount) {
      final PercentageDiscount discount => discount.rate,
      final SeniorPwdDiscount discount => discount.rate,
      _ => Decimal.zero,
    };
    final discountAmount = lineItem.discount?.calculateAmount(grossAmount) ?? Decimal.zero;

    final beneficiaryIdNumber = switch (lineItem.discount) {
      final SeniorPwdDiscount discount => discount.beneficiaryId,
      _ => null,
    };
    final beneficiaryName = switch (lineItem.discount) {
      final SeniorPwdDiscount discount => discount.beneficiaryName,
      _ => null,
    };

    final isVatExempt = lineItem.isVatExempt;
    final vatExclusiveAmount = grossAmount.vatableAmount;
    final vatAmount = isVatExempt ? Decimal.zero : grossAmount.vatAmount;

    final totalAmount = vatExclusiveAmount + vatAmount - discountAmount;

    return ReceiptItem(
      id: id,
      sequence: sequence,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      grossAmount: grossAmount,
      discountCode: discountCode,
      discountRate: discountRate,
      discountAmount: discountAmount,
      vatExclusiveAmount: vatExclusiveAmount,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      isMain: true,
      discountBeneficiaryIdNumber: beneficiaryIdNumber,
      discountBeneficiaryName: beneficiaryName,
    );
  }
```

- [ ] **Step 2: Update `_receiptItemIListFromSelectedModifier` the same way**

In the method body (currently lines 105-152), add the same beneficiary extraction and pass it into the returned `ReceiptItem` for each option:

```dart
  IList<ReceiptItem> _receiptItemIListFromSelectedModifier(
    SelectedModifier modifier, {
    required int sequence,
    required LineItem lineItem,
  }) {
    final discountCode = lineItem.discount?.code ?? '';
    final discountRate = switch (lineItem.discount) {
      final PercentageDiscount discount => discount.rate,
      final SeniorPwdDiscount discount => discount.rate,
      _ => Decimal.zero,
    };
    final beneficiaryIdNumber = switch (lineItem.discount) {
      final SeniorPwdDiscount discount => discount.beneficiaryId,
      _ => null,
    };
    final beneficiaryName = switch (lineItem.discount) {
      final SeniorPwdDiscount discount => discount.beneficiaryName,
      _ => null,
    };

    return modifier.options.map((option) {
      final id = UuidV7.generate();
      final description = option.name;

      final quantity = lineItem.quantity;
      final unitPrice = option.price;
      final grossAmount = Decimal.fromInt(quantity) * unitPrice;

      final discountAmount = switch (lineItem.discount) {
        FixedAmountDiscount() => Decimal.zero, // Fixed discounts don't apply to add-ons
        final discount => discount?.calculateAmount(grossAmount) ?? Decimal.zero,
      };

      final isVatExempt = lineItem.isVatExempt;
      final vatExclusiveAmount = grossAmount.vatableAmount;
      final vatAmount = isVatExempt ? Decimal.zero : grossAmount.vatAmount;

      final totalAmount = vatExclusiveAmount + vatAmount - discountAmount;

      return ReceiptItem(
        id: id,
        sequence: sequence,
        description: description,
        quantity: quantity,
        unitPrice: unitPrice,
        grossAmount: grossAmount,
        discountCode: discountCode,
        discountRate: discountRate,
        discountAmount: discountAmount,
        vatExclusiveAmount: vatExclusiveAmount,
        vatAmount: vatAmount,
        totalAmount: totalAmount,
        isMain: false,
        discountBeneficiaryIdNumber: beneficiaryIdNumber,
        discountBeneficiaryName: beneficiaryName,
      );
    }).toIList();
  }
```

- [ ] **Step 3: Confirm analyzer passes**

Run: `cd kiosk && dart analyze lib/features/sales/use_cases/finalize_sale.dart`
Expected: no new errors.

- [ ] **Step 4: Commit**

```bash
cd kiosk
git add lib/features/sales/use_cases/finalize_sale.dart
git commit -m "feat: populate receipt items with Senior/PWD beneficiary info"
```

---

## Task 11: Kiosk — fix the two calculator-only `SeniorPwdDiscount` const usages

**Files:**
- Modify: `kiosk/lib/features/sales/view/discount_screen.dart:829` (`_SummarySection`)
- Modify: `kiosk/lib/features/sales/view/discount_screen.dart:1874` (`_DlgSummary`)

These two usages are calculator-only local constants (never sent anywhere) used purely to call `.calculateAmount()` for a live preview — they need a placeholder `beneficiaryName` to satisfy the now-required constructor parameter.

- [ ] **Step 1: Fix `_SummarySection` (around line 829)**

```dart
    if (selectedDiscountType == 'Senior/PWD') {
      const discount = SeniorPwdDiscount(beneficiaryId: 'for_calculator_use_only', beneficiaryName: '');
      vatExempt = grossAmount.vatAmount;
      discountAmount = discount.calculateAmount(grossAmount);
    }
```

- [ ] **Step 2: Fix `_DlgSummary` (around line 1874)**

```dart
    if (selectedType == 'Senior/PWD') {
      const discount = SeniorPwdDiscount(beneficiaryId: '', beneficiaryName: '');
      vatExempt = grossAmount.vatAmount;
      discountAmount = discount.calculateAmount(grossAmount);
    }
```

- [ ] **Step 3: Confirm analyzer passes for the file**

Run: `cd kiosk && dart analyze lib/features/sales/view/discount_screen.dart`
Expected: these two errors are gone; other errors from not-yet-fixed call sites (Tasks 12-13) still present at this point — that's expected mid-plan.

- [ ] **Step 4: Commit**

```bash
cd kiosk
git add lib/features/sales/view/discount_screen.dart
git commit -m "fix: satisfy required beneficiaryName in calculator-only SeniorPwdDiscount usages"
```

---

## Task 12: Kiosk `DiscountScreen` — add Name of ID Holder field

This is the full-screen discount flow (`_DiscountControlsView`, routed via `sales_route.dart`), separate from the dialog flow handled in Task 13.

**Files:**
- Modify: `kiosk/lib/features/sales/view/discount_screen.dart:26-107` (`DiscountScreen.build`, `onApplyDiscount`)
- Modify: `kiosk/lib/features/sales/view/discount_screen.dart:178-260` (`_LandscapeLayout`, `_PortraitLayout`)
- Modify: `kiosk/lib/features/sales/view/discount_screen.dart:617-792` (`_DiscountControlsView`)

- [ ] **Step 1: Change the `onApplyDiscount` callback shape in `DiscountScreen.build`**

Replace the `onApplyDiscount` function and its call signature (currently `void onApplyDiscount(String? idNumber)` at line 42):

```dart
    void onApplyDiscount(String? idNumber, String? beneficiaryName) {
      if (selectedQuantities.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select items to discount.')),
        );
        return;
      }

      if (selectedDiscountType.value == 'Senior/PWD') {
        ref.read(orderingProvider.notifier).applyDiscount(
          selectedQuantities.value,
          (item, quantity) => SeniorPwdDiscount(
            beneficiaryId: idNumber ?? '',
            beneficiaryName: beneficiaryName ?? '',
          ),
        );
      } else {
        ref.read(orderingProvider.notifier).applyDiscount(
          selectedQuantities.value,
          (item, quantity) => null,
        );
      }
      context.pop();
    }
```

- [ ] **Step 2: Update the `onApplyDiscount` type threaded through `_LandscapeLayout`/`_PortraitLayout`/`_DiscountControlsView`**

In all three places where `onApplyDiscount` is typed as `ValueChanged<String?>` (the constructor param in `_LandscapeLayout`, `_PortraitLayout`, and `_DiscountControlsView`), change the type to:

```dart
  final void Function(String? idNumber, String? beneficiaryName) onApplyDiscount;
```

This is a pure type-signature change in 3 places — the widgets just forward the callback down, no other logic changes.

- [ ] **Step 3: Add the name controller and field in `_DiscountControlsView`**

In `_DiscountControlsView.build` (currently starting line 632), add a second controller next to `idNumberController`:

```dart
    final idNumberController = useTextEditingController();
    final nameController = useTextEditingController();

    void validateAndSubmit() {
      if (formKey.currentState?.validate() ?? false) {
        onApplyDiscount(idNumberController.text, nameController.text);
      }
    }
```

Then, in the "ID / Promo field" section (currently lines 745-769), add the Name field right after the existing `TextBoxFormField` when Senior/PWD is selected:

```dart
                      // ID / Promo field
                      if (selectedDiscountType == 'Senior/PWD') ...[
                        TextBoxFormField(
                          controller: idNumberController,
                          label: 'ID Number',
                          maxLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          validator: Validate(rules: [isRequired()]).call,
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                          ),
                        ),
                        SizedBox(height: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
                        TextBoxFormField(
                          controller: nameController,
                          label: 'Name of ID Holder',
                          maxLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          validator: Validate(rules: [isRequired()]).call,
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                          ),
                        ),
                      ] else
                        TextBoxFormField(
                          controller: idNumberController,
                          label: 'Promo Code',
                          maxLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          validator: Validate(rules: [isRequired()]).call,
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                          ),
                        ),
```

- [ ] **Step 4: Confirm analyzer passes for the file**

Run: `cd kiosk && dart analyze lib/features/sales/view/discount_screen.dart`
Expected: no errors related to `DiscountScreen`/`_DiscountControlsView`/`_LandscapeLayout`/`_PortraitLayout`. Dialog-flow errors (Task 13) may still remain — expected at this point.

- [ ] **Step 5: Manual verification**

Run: `cd kiosk && flutter run -d windows`
Navigate to the discount screen (via the route in `sales_route.dart`), select Senior/PWD, select an item, confirm both "ID Number" and "Name of ID Holder" fields are required before Apply succeeds, and that applying stores both values (check via a subsequent screen or by inspecting the applied item's discount badge).

- [ ] **Step 6: Commit**

```bash
cd kiosk
git add lib/features/sales/view/discount_screen.dart
git commit -m "feat: add Name of ID Holder field to full-screen discount flow"
```

---

## Task 13: Kiosk discount dialog — add Name of ID Holder field

This is the dialog flow (`showDiscountDialog` / `_DiscountDialogContent` / `_DlgDiscountPanel`), opened from `ordering_screen.dart`.

**Files:**
- Modify: `kiosk/lib/features/sales/view/discount_screen.dart:972-1013` (`_DiscountDialogContent.build`)
- Modify: `kiosk/lib/features/sales/view/discount_screen.dart:1094-1150` (wiring into `_DlgDiscountPanel`)
- Modify: `kiosk/lib/features/sales/view/discount_screen.dart:1501-1638` (`_DlgDiscountPanel`)

- [ ] **Step 1: Add a name controller in `_DiscountDialogContent.build`**

```dart
    final codeController = useTextEditingController();
    final nameController = useTextEditingController();
```

Update `onTypeChanged` to also clear the new controller:

```dart
    void onTypeChanged(String v) {
      selectedDiscountType.value = v;
      codeController.clear();
      nameController.clear();
      formKey.currentState?.reset();
    }
```

Update `applyDiscount` to read both controllers:

```dart
    void applyDiscount() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (selectedQuantities.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one item to discount.')),
        );
        return;
      }
      if (selectedDiscountType.value == 'Senior/PWD') {
        ref.read(orderingProvider.notifier).applyDiscount(
          selectedQuantities.value,
          (item, quantity) => SeniorPwdDiscount(
            beneficiaryId: codeController.text,
            beneficiaryName: nameController.text,
          ),
        );
      }
      if (context.mounted) Navigator.of(context).pop();
    }
```

- [ ] **Step 2: Pass `nameController` down to `_DlgDiscountPanel` at both call sites (wide and narrow layout branches)**

In both places `_DlgDiscountPanel(...)` is constructed (the `isWide` branch and the fallback `Column` branch, both inside the `LayoutBuilder` in `_DiscountDialogContent.build`), add `nameController: nameController,` to the constructor call.

- [ ] **Step 3: Add the `nameController` field and Name input to `_DlgDiscountPanel`**

Add the field to the constructor:

```dart
class _DlgDiscountPanel extends StatelessWidget {
  const _DlgDiscountPanel({
    required this.formKey,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedQuantities,
    required this.codeController,
    required this.nameController,
    required this.onApply,
  });

  final GlobalKey<FormState> formKey;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final Map<String, int> selectedQuantities;
  final TextEditingController codeController;
  final TextEditingController nameController;
  final VoidCallback onApply;
```

Then, right after the existing `codeController` `TextFormField` (currently ending around line 1637 with the `errorBorder`/`focusedErrorBorder` block), add a Name field — only rendered when `isSenior` is true:

```dart
                  if (isSenior) ...[
                    SizedBox(height: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                    Text(
                      'NAME OF ID HOLDER',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: POSColors.textTertiary,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                        color: POSColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Name of ID Holder is required' : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. Juan Dela Cruz',
                        hintStyle: const TextStyle(
                          color: POSColors.textDisabled,
                          fontStyle: FontStyle.italic,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.person_outline_rounded, size: 18, color: POSColors.textTertiary),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
                          vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(POSRadius.md),
                          borderSide: const BorderSide(color: POSColors.borderDefault),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(POSRadius.md),
                          borderSide: const BorderSide(color: POSColors.borderDefault),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(POSRadius.md),
                          borderSide: const BorderSide(color: ColorSet.primary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(POSRadius.md),
                          borderSide: BorderSide(color: ColorSet.danger),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(POSRadius.md),
                          borderSide: BorderSide(color: ColorSet.danger, width: 1.5),
                        ),
                      ),
                    ),
                  ],
```

- [ ] **Step 4: Confirm analyzer passes for the file**

Run: `cd kiosk && dart analyze lib/features/sales/view/discount_screen.dart`
Expected: no errors anywhere in the file at this point (Tasks 11-13 combined resolve all `SeniorPwdDiscount` construction sites).

- [ ] **Step 5: Manual verification**

Run: `cd kiosk && flutter run -d windows`
From the ordering screen, open the discount dialog (`showDiscountDialog`), select Senior/PWD, select item(s), confirm both ID Number and Name of ID Holder are required, apply, and confirm the item locks with "Already Discounted".

- [ ] **Step 6: Commit**

```bash
cd kiosk
git add lib/features/sales/view/discount_screen.dart
git commit -m "feat: add Name of ID Holder field to discount dialog"
```

---

## Task 14: Kiosk discount dialog — Applied Discounts summary grouped by beneficiary

**Files:**
- Modify: `kiosk/lib/features/sales/view/discount_screen.dart:1159-1433` (`_DlgItemPanel`)

Currently, `_DlgItemPanel` renders every item and shows a generic `_AlreadyDiscountedBadge()` (line 1370-1371) for any locked item, with no beneficiary info. This task adds a grouped summary above the item list.

- [ ] **Step 1: Add a helper to group locked items by beneficiary, above `_DlgItemPanel.build`**

Add this top-level function near the bottom of the file (after the last class), or as a private static method — either is fine, follow whichever the file already leans toward for similar small helpers (there are none yet, so a top-level function is simplest):

```dart
/// Groups items already carrying a Senior/PWD discount by beneficiary (name + id number).
List<_BeneficiaryGroup> _groupDiscountedItemsByBeneficiary(IList<LineItem> items) {
  final groups = <String, _BeneficiaryGroup>{};

  for (final item in items) {
    final discount = item.discount;
    if (discount is! SeniorPwdDiscount) continue;

    final key = '${discount.beneficiaryName}|${discount.beneficiaryId}';
    final existing = groups[key];
    if (existing == null) {
      groups[key] = _BeneficiaryGroup(
        beneficiaryName: discount.beneficiaryName,
        beneficiaryId: discount.beneficiaryId,
        itemIds: [item.id],
        totalQuantity: item.quantity,
      );
    } else {
      groups[key] = existing.copyWith(
        itemIds: [...existing.itemIds, item.id],
        totalQuantity: existing.totalQuantity + item.quantity,
      );
    }
  }

  return groups.values.toList();
}

class _BeneficiaryGroup {
  const _BeneficiaryGroup({
    required this.beneficiaryName,
    required this.beneficiaryId,
    required this.itemIds,
    required this.totalQuantity,
  });

  final String beneficiaryName;
  final String beneficiaryId;
  final List<String> itemIds;
  final int totalQuantity;

  _BeneficiaryGroup copyWith({List<String>? itemIds, int? totalQuantity}) => _BeneficiaryGroup(
    beneficiaryName: beneficiaryName,
    beneficiaryId: beneficiaryId,
    itemIds: itemIds ?? this.itemIds,
    totalQuantity: totalQuantity ?? this.totalQuantity,
  );
}
```

- [ ] **Step 2: Render the summary in `_DlgItemPanel.build`, above the item list**

In `_DlgItemPanel.build` (currently starting line 1172), compute the groups and render a summary block right after the sub-header (`Divider(height: 1, ...)` at line 1234) and before the `Expanded(child: ListView.builder(...))`:

```dart
    final beneficiaryGroups = _groupDiscountedItemsByBeneficiary(items);
```

(add this line near the top of `build`, alongside the existing `allSelected` computation)

```dart
        const Divider(height: 1, color: POSColors.borderDefault),
        if (beneficiaryGroups.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(r.value<double>(kiosk: 10, tablet: 8, phone: 8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in beneficiaryGroups)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8EC),
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_rounded, size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${group.beneficiaryName} (${group.beneficiaryId})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${group.itemIds.length} item${group.itemIds.length == 1 ? "" : "s"} · ${group.totalQuantity} qty',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFFD97706)),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _removeBeneficiaryDiscount(context, ref, group),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFB91C1C),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Remove', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
```

Note: `_DlgItemPanel` is currently a `StatelessWidget`, not a `ConsumerWidget` — it receives `items`/`selectableItems` as plain constructor params (`IList<LineItem>`), with no `ref`. Convert it to `ConsumerWidget` (change `extends StatelessWidget` to `extends ConsumerWidget`, add `WidgetRef ref` to `build`'s signature) so the Remove button can call `ref.read(orderingProvider.notifier).clearDiscount(...)`.

- [ ] **Step 3: Implement `_removeBeneficiaryDiscount`**

Add this method alongside the other top-level helpers/classes added in Step 1. `clearDiscount` takes an `index` (int), not an item id, so this needs to resolve each grouped item's index in the current `sale.items` list before clearing — clear from the highest index down so earlier removals don't shift the indices of items still pending removal:

```dart
void _removeBeneficiaryDiscount(BuildContext context, WidgetRef ref, _BeneficiaryGroup group) {
  final items = ref.read(orderingProvider).value?.sale.items ?? const IList.empty();
  final indexes = [
    for (final itemId in group.itemIds) items.indexWhere((e) => e.id == itemId),
  ]..sort((a, b) => b.compareTo(a));

  for (final index in indexes) {
    if (index == -1) continue;
    ref.read(orderingProvider.notifier).clearDiscount(index: index);
  }
}
```

- [ ] **Step 4: Confirm analyzer passes for the file**

Run: `cd kiosk && dart analyze lib/features/sales/view/discount_screen.dart`
Expected: no errors. In particular confirm `_DlgItemPanel`'s two call sites (in `_DiscountDialogContent.build`'s `isWide` and fallback branches) still compile as a `ConsumerWidget` (no constructor changes needed there — `ConsumerWidget` is still constructed the same way as `StatelessWidget`).

- [ ] **Step 5: Manual verification**

Run: `cd kiosk && flutter run -d windows`
Apply a Senior/PWD discount to item(s) with beneficiary "Juan Dela Cruz / SC-2024-00001", then select different item(s) and apply again with beneficiary "Maria Santos / SC-2024-00042". Confirm the summary shows two distinct groups with correct item/qty counts, full (unmasked) ID numbers, and that tapping "Remove" on one group unlocks only that beneficiary's items.

- [ ] **Step 6: Commit**

```bash
cd kiosk
git add lib/features/sales/view/discount_screen.dart
git commit -m "feat: show applied Senior/PWD discounts grouped by beneficiary"
```

---

## Task 15: Kiosk on-screen receipt — show beneficiary info per item

**Files:**
- Modify: `kiosk/lib/features/sales/view/receipt_screen.dart:571-636` (`_ItemsView._buildItemRow`)

- [ ] **Step 1: Add a beneficiary line under discounted items**

Insert a new conditional block right after the existing sale-type/note block (currently lines 598-624) and before the `isPartiallyRefunded` block:

```dart
          if (item.isMain && item.discountBeneficiaryName != null)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                'LESS: ${item.discountCode} — ${item.discountBeneficiaryName} (${item.discountBeneficiaryIdNumber})',
                style: TextStyle(
                  fontSize: r.value<double>(kiosk: 11, tablet: 11, phone: 10),
                  color: ColorSet.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
```

- [ ] **Step 2: Confirm analyzer passes**

Run: `cd kiosk && dart analyze lib/features/sales/view/receipt_screen.dart`
Expected: no errors.

- [ ] **Step 3: Manual verification**

Run: `cd kiosk && flutter run -d windows`
Finalize a sale with a Senior/PWD discount applied to at least one item, open the receipt preview screen, confirm the "LESS: Senior Citizen / PWD — {name} ({id})" line appears directly under the discounted item.

- [ ] **Step 4: Commit**

```bash
cd kiosk
git add lib/features/sales/view/receipt_screen.dart
git commit -m "feat: show Senior/PWD beneficiary on the on-screen receipt"
```

---

## Task 16: Kiosk printed receipt (ESC/POS) — print beneficiary info per item

**Files:**
- Modify: `kiosk/lib/features/sales/use_cases/encode_esc_pos_receipt.dart:134-163`

Today the printed receipt has **no** per-item discount line at all — only an aggregate "Discount" total near the footer (already handled, unchanged). This task adds the missing per-item line.

- [ ] **Step 1: Add the beneficiary line to the item-printing loop**

Insert right after the existing sale-type/note block (currently lines 154-157) and before the `isPartiallyRefunded` block:

```dart
          if (item.isMain && (item.saleType != null || item.note != null)) {
            final tag = item.saleType != null ? '[${item.saleType!.displayName}] ' : '';
            bytes += generator.text(sanitizeForPrinter('  $tag${item.note ?? ''}'.trimRight()));
          }

          if (item.isMain && item.discountBeneficiaryName != null) {
            bytes += generator.text(
              sanitizeForPrinter(
                '  LESS: ${item.discountCode} - ${item.discountBeneficiaryName} (${item.discountBeneficiaryIdNumber})',
              ),
            );
          }

          if (isPartiallyRefunded) {
            bytes += generator.text('  (Refunded: $refundedQty of ${item.quantity})');
          }
```

- [ ] **Step 2: Confirm analyzer passes**

Run: `cd kiosk && dart analyze lib/features/sales/use_cases/encode_esc_pos_receipt.dart`
Expected: no errors.

- [ ] **Step 3: Manual verification**

Run: `cd kiosk && flutter run -d windows`
Finalize a sale with a Senior/PWD discount applied, print (or preview, if a physical printer isn't attached) the receipt, confirm the "LESS: Senior Citizen / PWD - {name} ({id})" line prints directly under the discounted item, above the "Refunded" line if both apply.

- [ ] **Step 4: Commit**

```bash
cd kiosk
git add lib/features/sales/use_cases/encode_esc_pos_receipt.dart
git commit -m "feat: print Senior/PWD beneficiary info per receipt line item"
```

---

## Task 17: Full regression pass

**Files:** none (verification only)

- [ ] **Step 1: Run the full backend test suite**

Run: `cd be && npm run test`
Expected: all tests pass, including the new ones added in Tasks 3-5. Per project history, ~27 pre-existing broken test suites are unrelated to this change — confirm no *new* failures beyond that known baseline.

- [ ] **Step 2: Run backend lint and check for stray reformatting**

Run: `cd be && npm run lint`
Then: `git status`
Expected: only files touched by this plan show as modified. If unrelated files were reformatted by `--fix`, revert those specific files (`git checkout -- <file>`) before committing anything further.

- [ ] **Step 3: Run kiosk analyzer across the whole project**

Run: `cd kiosk && dart analyze`
Expected: no errors introduced by this feature (pre-existing unrelated warnings, if any, are out of scope).

- [ ] **Step 4: Run existing kiosk unit tests**

Run: `cd kiosk && flutter test`
Expected: all tests pass, including `test/features/sales/state/ordering_notifier_test.dart` (confirms `applyDiscount`/`clearDiscount` still behave correctly with the new required `beneficiaryName` field).

- [ ] **Step 5: End-to-end manual walkthrough**

With `flutter run -d windows` and the backend running (`npm run start:dev`), place an order with 3+ items, apply Senior/PWD to a subset with beneficiary A, apply again to the remainder with beneficiary B, finalize the sale, and confirm:
- The Applied Discounts summary showed both beneficiaries correctly before finalizing.
- The on-screen receipt shows both beneficiaries' name+ID under their respective items.
- The printed (or previewed) receipt shows the same.
- Querying the `so_items` table for that order (e.g. via `psql` or a DB client) shows `discount_beneficiary_id_number`/`discount_beneficiary_name` populated correctly per row, matching which beneficiary covered which item.
