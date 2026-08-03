# Mobile POS App Design Spec
**Date:** 2026-07-22
**Branch:** feature/mobile-pos (to be created from develop)
**Status:** Approved

---

## Overview

Build a fully offline Flutter mobile POS application in `mobile/` that replicates all features of the `kiosk/` Windows app. The mobile app supports both tablet and phone form factors via an adaptive layout. All data is stored locally in SQLite (Drift). Product catalog, users, modifier groups, and store info are seeded via CSV import. A default admin account is auto-seeded on first launch with PIN `000000`.

This is an MVP — no backend connectivity, no sync.

---

## Architectural Approach

**Option A — Independent app with kiosk-inspired architecture.** The mobile app is a fully standalone Flutter project in `mobile/`. It mirrors the kiosk's feature-module structure and Riverpod/GoRouter/dart_mappable patterns but has its own data layer backed by Drift instead of the NestJS backend API. No Dart code is shared between `kiosk/` and `mobile/` at this stage.

**Rationale:** Kiosk is in active production. Coupling it to a shared package risks destabilizing it. A clean slate gives full control over the mobile-specific schema and offline-first data model.

---

## Folder Structure

```
mobile/lib/
├── core/
│   ├── database/              # Drift AppDatabase, tables, DAOs
│   ├── csv/                   # CSV importer services (one per domain)
│   ├── seeder/                # AdminSeeder — runs once on first launch
│   ├── printing/              # PrintService hierarchy + ReceiptPrinter
│   ├── result/                # Result<T, AppError> sealed type
│   ├── errors/                # AppError, DatabaseException subtypes
│   └── theme/                 # Design system: colors, typography, tokens
├── features/
│   ├── auth/
│   ├── catalog/
│   ├── ordering/
│   ├── sales/
│   ├── reports/
│   ├── settings/
│   └── users/
├── navigation/                # GoRouter with typed routes + auth/role guards
├── shared/
│   ├── widgets/               # ErrorStateWidget, EmptyStateWidget, etc.
│   ├── shell/                 # AdaptiveShell (tablet sidebar / phone bottom nav)
│   └── responsive/            # Breakpoint constants, context extensions
└── main.dart
```

Each feature module follows this layout:
```
<feature>/
├── data/
│   ├── datasources/           # Drift DAO calls
│   └── repositories/          # Concrete implementations
├── domain/
│   ├── entities/              # Immutable dart_mappable domain models
│   ├── repositories/          # Abstract interfaces
│   └── use_cases/             # Single-responsibility use cases
└── presentation/
    ├── state/                 # Riverpod AsyncNotifier / StateNotifier providers
    └── view/                  # Screens + widgets (HookConsumerWidget)
```

---

## Data Layer

### Drift Database

Single `AppDatabase` with DAOs grouped by domain. All foreign keys enforced. Indexed on `sales.created_at` and `products.group_id` for fast report queries.

| Table | Key columns |
|---|---|
| `users` | id, name, role, pin_hash, is_active |
| `product_groups` | id, name, sort_order |
| `products` | id, group_id, name, price, is_available, image_url, sort_order |
| `modifier_groups` | id, product_id, name, is_required, max_selections |
| `modifier_options` | id, group_id, name, additional_price |
| `sales` | id, cashier_id, total, discount, status, type, created_at |
| `sale_items` | id, sale_id, product_id, variant_name, qty, unit_price |
| `sale_item_modifiers` | id, item_id, modifier_name, additional_price |
| `payments` | id, sale_id, method, amount, reference, created_at |
| `refunds` | id, sale_id, reason, total, created_at |
| `refund_items` | id, refund_id, sale_item_id, qty, amount |
| `store_info` | singleton row: store name, address, tax rate, currency |

### CSV Import (`core/csv/`)

Four independent importers. Each implements `CsvImporter<T>`:
```dart
abstract interface class CsvImporter<T> {
  Future<ImportResult<T>> import(File file);
}
```

| Importer | CSV covers |
|---|---|
| `ProductsCsvImporter` | products + product groups |
| `ModifiersCsvImporter` | modifier groups + modifier options |
| `UsersCsvImporter` | staff accounts (name, role, PIN) |
| `StoreInfoCsvImporter` | store name, address, tax rate, currency |

`ImportResult<T>` is a value object containing:
- `successCount` — rows saved
- `skippedCount` — rows skipped (already exists / duplicate)
- `errors` — `List<CsvRowError>` with row index + message

**Rules:**
- Missing CSV files are silently skipped — other imports proceed normally
- Parse errors are collected per-row, never thrown — summarized in a result dialog
- Import runs in a Dart `Isolate` to keep the UI responsive
- Duplicate detection by natural key (product name + group, user name, etc.) — upsert strategy

### Admin Seeder (`core/seeder/`)

`AdminSeeder.seed()` is called once at app startup:
1. Check `SharedPreferences` key `admin_seeded`
2. If false: query `users` table for any row with `role = admin`
3. If none found: insert default admin (`name: Admin, pin_hash: bcrypt("000000"), role: admin, is_active: true`)
4. Set `admin_seeded = true`
5. On first login with default PIN, force a PIN change screen before proceeding

### Error Handling (Data Layer)

- All DAO calls return `Result<T, AppError>` — no raw exceptions propagate
- `AppError` is a sealed class: `DatabaseError | ValidationError | NotFoundError | CsvParseError`
- Drift `SqliteException` is caught at the DAO boundary and mapped to `DatabaseError`

### Performance (Data Layer)

- Indexed columns: `sales.created_at`, `sales.cashier_id`, `products.group_id`
- Report aggregations use Drift native SQL expressions — no in-memory list scanning
- Product images stored as file paths (TEXT) — no BLOBs in the database
- CSV import runs on a background isolate — zero UI jank during large imports

---

## Feature Modules

### `auth`
- PIN pad login screen (6-digit input, large touch targets)
- Session state via Riverpod (`AuthNotifier`) — stores current user in memory
- Change PIN flow — old PIN → new PIN → confirm
- Force PIN change on first login with default `000000`
- Session expires on app background (configurable, default: never for kiosk-like usage)

### `catalog`
- Product groups (categories) + products with images
- Modifier groups + options per product
- Admin-only CRUD screens for post-import management
- Product availability toggle (enable/disable without deleting)

### `ordering`
- Main POS screen — the primary daily-use screen
- **Tablet:** side-by-side layout — left: category filter + product grid, right: live cart panel (mirrors kiosk)
- **Phone:** full-width product grid + floating cart FAB → cart bottom sheet
- Line item management: add, remove, change quantity, apply modifiers
- Discount input (flat or percentage) per item or per order
- Sale type: dine-in / take-out / delivery

### `sales`
- Finalize sale: cash, card, or other reference payment methods
- Cash payment: compute change due
- Card / reference: capture reference number
- Void transaction: admin PIN required
- Refund flow: item-level refund selection, reason input, partial refunds supported
- Receipt triggered on sale completion (see Printing section)

### `reports`
- Sales summary: daily / weekly / monthly with bar chart (`fl_chart`)
- Z-reading report: end-of-day summary — total sales, payment breakdown, item-level sales, category sales
- Cashier daily report: per-cashier breakdown
- All data sourced from local Drift queries
- Export to PDF via share sheet

### `settings`
- Store / franchisee info (name, address, tax rate, currency)
- CSV import screen: file picker per CSV type, import result summary dialog
- Printer setup: scan + pair Bluetooth printer, detect built-in printer, test print
- App settings: PIN timeout, currency format, receipt footer text

### `users`
- List all users with role badges
- Add / edit / deactivate users
- Role-based access: admin vs cashier
- PIN reset by admin (does not require old PIN)

---

## Adaptive Layout & Navigation

### AdaptiveShell

`AdaptiveShell` wraps all authenticated screens. Uses `LayoutBuilder` (not `MediaQuery`) to avoid deep-tree rebuild propagation:

- `width >= 720` → `TabletShell`: permanent left sidebar navigation + content area
- `width < 720` → `PhoneShell`: `Scaffold` with `BottomNavigationBar`

Sidebar / bottom nav items: Ordering, Reports, Catalog, Users, Settings.

### GoRouter Routes

```
/                        → redirect → /login or /ordering
/login                   → LoginScreen
/ordering                → OrderingScreen          (AdaptiveShell)
/sales/payment           → PaymentScreen
/sales/receipt           → ReceiptScreen
/refund/:saleId          → RefundScreen
/reports                 → ReportsScreen           (AdaptiveShell)
/reports/z-reading       → ZReadingScreen
/users                   → UserManagementScreen    (AdaptiveShell, admin only)
/catalog                 → CatalogManagementScreen (AdaptiveShell, admin only)
/settings                → SettingsScreen          (AdaptiveShell)
/settings/csv-import     → CsvImportScreen
/settings/printer        → PrinterSetupScreen
```

**Auth guard:** unauthenticated users redirected to `/login`.
**Role guard:** cashier role redirected away from `/users` and `/catalog` with a clear "Access Denied" message.

### Error Handling (Navigation)

- All `AsyncNotifier` states exposed as `AsyncValue` — screens handle `loading / data / error` states
- `ErrorStateWidget`: consistent full-screen error UI with retry CTA
- `EmptyStateWidget`: per-screen empty states with actionable CTA (e.g., "Import products via CSV")

### Performance (UI)

- `AdaptiveShell` rebuilt only on breakpoint change via `LayoutBuilder`
- Riverpod `select()` used on all providers to scope rebuilds to the minimum widget subtree
- Product catalog grid uses `SliverGrid` with `RepaintBoundary` on each card
- Image caching: `CachedNetworkImage` for URL images, `FileImage` for local paths — both use the same `ImageCache` budget
- All report charts rendered as `const`-safe stateless widgets fed by pre-computed data from the notifier

---

## Printing

### Architecture

```
abstract interface class PrintService {
  Future<PrintResult> print(ReceiptData receipt);
}

class ReceiptPrinter {
  // Tries in order: Bluetooth → BuiltIn → PDF fallback
  Future<PrintResult> print(ReceiptData receipt);
}
```

`PrintResult` is a sealed class: `PrintSuccess | BluetoothUnavailable | PrinterNotFound | PrintError | PdfShared`.

### Bluetooth ESC/POS (`BluetoothPrintService`)

- Package: `print_bluetooth_thermal`
- Paired printer address saved to `SharedPreferences`
- Printer setup screen: scan → select → test print → save
- Receipt layout built with `esc_pos_utils_plus` (same package as kiosk)
- Riverpod provider tracks connection state — settings screen shows live printer status badge

### Built-in Thermal Printer (`BuiltInPrintService`)

- Package: `flutter_thermal_printer` (or raw USB serial port detection)
- Auto-detected at startup — if built-in ESC/POS port found, registered as preferred printer
- Falls through to Bluetooth if no built-in detected

### PDF Fallback (`PdfPrintService`)

- Packages: `pdf` + `printing`
- Generates a styled receipt PDF matching the thermal layout
- Shared via `Share.shareXFiles()` — user can print, save, or forward
- Also used for report exports (Z-reading, sales summary PDF)

### Error Handling (Printing)

- Each `PrintService` returns `PrintResult` — never throws
- If Bluetooth fails mid-print: UI shows one-tap "Share as PDF" fallback without re-entering receipt flow
- Print errors logged to a local error log accessible in Settings for debugging

### Performance (Printing)

- `EscPosBuffer` (ESC/POS receipt data) pre-built in a background isolate before confirmation
- PDF generation uses the `pdf` package canvas API — not HTML rendering — fast on low-end handhelds

---

## Design System

Mirrors the kiosk brand:
- **Primary:** `0xFF1B7A8C` (teal)
- **Secondary:** `0xFFBCBE68` (olive)
- **Background:** `0xFFF3F1ED`
- **Typography:** Inter / Poppins — large bold titles, medium section headers
- **Spacing:** 8px base grid
- **Border radius:** 16–24px on cards, 12px on buttons
- **Touch targets:** minimum 48×48px, preferred 56–72px height on buttons
- **Shadows:** soft, layered — no heavy drop shadows

Semantic tokens in `core/theme/pos_design.dart` — same token names as kiosk for consistency.

---

## Key Packages

| Package | Purpose |
|---|---|
| `drift` + `sqlite3_flutter_libs` | Local SQLite database |
| `hooks_riverpod` + `flutter_hooks` | State management |
| `go_router` + `go_router_builder` | Navigation |
| `dart_mappable` | JSON/entity mapping + code gen |
| `esc_pos_utils_plus` | ESC/POS receipt building |
| `print_bluetooth_thermal` | Bluetooth printer |
| `flutter_thermal_printer` | Built-in thermal printer |
| `pdf` + `printing` | PDF receipt + report export |
| `share_plus` | Share sheet for PDF |
| `file_picker` | CSV file selection |
| `csv` | CSV parsing |
| `bcrypt` | PIN hashing |
| `shared_preferences` | Seeding flags, printer address |
| `fl_chart` | Sales bar charts |
| `cached_network_image` | Product image caching |
| `flutter_svg` | SVG assets |
| `gap` | Spacing widgets |
| `intl` | Date/number formatting |

---

## Out of Scope (MVP)

- Backend sync / online mode
- iOS build (Android first)
- Multi-store / multi-terminal
- Kitchen display integration
- Customer-facing display
- Loyalty / rewards system
- Inventory tracking
