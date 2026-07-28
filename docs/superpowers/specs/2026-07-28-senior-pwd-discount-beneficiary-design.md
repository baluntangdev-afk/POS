# Senior/PWD Discount Beneficiary Name — Design Spec

**Date:** 2026-07-28
**Branch:** feature/mobile-integration
**Scope:** Add a "Name of ID Holder" field alongside the existing Senior/PWD ID Number, persist both through to the backend and receipt (closing an existing gap where the ID number is silently dropped), and make multiple-beneficiaries-per-order a visible, reviewable cashier workflow.

---

## Problem

`SeniorPwdDiscount` (`kiosk/lib/features/sales/entities/discount.dart`) only stores `beneficiaryId` — there is no field for the ID holder's name. Worse, `beneficiaryId` is captured in the "Apply Discount" dialog but never actually sent to the backend: `_applyDiscountItemDiscountDtoFromDiscount` in `sale_repository.dart` only forwards `id`, `name` (the discount type's display name, not the person's name), and `rate`. Today the ID number is typed in, shown nowhere on the receipt, and discarded before the sale is saved.

Separately, because `discount` lives per `LineItem`/`SalesOrderItem`, the data model already permits different order items to carry different Senior/PWD beneficiaries — but there is no UI that surfaces this. Once an item is discounted it just shows a generic locked "Already Discounted" badge with no indication of *whose* discount it is, so a cashier serving a table with two senior citizens has no way to review who covers what before finalizing the sale.

## Goals

- Capture both ID Number and Name of ID Holder when applying a Senior/PWD discount; both required.
- Persist both fields end-to-end: kiosk entity → API request → `so_items` row → receipt.
- Make multiple beneficiaries per order a first-class, reviewable cashier workflow (not just an architectural accident).
- Print the beneficiary name and ID inline under each discounted receipt line.

## Non-goals

- No new beneficiary registry table — the two fields live directly on `so_items`, one row per line item, matching how discount rate/type already work per-item. A dedicated cross-order "senior citizens discounted" report table is out of scope unless a reporting need is identified later.
- No changes to `z-reading`/`x-reading`/cashier-daily-report aggregate discount totals — those stay aggregate-only.
- No masking/redaction of the ID nu mber in the kiosk UI — the summary list is cashier-facing only, shown in full (confirmed with user).
- No changes to Promo-type discount handling (`PercentageDiscount`, `FixedAmountDiscount`) — the two new fields stay null for those.

---

## Data model

### Kiosk entity (`kiosk/lib/features/sales/entities/discount.dart`)

`SeniorPwdDiscount` gains a required `beneficiaryName` field alongside the existing `beneficiaryId`:

```dart
class SeniorPwdDiscount extends Discount with SeniorPwdDiscountMappable {
  const SeniorPwdDiscount({required this.beneficiaryId, required this.beneficiaryName});
  final String beneficiaryId;
  final String beneficiaryName;
  ...
}
```

Run `dart run build_runner build --delete-conflicting-outputs` after this change (regenerates `discount.mapper.dart`).

### Backend migration

New migration (timestamp-named, added to `src/database/migrations/index.ts`) adds two nullable columns to `so_items`:

| Column | Type | Notes |
|---|---|---|
| `discount_beneficiary_id_number` | `varchar` | Nullable — only populated for Senior/PWD discounted rows |
| `discount_beneficiary_name` | `varchar` | Nullable — only populated for Senior/PWD discounted rows |

### `SalesOrderItem` entity (`be/src/sales-orders/entities/sales-order-item.entity.ts`)

Add matching fields:

```ts
@Column({ type: 'varchar', length: 100, nullable: true, name: 'discount_beneficiary_id_number' })
discountBeneficiaryIdNumber: string | null;

@Column({ type: 'varchar', length: 255, nullable: true, name: 'discount_beneficiary_name' })
discountBeneficiaryName: string | null;
```

### API contract (`ApplyDiscountItemDiscountDto`)

Add two optional fields, only populated by the kiosk for the Senior/PWD discount type:

```ts
@ApiPropertyOptional({ description: 'Beneficiary ID number (Senior/PWD only)' })
@IsOptional()
@IsString()
idNumber?: string;

@ApiPropertyOptional({ description: 'Beneficiary name (Senior/PWD only)' })
@IsOptional()
@IsString()
beneficiaryName?: string;
```

### Mapper (`ApplyDiscountToItemMapper.applyDiscountAmountsToItem`)

Accept and persist the two new values onto the `SalesOrderItem` when present (i.e., when the incoming DTO carries `idNumber`/`beneficiaryName`).

### Kiosk → backend request (`sale_repository.dart`, `_applyDiscountItemDiscountDtoFromDiscount`)

```dart
SeniorPwdDiscount(:final code, :final rate, :final beneficiaryId, :final beneficiaryName) =>
  ApplyDiscountItemDiscountDto(
    id: 1,
    name: code,
    value: rate.toDouble(),
    idNumber: beneficiaryId,
    beneficiaryName: beneficiaryName,
  ),
```

This is the fix for the existing bug — today `beneficiaryId` is captured but not included in this DTO construction at all.

### Multiple beneficiaries per order

No special-cased data structure is needed. Because the two new fields live on `so_items` (one row per line item), different items in the same order can carry different beneficiaries with zero collision risk — e.g., Item A/B tagged to "Juan Dela Cruz / SC-2024-00001", Item C tagged to "Maria Santos / SC-2024-00042", all under one sales order. The cashier runs the existing "Apply Discount" flow once per beneficiary, selecting only that beneficiary's items each time — mechanically identical to how discount type/rate already work per-item today.

---

## Kiosk UI changes

### Apply Discount dialog/screen (`discount_screen.dart`, `_DlgDiscountPanel` / `_DiscountControlsView`)

- The single "ID Number" field is joined by a second required field, "Name of ID Holder", shown together whenever Senior/PWD is the selected discount type. Both use the existing `Validate(rules: [isRequired()])` pattern; the Apply button stays gated on `formKey.currentState?.validate()` passing for both.
- `onApplyDiscount` / `applyDiscount` callbacks build `SeniorPwdDiscount(beneficiaryId: ..., beneficiaryName: ...)` from the two controllers instead of just one.

### Applied Discounts summary (new)

Once one or more items are locked with a Senior/PWD discount, a new section in the discount panel groups locked items by `(beneficiaryName, beneficiaryId)`:

- Each group renders as a compact row: full beneficiary name + full ID number (no masking — cashier-facing only) + count of items/qty covered.
- Each group has a "Remove" action that calls the existing `clearDiscount(index:)` (`ordering_notifier.dart:244`) for every item in that group, unlocking them for re-selection.
- This extends the existing per-item lock/lookup logic already in `_DlgItemPanel` (`isDiscounted`, `_AlreadyDiscountedBadge`) — the generic lock badge is joined by the beneficiary identity, it isn't replaced or restructured.

### Re-apply flow for a second beneficiary

Unchanged mechanically: cashier picks the next unlocked items, fills in the second person's ID + name, taps Apply. The summary list then shows two groups. No new screen or mode is introduced.

---

## Receipt changes

### `ReceiptItem` entity (`kiosk/lib/features/sales/entities/receipt_item.dart`)

Add two nullable fields:

```dart
final String? discountBeneficiaryIdNumber;
final String? discountBeneficiaryName;
```

### Population (`finalize_sale.dart`)

In `_receiptItemFromLineItem` and `_receiptItemIListFromSelectedModifier`, when `lineItem.discount` is a `SeniorPwdDiscount`, populate the two new fields from `beneficiaryId`/`beneficiaryName`; otherwise leave them null.

### Printed/on-screen layout

The existing per-item discount line (`"LESS: ${item.discount!.code}"`, both the on-screen cart badge in `_LineItemSelectionView` and the physical ESC/POS receipt template) becomes:

```
LESS: Senior Citizen / PWD — Juan Dela Cruz (SC-2024-00001)
```

Implementation needs to locate the ESC/POS print template (`printer` feature module) and update wherever `discountCode`/`discountRate` are currently rendered, appending ` — {name} ({idNumber})` when the two new fields are non-null.

### Reports (no change)

`z-reading`/`x-reading`/`cashier-daily-report` DTOs already aggregate Senior/PWD discount totals — this spec doesn't add beneficiary-level detail to those reports. Out of scope unless a reporting need surfaces later.

---

## Edge cases (covered by existing architecture, verify during implementation)

- **Removing a beneficiary's discount**: `clearDiscount` already works per-item; the new "Remove" action in the summary list just needs to call it for each item in the beneficiary's group.
- **Partial-quantity discount split**: when only part of a line's quantity is discounted, `ordering_notifier.dart:105-114` already creates a child `LineItem` via `copyWith` — the two new fields ride along automatically since they're just additional constructor fields on `SeniorPwdDiscount`.
- **Non-Senior/PWD discounts**: `beneficiaryId`/`beneficiaryName` and their backend/receipt counterparts stay null throughout for `PercentageDiscount`/`FixedAmountDiscount`.

---

## Testing

- **Backend**: unit tests for `ApplyDiscountToItemMapper.applyDiscountAmountsToItem` (new fields persisted when present, left null otherwise), DTO validation for the two new optional fields, and a migration up/down check.
- **Kiosk**: widget/unit test coverage for the two-field validation gating Apply, the beneficiary grouping logic in the new summary section, and `finalize_sale.dart`'s receipt-item population of the two new fields.
- **Manual verification**: apply Senior/PWD discount to a subset of items with beneficiary A, apply again to remaining items with beneficiary B, confirm the summary list shows two distinct groups with correct item counts, finalize the sale, and confirm both beneficiaries' name+ID print inline under their respective items on the receipt.

---

## Open questions to resolve during implementation (not blocking spec approval)

- Exact location of the ESC/POS print template file(s) under the `printer` feature module that render `discountCode`/`discountRate` today — needs a grep pass during plan-writing, not guessed here.
