# Move Products CSV Import from Installer to In-App — Design Spec

**Date:** 2026-07-27
**Branch:** feature/mobile-integration

---

## Summary

Remove the mandatory CSV-import wizard page from the Windows installer and replace it with an in-app import flow in the kiosk's Inventory Management screen. On a fresh install with an empty catalog, the Menu screen detects the empty state and prompts admins/supervisors to import; cashiers see a message to contact their supervisor. The CSV format is unchanged — the same header/schema the installer used to validate. The in-app import offers a choice between **Upsert** (additive, default) and **Replace Entire Menu** (authoritative, soft-deletes anything not in the file — behind an explicit warning).

---

## 1. Backend

### 1.1 Installer changes (`be/installer/installer.iss`)

Remove:
- The CSV Import wizard page (file list UI, Add/Remove CSV buttons, schema detection, per-file status, unknown-schema warning dialog, `NextButtonClick` validation block for this page).
- The `[Run]` step "Step 3 - Seed store catalog from imported CSV files" (`seed-from-csv.bat` invocation) and its `ShouldSeedCsv`/`IsFreshInstall` gating for this step.
- The bundled `products-template.csv` `[Files]` entry (`DestDir: "{app}\data"`).

Keep unchanged:
- `--seed-csv` CLI mode on `POSBackend.exe` (`be/src/exec.ts`, `run-csv-seeders.ts`).
- `seed-from-csv.ps1` / `seed-from-csv.bat` and their use in `recover-services.bat` — recovery/upgrade re-seeding from a CSV dropped in `{app}\data\csv` remains a supported disaster-recovery path, unrelated to first-run UX.
- The `{app}\data\csv` directory creation entry — still the drop location `recover-services.bat` reads from.
- `csv-parser.ts`, `csv-validator.ts`, `csv-schema.registry.ts` — reused as-is by the new API endpoint.

Fresh installs proceed directly from "Run TypeORM migrations" to "Install backend Windows service" — no catalog-related step in between.

### 1.2 `ProductsCsvSeeder` — selectable authoritative mode

`ProductsCsvSeeder.run()` currently treats the imported rows as authoritative: categories/products/variants not present in the CSV are soft-deleted (see `products-csv.seeder.ts`). That behavior is still wanted for the CLI/recovery path (full-catalog re-seed) and, now, as an explicit opt-in for in-app imports — an admin doing a full menu replacement wants exactly that. The default for in-app imports must stay additive-only, since an admin adding a new batch of products should never *accidentally* soft-delete products added manually through the UI.

Change the signature to:

```ts
async run(dataSource: DataSource, rows: string[][], options?: { authoritative?: boolean }): Promise<void>
```

- `authoritative` defaults to `true` — CLI/recovery callers (`run-csv-seeders.ts`) pass no options and keep today's behavior exactly.
- When `authoritative: false`, skip the three soft-delete blocks (categories not in CSV, products not in CSV, variants not in CSV) in Passes 1–3. Upsert-by-name logic is otherwise identical. Pass 4 (recipe creation) is unaffected either way — it only ever adds recipes, never removes them.
- The in-app import endpoint (1.3) exposes both modes and passes the caller's choice through as this same option — there is no separate code path, just the existing flag driven by user selection instead of always `false`.

### 1.3 New endpoint — `POST /api/v1/products/import-csv`

Added to `products.controller.ts`, alongside the existing image-upload endpoints (same `FileInterceptor` + `multer` pattern already used there and in `product-groups.controller.ts`).

- **Auth:** standard JWT guard, no additional role guard — consistent with the rest of the products module, where admin/supervisor gating is UI-only (kiosk hides the button for other roles).
- **Request:** multipart, field `file` (the `.csv`) plus a `mode` field: `"upsert"` (default if omitted) or `"replace"`.
- **Behavior:**
  1. Parse the uploaded buffer with the existing `csv-parser` logic (adapt from file-path-based to buffer-based, or write to a temp file first — whichever keeps `csv-parser.ts` reusable without duplicating logic).
  2. Detect schema via `detectSchema()`. Reject with a 400 error if `UNKNOWN` (message: file doesn't match the expected products/categories/variants format) or `MODIFIERS` (not supported from this endpoint).
  3. Validate rows via `validateCsvRows()`. On any row error, return 400 with the row-level error list (row number, column, message) — same shape the installer wizard used to show.
  4. Run `ProductsCsvSeeder.run(dataSource, rows, { authoritative: mode === 'replace' })`.
  5. Return a summary: counts inserted/updated for categories, products, and variants (and, when `mode === 'replace'`, counts soft-deleted).
- **No `{app}\data\csv` archival** — uploaded files are not persisted to disk after processing (unlike the installer flow, which kept a permanent backup copy). This is an in-app convenience import, not a system-of-record backup mechanism.

### 1.4 Empty-catalog detection

No new endpoint needed. The kiosk Menu screen already fetches the product catalog on load (`GET /api/v1/catalog/products`); it can check the result for emptiness directly.

---

## 2. Kiosk — Inventory Management import

### 2.1 New dependency

Add `file_picker` to `kiosk/pubspec.yaml` (Windows-capable file-open and save dialogs). No existing package in the kiosk covers generic file selection.

### 2.2 UI

- **Products tab toolbar** (`inventory_grid_screen.dart`): add an "Import CSV" button, gated by `isAdminOrSupervisor` (matching the existing Add/Edit/Delete/toggle-availability gating already in this screen).
- **New dialog** `import_products_csv_dialog.dart` (in `lib/features/inventory/view/`):
  - Explanatory text stating the expected CSV header format: `Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price` (optionally with a trailing `Product Image URL` column).
  - **"Download template"** button: uses `file_picker`'s save-file dialog to write a static template CSV (header row only, matching `PRODUCTS_CSV_HEADERS_WITH_IMAGE` from the backend's `csv-schema.registry.ts`) to a location the user chooses — same header the installer's old bundled `products-template.csv` used, just generated in-app instead of shipped as an installer asset.
  - **Import mode selector** — a two-option segmented control / radio group:
    - **"Add & Update" (Upsert)** — selected by default. Helper text: "Adds new products and updates existing ones by name. Nothing already in your menu is removed."
    - **"Replace Entire Menu"** — selecting it immediately reveals an inline warning banner (red/warning-colored, non-dismissible while selected): "This will remove every category, product, and variant not present in the imported file. This cannot be undone from within the app. Make sure your CSV contains your complete menu before continuing."
  - **"Choose File"** button: uses `file_picker`'s open-file dialog, filtered to `*.csv`.
  - **"Import"** button: when mode is "Replace Entire Menu", clicking Import first opens a confirmation dialog ("Replace entire menu? This cannot be undone." / Cancel / "Yes, Replace") before the request is sent; when mode is "Add & Update", it submits directly. Uploads the selected file plus the chosen `mode` (`upsert` or `replace`) to `POST /products/import-csv`.
- **Result handling:**
  - Success → show a summary dialog (counts inserted/updated, and counts soft-deleted when mode was "Replace Entire Menu"), then invalidate `inventoryProductsProvider` and `inventoryCategoriesProvider` so the grid refreshes.
  - Row-level validation errors → show them in the dialog (row + column + message), matching the granularity the installer wizard used to provide, without closing the dialog (so the user can pick a different file).
  - Unknown-schema / network errors → show a simple error message via the existing `showMessageDialog` pattern.

---

## 3. Menu screen — empty-catalog check

`menu_screen.dart` already has an on-load check pattern (`checkAndShowPosDialog`, plus a users-dialog check) using `useRef<bool>` guards to show at most once per screen mount. Add a third check, `checkAndShowEmptyCatalogDialog`, using the same shape:

- Runs after the product catalog fetch resolves (mirrors how `checkAndShowPosDialog` waits on `posTerminalProvider`).
- If the resolved catalog is empty:
  - **Admin/Supervisor** (`role == Role.admin || role == Role.supervisor`):
    - Title: "No Products Found"
    - Message: "Import your product catalog to get started."
    - Primary button: **"Import Products"** → dismiss dialog, navigate to `InventoryRoute` (Products tab, where the new Import CSV button lives).
    - Secondary button: **"Sign Out"** → `const LoginRoute().go(context)`.
    - `barrierDismissible: false` (matches the existing no-terminal dialog for admins, which is also non-blocking-optional via two choices).
  - **Other roles:**
    - Title: "No Products Found"
    - Message: "Please contact your supervisor or admin to import the product catalog."
    - Single button: **"Sign Out"** → `const LoginRoute().go(context)`.
    - `barrierDismissible: false` (matches the existing no-terminal dialog for non-admins).
- Dialog ordering: if both the POS-terminal-missing and empty-catalog conditions are true simultaneously, the POS-terminal dialog takes precedence (it already runs first and is also `barrierDismissible: false`/blocking); the empty-catalog check only fires once a terminal is confirmed assigned, since without a terminal the user can't operate the register anyway.

---

## 4. CSV format (unchanged)

Same schema the installer validated — no format changes:

```
Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price[,Product Image URL]
```

Grouping/validation rules (blank `Variant Name` → single-price product via a default "Regular" variant, etc.) are unchanged from `products-csv.seeder.ts` / `csv-validator.ts`.

---

## 5. Out of scope

- Modifiers CSV import — was already unimplemented ("future use") in the installer wizard; stays unimplemented here.
- Changing the CLI/recovery (`--seed-csv`, `recover-services.bat`) authoritative re-seed behavior — untouched.
- Mobile app (`mobile/`) CSV import — it already has its own offline import flow (`csv_import_screen.dart`) unrelated to the installer/kiosk path this spec addresses.
- Persisting uploaded CSVs to disk as a backup (the installer used to copy files to `{app}\data\csv\` permanently; the in-app import endpoint does not replicate this).
- Backend role-based authorization on the new endpoint — role gating stays UI-only, consistent with the rest of the products module.
