# Mobile Store ID — Design

## Problem

The mobile app's Store Information screen (`mobile/lib/features/settings/view/store_info_screen.dart`) has no concept of a store ID. The local `store_info` table (Drift/SQLite) stores name, address, tax rate, currency, receipt footer, TIN, and terminal name, but nothing that uniquely identifies the store installation.

## Goals

- A store ID is visible on the Store Information screen.
- If the local DB has no store ID saved, the user is prompted to set one before using the screen (required, no skip).
- The store ID is editable afterward via the normal form + Save button, same as the other fields.

## Data layer

`mobile/lib/core/database/tables/store_info_table.dart`
- Add `TextColumn get storeId => text().withDefault(const Constant(''))();`

`mobile/lib/core/database/app_database.dart`
- Bump `schemaVersion` from 11 to 12.
- In `onUpgrade`, add:
  ```dart
  if (from < 12) {
    if (!await _hasColumn('store_info', 'store_id')) {
      await m.addColumn(storeInfoTable, storeInfoTable.storeId);
    }
  }
  ```
  (follows the existing guarded-`addColumn` pattern used for versions 8–11)

`mobile/lib/features/settings/state/store_info_notifier.dart`
- `StoreInfoNotifier.save(...)` gains a `required String storeId` parameter, persisted via the existing `upsertStoreInfo` companion the same way as the other fields.

## ID generation

No new dependency. Add a small helper (e.g. in `store_info_screen.dart` or a `core/utils` file) that generates an 8-character uppercase alphanumeric ID using `dart:math`'s `Random.secure()`.

## UI flow

`mobile/lib/features/settings/view/store_info_screen.dart`

1. `StoreInfoScreen` watches `storeInfoProvider` as today. Once data resolves (`info != null && info.storeId.isNotEmpty`), render the form as usual, now including a "Store ID" field.
2. If `info == null || info.storeId.isEmpty`, instead of rendering the form immediately, show a blocking dialog (`barrierDismissible: false`, no cancel/skip action) pre-filled with a generated ID. The user can accept it or type their own, then confirm.
   - Confirming calls the notifier to persist just the `storeId` (reusing `save(...)` with the current/default values for the other fields) and the provider refresh causes the screen to re-render into the normal form.
3. "Basic Info" section gains a "Store ID" `TextFormField` (required, free text, same validation style as Store Name) alongside the existing fields. Editing it and pressing the existing "Save" button persists it like every other field.

## Out of scope

- No uniqueness validation against other stores (this is a single-store local app).
- No format/pattern restriction on the ID beyond "non-empty" — free text.
- No syncing of this ID to any backend (this mobile app has no backend calls today).
