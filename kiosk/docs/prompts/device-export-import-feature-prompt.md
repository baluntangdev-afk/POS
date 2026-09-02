# Prompt: Device Export / Import (Full Migration) Feature

> Paste everything below the line into a fresh Claude Code session started at the
> repo root (`C:\Users\Jufiel\Documents\POS_ENTERPRISE\POS_KIOSK`). It is written
> to be self-contained. The implementing session **will** need to touch both
> `be/` and `kiosk/` — this is an approved exception to the usual "kiosk UI only"
> rule because the data being exported lives in the backend's PostgreSQL, not on
> the Flutter device.

---

## Task

Build an **Export** and **Import** feature that lets an **Admin or Supervisor**
copy the *entire* contents of one kiosk installation and restore it onto another
kiosk installation. This is a **device-migration / full-restore** tool: the export
is a single **encrypted `.zip` archive**, and import performs a **full replace**
(wipe the target, load the archive verbatim).

### Confirmed product decisions (do not re-litigate these)

| Decision | Choice |
|---|---|
| What data | **Full backend dataset** — everything in the local Postgres DB, plus the kiosk device-local state needed to bring the new machine online |
| Primary purpose | **Device migration** (old kiosk machine → new kiosk machine) |
| Import behaviour | **Full replace / restore** — target data is wiped and replaced. Destructive; requires strong confirmation |
| File format | **Encrypted `.zip` archive**, saved to / picked from a location the admin chooses |
| Who can use it | Role `admin` or `supervisor` only (`kiosk/lib/features/menu/enums/role.dart`) |

---

## Before writing code

1. Invoke the **`superpowers:brainstorming`** skill and walk the requirements
   below into a short design doc under `docs/superpowers/specs/`.
2. Then invoke **`superpowers:writing-plans`** to produce an implementation plan
   under `docs/superpowers/plans/`.
3. Follow the repo's existing patterns. Read the "Architecture" sections of both
   `CLAUDE.md` and `kiosk/CLAUDE.md` first.
4. **Do not create git commits** unless explicitly asked (see `CLAUDE.md` → Git Rules).

---

## Context you need

### The system shape

- `be/` — NestJS + TypeORM + PostgreSQL. In production it runs as the Windows
  service `POSBackendService` alongside a bundled PostgreSQL 16 service
  (`POSPostgres`), data dir `C:\posdata\`. API root `http://localhost:3000/api/v1`.
- `kiosk/` — Flutter Windows app, a thin client to that backend. Local persistence
  is minimal:
  - `kiosk/lib/core/database/app_database.dart` — a drift DB (`kiosk_pos`) that
    currently only holds `order_events` (an offline order-sync queue).
  - `kiosk/lib/data/secure_storage/` — auth token + **merchant/device
    registration** (see recent commit `e0d6509 feat: Implement merchant device
    registration and storage`).
  - `kiosk/lib/data/shared_preferences/` — user grant prefs, small UI state.
- The installer bundles all three (Flutter app, backend SEA, Postgres) onto one
  machine. "The kiosk device" therefore means *that whole machine*.

### Existing precedents to mirror

- **CSV product import** already does a smaller version of this pattern:
  - Kiosk UI: `kiosk/lib/features/inventory/view/import_products_csv_dialog.dart`
    (file picker, `upsert` vs `replace` mode, a red destructive-confirmation
    `showMessageDialog` for `replace`, result summary dialog).
  - Kiosk repo call: `InventoryRepository.importProductsCsv` in
    `kiosk/lib/features/inventory/data/inventory_repository.dart` →
    `POST /api/v1/products/import-csv` as multipart `FormData`.
  - Backend side handles the transactional replace. Find it with
    `grep -rn "import-csv" be/src` and copy its transaction / delete-then-insert
    approach.
- **Report export + "mark exported"**: `kiosk/lib/data/backend_api/sources/reports_api.dart`
  (`getExportable`, `markExported`) and recent commit `0d3b78c` (email CSV export).
- **HTTP clients**: `kiosk/lib/data/backend_api/api_clients.dart` —
  `secureApiClientProvider` (JWT via `tokenInterceptor`) is the one to use.
- **Menu entry + role gating**: `kiosk/lib/features/menu/view/menu_grid.dart`
  (`_getMenuItems`, the `role == Role.user` filter), `menu_screen.dart`,
  `kiosk/lib/features/menu/enums/menu_type.dart`. There is already a `syncData`
  menu type; add the new entries the same way.
- **Typed routing**: `kiosk/lib/navigation/router.dart` + `part` route files +
  `go_router_builder` codegen.
- **Dialogs / design system**: `kiosk/lib/widgets/message_dialog.dart`,
  `kiosk/lib/theme/pos_design.dart`, `context.responsive.value(...)`. Follow
  `kiosk/CLAUDE.md` (touch-first, 8px system, brand teal `0xFF1B7A8C`).
- Packages already in `kiosk/pubspec.yaml`: `file_picker`, `share_plus`,
  `archive`, `drift`, `path_provider` is **not** present — check before using it;
  prefer `file_picker`'s `saveFile` / `pickFiles(withData: true)` like the CSV
  dialog does.

---

## Backend requirements (`be/`)

Create a new module, e.g. `src/device-transfer/` (follow the standard module
layout in `CLAUDE.md`: `dto/`, `services/` one file per use-case, controller,
module). Suggested endpoints under the global `api/v1` prefix, JWT-guarded,
restricted to admin/supervisor:

### `POST /api/v1/device-transfer/export`

- Body: `{ passphrase: string }` (min length enforced, e.g. ≥ 12 chars).
- Produces a single **encrypted zip** streamed back as
  `application/octet-stream` (attachment). Internals:
  - A `manifest.json`: schema/export format version, backend app version, DB
    name, source device/merchant identifiers, row counts per table, UTC
    timestamp, and the **list of migrations applied** (read from the TypeORM
    `migrations` table) so import can refuse a mismatched target.
  - One file per table/domain (JSON or NDJSON), covering **all** business data.
    Enumerate the real tables by inspecting the entities under `be/src/*/entities/`
    and the migrations in `be/src/database/migrations/` — at minimum:
    users / employees + PINs, roles/access, POS terminals & device/merchant
    registration, stores/locations, product groups & categories, products,
    product variants, modifier groups, modifier options, product↔modifier-group
    junction (`product_modifier_groups`), sales orders + items + modifiers,
    payments, refunds + refund items, discounts/promos, cashier X-reading /
    daily-report / Z-reading history, `order_events` if persisted server-side,
    sequences/counters (receipt numbers, OR numbers — **critical for fiscal
    continuity**), and any settings/config tables.
  - Binary assets (e.g. product images if stored as files/BYTEA) included in the
    archive under `assets/`.
- Encryption: authenticated symmetric encryption (e.g. AES-256-GCM) with a key
  derived from the passphrase via a strong KDF (scrypt/PBKDF2 with a random salt
  stored in the manifest/header). Use Node's `crypto`. Do **not** invent crypto —
  use a well-trodden construction. Encrypt the zip bytes (or encrypt entries);
  simplest correct option: build the zip, then encrypt the whole blob and wrap it
  with a tiny header (`magic`, `version`, `salt`, `iv`, `authTag`).
- Read-only. Never mutates. Safe to run on a live machine. Consider a short
  advisory note in the response if orders are mid-flight.

### `POST /api/v1/device-transfer/import`

- Multipart: the encrypted archive file + `passphrase` + explicit
  `confirmReplace: true`.
- Steps, all inside **one DB transaction** where possible:
  1. Decrypt + verify auth tag. Reject on wrong passphrase / tampered file with a
     clear error.
  2. Read `manifest.json`. **Compatibility gate**: refuse if the applied-migration
     list doesn't match this backend's, or the format version is newer than this
     backend understands. Return a structured error the kiosk can display.
  3. Optional but recommended: refuse unless the target has no sales history
     *unless* `confirmReplace` is set (it always is from the UI, but keep the
     guard for the API).
  4. Disable FK checks / defer constraints, `TRUNCATE ... CASCADE` (or delete in
     dependency order) every table the export owns, then bulk-insert the archive
     rows **preserving primary keys**.
  5. Reset all Postgres sequences to `MAX(id)+1` for every restored table, and
     restore fiscal counters exactly.
  6. Commit. On any error, roll back and leave the target untouched.
- Return a summary: rows restored per table, manifest info, warnings.
- After a successful import the backend process may need a restart to drop cached
  state — document this and, if there's an existing health/restart hook, surface
  a "restart recommended" flag.

### Backend testing

- Unit tests for the crypto round-trip, manifest build, compatibility gate, and
  sequence-reset logic (`npm run test`).
- An e2e test (`npm run test:e2e`) that seeds data, exports, wipes, imports, and
  asserts row counts + a few spot-checked records + sequence values match.
- `npm run lint` and `npm run build` must pass. If you add tables to the export,
  keep `be/src/database/migrations/index.ts` untouched (no schema change needed).

---

## Kiosk requirements (`kiosk/`)

New feature module `kiosk/lib/features/device_transfer/` following the standard
layout (`repositories/`, `state/`, `view/`). 

### Data / repository layer

- `kiosk/lib/data/backend_api/sources/device_transfer_api.dart` — `DeviceTransferApi`
  using `secureApiClientProvider`:
  - `Future<Uint8List> export({required String passphrase})` — expects
    `responseType: ResponseType.bytes`.
  - `Future<ImportSummary> import({required Uint8List archiveBytes, required String fileName, required String passphrase})`
    — multipart `FormData` like `importProductsCsv`.
- `schemas/` DTOs (`@MappableClass`) for the import summary / manifest info /
  structured compatibility error. Run `build_runner` after.
- A `DeviceTransferRepository` + provider mirroring `InventoryRepository`.

### State layer

- Riverpod notifier(s) / mutations for export and import with progress + error
  states. Mirror the `MutationPending / MutationError / MutationSuccess` pattern
  used in `import_products_csv_dialog.dart`.

### UI

- **Menu**: add `MenuType.deviceExport` / `MenuType.deviceImport` (or a single
  "Backup & Transfer" tile that opens a hub screen — your call, justify it in the
  design doc). Gate to admin/supervisor exactly like the other privileged tiles
  in `menu_grid.dart`. Add SVG icons to `kiosk/assets` + regenerate
  `assets.gen.dart` if you add assets, or reuse an existing `Icons.*`.
- **Route + screen** via `go_router_builder` (add a `part` file in
  `kiosk/lib/navigation/`).
- **Export flow**:
  1. Screen explains what will be exported and that the file contains sensitive
     data (PINs, customer + sales data).
  2. Admin enters + confirms a passphrase (min length, strength hint). Warn that
     the file is unrecoverable without it.
  3. Optional **authorizer PIN** re-confirmation — reuse the existing refund /
     Z-reading authorization dialog pattern
     (`kiosk/lib/features/sales/view/refund_authorization_dialog.dart`,
     `cashier_z_reading_screen.dart`).
  4. Call export, show progress, then `FilePicker.platform.saveFile` with a
     sensible default name, e.g. `pos-kiosk-backup-<storeOrDevice>-<yyyyMMdd-HHmm>.pos`
     (or `.zip.enc`), and `File(path).writeAsBytes(bytes)`.
  5. Success dialog with file location + row-count summary.
- **Import flow**:
  1. Strong warning screen: *"This permanently replaces ALL data on this
     device — users, transactions, inventory, reports. This cannot be undone."*
     Red styling, matches the CSV `replace` warning box.
  2. `FilePicker.platform.pickFiles(withData: true)` for the archive.
  3. Passphrase entry.
  4. Authorizer PIN confirmation (required for import).
  5. Type-to-confirm gate (e.g. type `REPLACE`) before the button enables.
  6. Call import, show indeterminate progress (this can take a while — set a
     generous Dio `receiveTimeout`/`sendTimeout` on this call specifically).
  7. On the structured compatibility error, show a clear, non-scary explanation
     ("This backup is from an incompatible app version…").
  8. On success: summary dialog, then force a return to the login/startup screen
     (`const LoginRoute().go(context)` / restart-app guidance) so all providers
     re-fetch against the restored data. If the backend signalled
     "restart recommended", tell the admin to restart the machine.

### Kiosk testing / verification

- Per `kiosk/CLAUDE.md` and project memory: **do not author new test files**
  unless asked. Verify with `dart analyze` (must be clean) and
  `dart run build_runner build --delete-conflicting-outputs`.
- Manually sanity-check the flows compile and navigate; describe manual test
  steps in the plan.

---

## Cross-cutting requirements

- **Security**: the archive holds PINs, staff PII, and full sales history. It
  must never be written unencrypted to disk, never logged, and the passphrase
  must never be logged or persisted. Redact archive contents from any error
  output.
- **Fiscal integrity**: receipt / OR / invoice sequence numbers must survive the
  round-trip exactly. Call this out explicitly in tests.
- **Atomicity**: a failed import leaves the target exactly as it was.
- **Versioning**: bump an export-format version constant; the compatibility gate
  keys off it plus the migration list.
- **Docs**: update `CLAUDE.md` (backend module list / schema notes) and
  `kiosk/CLAUDE.md` (feature list) with the new module. Add a short
  `docs/` runbook: how an operator migrates a machine end to end.
- Keep DTO parity: any backend DTO consumed by Flutter must have a matching
  `@MappableClass` schema on the kiosk side (see `CLAUDE.md` → Shared conventions).

---

## Deliverables

1. Design doc in `docs/superpowers/specs/`.
2. Implementation plan in `docs/superpowers/plans/`.
3. Backend `device-transfer` module + tests, `npm run lint` / `build` / `test` /
   `test:e2e` green.
4. Kiosk `device_transfer` feature + menu entries + route, `dart analyze` clean,
   codegen run.
5. Updated `CLAUDE.md`, `kiosk/CLAUDE.md`, and an operator runbook.
6. A short summary of manual test steps performed / recommended.

## Acceptance criteria

- An admin can export on machine A, move the file to machine B (same app
  version), import it, and machine B then shows identical users, inventory,
  transactions, reports, POS-terminal config, and receipt sequence position.
- Wrong passphrase, tampered file, and version-mismatched archive each produce a
  clear, non-destructive error.
- A failed import (killed mid-way) leaves the target database unchanged.
- Non-admin/supervisor users cannot see or reach either flow.
