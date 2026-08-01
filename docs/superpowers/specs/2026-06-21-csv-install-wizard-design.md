# CSV Import in Install Wizard — Design Spec

**Date:** 2026-06-21
**Branch:** feature/optimize

---

## Summary

Add a CSV import step to the Inno Setup install wizard so that each store seeds its own product catalog (categories, products, variants) at install time. The installer prompts the user to attach one or more CSV files, auto-detects the schema of each, validates recognized files, and passes them to a new `--seed-csv` CLI mode on `POSBackend.exe`. The DB remains the source of truth after install; the store can manage products in-app at any time.

---

## 1. Wizard Page

A new wizard page is inserted after the existing Kiosk Number page.

### UI elements

- **File list** — table with columns: Filename, Detected Type, Rows, Status
- **Add CSV** button — opens a multi-select file dialog filtered to `*.csv`; files can be added in batches or one at a time
- **Remove** button — removes the selected file from the list
- **Status area** — overall validation state shown at the bottom of the page

### Schema detection

Each file's header row is matched against known schemas:

| Detected Type | Expected Header |
|---|---|
| Products / Categories / Variants | `Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price` |
| *(future)* Modifiers | `Modifier Group Name,Group Description,Selection Type,Is Required,Min Selection,Max Selection,Linked Product Group,Option Name,Option Price Add-On,Option Available` |
| Unknown | Header does not match any known schema |

### Per-file status in list

| Status | Meaning |
|---|---|
| Valid | Recognized schema, all rows pass validation |
| Error | Recognized schema, one or more rows fail validation — row number + reason shown |
| Warning | Unknown schema — file is unrecognized |

### NextButtonClick validation (blocks wizard)

1. At least one file with a recognized schema must be attached
2. No recognized-schema file may have row-level errors

### Unknown schema warning dialog

If any attached file has an unknown schema and the user clicks Next, a dialog appears **before** proceeding:

> **The following files do not match a known schema and will be skipped:**
> - `<filename>.csv`
>
> Do you want to continue without these files, or go back to fix them?
>
> **[ Go Back ]   [ Continue Without Them ]**

Unknown files chosen to skip are still copied to `C:\POSKiosk\data\csv\` as backup but are not processed during seeding.

### File copy

In `CurStepChanged(ssInstall)`, all attached files (recognized and unknown) are copied via `FileCopy()` to `C:\POSKiosk\data\csv\`.

---

## 2. Backend — `--seed-csv` CLI Mode

A new flag `--seed-csv <dir>` is added to `POSBackend.exe`. It receives the path `C:\POSKiosk\data\csv\` and processes all `.csv` files found there.

### Pipeline per file

1. Read header row → identify schema (same detection logic as the wizard, authoritative)
2. Parse all rows → validate each against schema rules
3. Any validation error → log row number + reason, exit non-zero
4. Success → run the appropriate seeder

### Products / Categories / Variants seeder

Follows the same upsert pattern as the existing `ProductsSeeder`:

**Pass 1 — Product Groups (categories)**
- Upsert by `Category` name
- `Category Description` maps to description; first occurrence wins on conflict

**Pass 2 — Products**
- Grouped by `Product Name` within their category
- Upsert by name; uses `Product Base Price` and `Product Description`
- Fully idempotent — safe to re-run

**Pass 3 — Product Variants**
- Each row with a non-blank `Variant Name` adds one variant to its parent product
- Upsert by `Variant Name` within the product
- A row with blank `Variant Name` and `Variant Price` → single-price product, no variants created

### New installer script

`be/installer/scripts/seed-from-csv.ps1`:
- Accepts `$AppDir` parameter
- Calls `POSBackend.exe --seed-csv "$AppDir\data\csv"`
- Logs to `$AppDir\logs\seed-csv-install.log`
- Exits non-zero on failure

A companion `.bat` wrapper (`seed-from-csv.bat`) follows the same pattern as the existing `run-migrations.bat`.

---

## 3. Install Sequence

```
Step 0  Visual C++ Redistributable
Step 1  Setup PostgreSQL + create pos_db
Step 2  Run TypeORM migrations
Step 3  ← NEW: seed-from-csv.bat  (reads C:\POSKiosk\data\csv\*.csv)
Step 4  Install backend Windows service
Step 5  Offer to launch kiosk
```

---

## 4. Error Handling

| Scenario | Behavior |
|---|---|
| CSV has unknown schema | Warning dialog at wizard Next click listing unrecognized files by name; user chooses Continue or Go Back |
| Recognized CSV with row errors | Shown in wizard file list; blocks Next until resolved or file is removed |
| No recognized-schema file attached | Blocks Next with message: "At least one recognized CSV file is required" |
| `--seed-csv` exits non-zero | Installer shows MsgBox with log path (`{app}\logs\seed-csv-install.log`) |
| CSV dir missing or empty at seeding step | Exit non-zero → same MsgBox |
| Seeding partially completes then fails | Idempotent upserts mean re-running `recover-services.bat` picks up safely |

---

## 5. CSV Format — Products / Categories / Variants

**Header (exact, case-sensitive):**
```
Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price
```

**Column rules:**

| Column | Required | Validation |
|---|---|---|
| `Category` | Yes | Non-empty string |
| `Category Description` | No | Optional; blank is fine |
| `Product Name` | Yes | Non-empty string |
| `Product Description` | No | Optional |
| `Product Base Price` | Yes | Valid number ≥ 0 |
| `Variant Name` | No | Blank = product has no variants |
| `Variant Price` | Conditional | Required if `Variant Name` is present; valid number ≥ 0 |

**Grouping rules:**
- Rows sharing the same `Category` → same category
- Rows sharing the same `Product Name` within a category → same product, each row adds one variant
- Row with blank `Variant Name` → single-price product, base price used directly

**Bundled template:** `products-template.csv` is included in the installer via a `[Files]` entry and extracted to `C:\POSKiosk\data\csv\` during install as a reference for future catalog updates.

---

## 6. Backup

All CSV files attached during the wizard are copied to `C:\POSKiosk\data\csv\` and remain there permanently. This directory serves as:
- The seeding source for `--seed-csv`
- A permanent backup of the catalog data imported at install time
- The drop location for updated CSVs when re-seeding via `recover-services.bat`

---

## 7. Out of Scope

- Modifiers CSV import (schema defined for future use, not implemented now)
- In-app CSV import (products are managed in-app via the UI after install)
- CSV export from the installer
- Wizard-level preview or conflict display when multiple files share the same schema type (the backend simply merges their rows during seeding)
