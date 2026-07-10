# Design: Multiple "Other" Payment Methods

## Problem

`PosTerminalDetailsDialog` (`kiosk/lib/features/settings/view/pos_terminal_details_dialog.dart`) lets a terminal register one payment method entry per `PaymentMethod` enum value. This blocks adding more than one "Other" entry (e.g. a user cannot register both "PayMaya" and "Bitcoin" as separate Other payment methods) because the dropdown filters out any `PaymentMethod` value already present on the terminal, including `PaymentMethod.other`.

The backend (`PosTerminalsService`, `PosTerminalPaymentMethod` entity) has no uniqueness constraint on `paymentMethod` — the one-per-type restriction is enforced purely client-side. So this is a Flutter-only change.

## Scope

Single file: `kiosk/lib/features/settings/view/pos_terminal_details_dialog.dart`. No backend, DTO, or schema changes.

## Behavior

- **Cash, GCash, Credit Card**: unchanged — capped at one entry each per terminal (Credit Card remains excluded from the dropdown entirely, as today).
- **Other**: no longer capped. The "Other" option remains selectable in the dropdown regardless of how many Other entries already exist.
- **Duplicate name guard**: since multiple Other entries are distinguished only by their custom `paymentMethodName`, adding or editing an Other entry whose trimmed, case-insensitive name matches an existing Other entry on the same terminal is blocked with a form validation error: "A payment method with this name already exists." When editing an entry, that entry itself is excluded from the comparison so leaving the name unchanged doesn't self-conflict.

## Implementation

1. Replace `resolveExistingMethods({int? excludeId})` (currently maps entries to `List<PaymentMethod>`) with `resolveExistingEntries({int? excludeId})`, returning the raw `List<PaymentMethodEntryDto>` (terminal's payment methods, minus the entry with `excludeId` if given). Raw entries are needed because the dedupe check operates on `paymentMethodName`, not the enum.

2. `_PaymentMethodFormDialog` changes its `existingMethods: List<PaymentMethod>` field to `existingEntries: List<PaymentMethodEntryDto>`. Inside `build()`, derive:
   - `existingTypes`: enum values of entries where `paymentMethod != 'Other'`, mapped via the existing `PaymentMethod.values.firstWhere(...)` pattern. Used to filter the dropdown (`availableMethods`).
   - `existingOtherNames`: `Set<String>` of trimmed, lowercased `paymentMethodName` for entries where `paymentMethod == 'Other'` (skipping null/empty names). Used only by the name validator.

3. `availableMethods` becomes:
   ```dart
   PaymentMethod.values
       .where((m) => m != PaymentMethod.creditCard && (m == PaymentMethod.other || !existingTypes.contains(m)))
       .toList()
   ```

4. The "Payment Method Name" `TextFormField` validator (shown only when `selectedMethod.value == PaymentMethod.other`) becomes:
   ```dart
   validator: (v) {
     final trimmed = (v ?? '').trim();
     if (trimmed.isEmpty) return 'Payment method name is required';
     if (existingOtherNames.contains(trimmed.toLowerCase())) {
       return 'A payment method with this name already exists';
     }
     return null;
   },
   ```

5. Update call sites `onAddPaymentMethod` and `onEditPaymentMethod` in `PosTerminalDetailsDialog.build()` to call `resolveExistingEntries(...)` instead of `resolveExistingMethods(...)` and pass the result as `existingEntries:`.

## Out of scope

- No backend/API changes.
- No changes to `_PaymentMethodTile` or `_PaymentMethodsSection` rendering — both already display Other entries by their custom name and support an arbitrary-length list.
- No changes to Cash/GCash/Credit Card capping behavior.

## Testing

Manual verification in the running kiosk app (dev mode):
1. Add an Other entry named "PayMaya" — succeeds, dropdown still shows "Other" afterward.
2. Add a second Other entry named "Bitcoin" — succeeds.
3. Attempt to add a third Other entry named "paymaya " (different case/whitespace) — blocked with validation error.
4. Edit the "PayMaya" entry without changing its name — saves successfully (no self-conflict).
5. Edit the "Bitcoin" entry, renaming it to "PayMaya" — blocked with validation error.
6. Cash/GCash still disappear from the dropdown once one of each exists; Credit Card never appears.
