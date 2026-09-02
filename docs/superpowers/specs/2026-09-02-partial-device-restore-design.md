# Partial device restore — design

Date: 2026-09-02
Status: approved

## Problem

`POST /api/v1/device-transfer/import` refuses any archive whose `migrations`
table is not byte-identical to the target device's (`device-import.service.ts`
`assertCompatible`). A store trying to move to a replacement kiosk that runs a
slightly different app build gets **"Incompatible Backup"** and no way forward
except re-installing to line the versions up.

We want an opt-in path that accepts the archive anyway and imports only the data
the two devices have in common, reporting the rest as skipped.

## Scope

- **Backend**: opt-in "partial restore" path in the import flow. Export is
  unchanged — the archive already carries per-table column names + Postgres
  `udt` types, which is everything partial restore needs.
- **Kiosk**: a "Partial restore" toggle in the import dialog, threaded through
  controller → repository → api, plus a skipped-items summary on completion, and
  a "Retry as partial restore" action on the existing 409 dialog.
- Strict same-version full replace stays the default and is untouched.

## Backend

### Request flag

`ImportDeviceDto` gains an optional multipart field `partialRestore: 'true' |
'false'` (mirrors the existing `confirmReplace: 'true'` convention), default
absent → strict.

### Compatibility gate (`assertCompatible`)

| Check | Strict (default) | Partial |
|---|---|---|
| Archive format version ≠ supported | `409 Conflict` (payload genuinely unreadable) | same — still hard |
| Migration history differs | `409 Conflict` | skipped — proceed |

### Restore algorithm (`DbSnapshotService.restore`, new `{ partial }` option)

1. Read the target schema: `{ table -> { column -> { udt, omittable } } }`, where
   `omittable` = column is nullable **or** has a default **or** is identity **or**
   is generated.
2. `TRUNCATE ... RESTART IDENTITY CASCADE` every target table **except
   `migrations`** — the target keeps its own true migration history so future
   `migration:up` / app updates still behave. (Strict mode still truncates and
   reloads `migrations` as today.)
3. For each archive table:
   - **not on target** → skip, record `{ table, reason: "not present on this device" }`
   - `migrations` (partial only) → skip, record `{ table, reason: "kept this device's own migration history" }`
   - compute the by-name column intersection:
     - column in both but **`udt` differs** → drop it, record
       `{ table, column, reason: "type changed (<from> → <to>)" }`
     - column only in the archive → drop it, record
       `{ table, column, reason: "not present on this device" }`
     - a **required** target column (`!omittable`) is **missing** from the
       archive → skip the whole table, record
       `{ table, reason: "backup is missing required column \"x\"" }`
     - intersection empty → skip the table, record `{ table, reason: "no compatible columns" }`
   - insert using only the surviving columns (row values projected to those indices).
4. Reset sequences across all tables, as today.

FK checks are already disabled for the transaction
(`session_replication_role = 'replica'`), so partial data loads even with
dangling references — orphaned rows are possible and are the accepted trade-off
of this mode. The import stays fully transactional: any hard error rolls back and
the device is unchanged.

### Response

`DeviceImportSummaryDto` gains:

```ts
skipped: {
  tables:  { name: string; reason: string }[];
  columns: { table: string; column: string; reason: string }[];
}
```

`warnings` (empty-table notices from `collectWarnings`) is unchanged. In strict
mode `skipped` is always `{ tables: [], columns: [] }`.

## Kiosk

- `import_backup_dialog.dart`: a `partialRestore` toggle (off by default) with one
  line of explainer — *"Import only the data both devices have in common. Use when
  the backup is from a different app version."* Still gated by the existing
  supervisor auth + typed `REPLACE`.
- Thread the bool through `DeviceTransferController.import` → repository →
  `DeviceTransferApi.import` (adds the `partialRestore` form field).
- Mirror the `skipped` shape in `device_transfer_dto.dart` (`@MappableClass`,
  then `build_runner`).
- "Restore Complete" dialog: when `skipped` is non-empty, show a scrollable
  "Not imported" list under the record count.
- The existing `409` "Incompatible Backup" handler gains a secondary button
  **"Retry as partial restore"** that re-submits with the flag on.

## Tests

Backend unit tests only (kiosk tests skipped per repo convention):

- `db-snapshot.service.spec.ts` (new): partial-mode cases — archive table absent
  on target is skipped; archive-only column is dropped; changed-`udt` column is
  dropped; missing required target column skips the whole table; `migrations` is
  preserved (not truncated, not reloaded).
- `device-import.service.spec.ts`: migration mismatch is allowed through in
  partial mode; still `409` in strict; format-version mismatch is still `409` in
  both.
- `device-transfer.controller.spec.ts`: `partialRestore: 'true'` reaches
  `importService.import` as `true`; absent → `false`.

## Docs

- `docs/runbooks/kiosk-device-migration.md` — replace the "If you see
  Incompatible Backup" note with the partial-restore option and its caveats.
- root `CLAUDE.md` — extend the `device-transfer` paragraph.
