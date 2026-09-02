# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

```
POS/
├── be/      # NestJS backend (TypeScript · PostgreSQL · Docker)
├── kiosk/   # Flutter Windows kiosk app (Dart · Riverpod · Win32)
└── build-installer.bat / build-installer.ps1   # one-click installer builder
```

---

## Backend (`be/`)

### Commands

```bash
# Dev server (hot reload)
npm run start:dev

# Build
npm run build

# Lint / format
npm run lint
npm run format
npm run format:check

# Tests
npm run test                        # unit tests
npm run test:watch                  # unit tests in watch mode
npm run test:e2e                    # end-to-end
npm run test:cov                    # with coverage

# Run a single test file
npx jest --testPathPattern=src/products/products.service.spec.ts

# Database migrations (Postgres must be running)
npm run migration:up      # apply pending migrations
npm run migration:down    # revert last migration
npm run migration:generate  # generate from entity changes
npm run migration:create    # blank migration file
npm run migration:show    # list status

# Seeding
npm run seed:run          # run all seeders
npm run seed:create       # scaffold a new seeder

# DB reset (drops and re-creates, dev only)
npm run db:reset

# Docker (manages both Postgres and the app)
npm run docker:build:up   # build image + start containers
npm run docker:dev        # start containers in foreground
npm run docker:down       # stop containers
npm run docker:logs       # stream logs

# PM2 (production process manager)
npm run pm2:start         # start backend as PM2 process
npm run pm2:restart       # restart
npm run pm2:logs          # stream logs
npm run pm2:monit         # resource monitor

# Windows installer build (SEA = Single Executable App)
npm run build:sea         # sync migration/seeder indexes + nest build + pkg → be/POSBackend.exe

# Smart-quote sanitiser (installer.iss guard)
npm run check:quotes      # detect curly quotes in installer.iss
npm run fix:quotes        # replace them with straight ASCII quotes
```

`npm install` requires `--legacy-peer-deps`.

API root: `http://localhost:3000/api/v1` · Swagger: `http://localhost:3000/api/docs`

### Architecture

**Module structure** — each domain lives under `src/<domain>/` and follows this layout:

```
products/
├── dto/                 # Input/output DTOs (class-validator)
├── entities/            # TypeORM entities
├── mapper/              # Entity ↔ DTO mappers (pure static classes)
├── services/            # One file per use-case (CreateProductService, etc.)
├── products.controller.ts
├── products.service.ts  # Orchestrates feature services
└── products.module.ts
```

**Data access** — TypeORM with PostgreSQL. Migrations are the only way to change the DB schema — never use `synchronize: true`. Migration files live in `src/database/migrations/` with timestamp-based names. An `index.ts` in that directory must be kept in sync (`npm run migration:sync-index` handles this, and `build:sea` runs it automatically).

**Auth** — JWT via Passport. `@Public()` decorator opts out of the default JWT guard. User identity injected with `@CurrentUser()`. Tokens returned from `POST /api/v1/auth/login`.

**Cross-cutting** — `EventEmitterModule` for in-process events; `ScheduleModule` + `CronJobsModule` for scheduled work.

**Device transfer** — `src/device-transfer/` exports the entire `public` schema (every base table, `migrations` included) as one gzipped-then-AES-256-GCM-encrypted `.posbackup` file, and imports one as a **full replace**. `POST /api/v1/device-transfer/export` and `/import` are admin/supervisor only. Import runs in a single transaction: `SET LOCAL session_replication_role = 'replica'` (needs a superuser DB role — true for the bundled Postgres), `TRUNCATE ... CASCADE`, bulk re-insert preserving primary keys, then reset every sequence (parsed from `column_default`, so standalone sequences like `z_readings_z_counter_seq` are covered too). A strict import is refused unless the archive's migration history is identical to the target's. Passing `partialRestore: 'true'` on `/import` switches to a best-effort mode: the migration-history gate is skipped, the target keeps its own `migrations` table, and only the tables/columns present on both devices are imported — a table is dropped whole if the target added a required column the archive lacks, a column is dropped if its Postgres `udt` changed. Everything skipped comes back in `DeviceImportSummaryDto.skipped` (`{ tables, columns }`). Used for migrating a store to a replacement kiosk machine — see `docs/runbooks/kiosk-device-migration.md`.

**Health endpoints** — mounted under the global `api/v1` prefix:

| Endpoint | Checks |
|---|---|
| `GET /api/v1/health` | memory + disk + postgres |
| `GET /api/v1/health/live` | memory only (liveness) |
| `GET /api/v1/health/ready` | postgres (readiness) |

`/health/live` without the `api/v1` prefix returns 404 — that's expected.

**Important schema notes:**
- Migration `1779582000000` changed `products.image_url` from `BYTEA` to `TEXT` and added `price`, `is_available`, `sort_order`, `category` columns. Also created the `product_modifier_groups` junction table (product → modifier_group, bypassing the store-menu/menu-item chain). The `Product` entity and `FindProductDetailsService` must stay in sync.
- Migration `1779582100000` dropped the `catalog_` prefixed tables. The kiosk now reads products via `GET /api/v1/catalog/products` (raw SQL in `CatalogService`) and individual product details via `GET /api/v1/products/:id`. These two endpoints use different data paths and must be kept consistent.

---

## Kiosk (`kiosk/`)

### Commands

```bash
# Install deps + generate code (run after any pubspec or annotated-class change)
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Run on Windows
flutter run -d windows

# Run on Android
flutter run -d android

# Build Windows release
flutter build windows

# Analyze
dart analyze
```

The `.env` file (copy from `.env.sample`) must contain `BACKEND_API_BASE_URL` and `SECURE_STORAGE_KEY` before running. New variables must also be added as `@EnviedField()` properties on the `Env` class in `lib/config/environment/`.

### Code generation

`dart_mappable` generates `.mapper.dart` files alongside every `@MappableClass` annotated file. `envied_generator` generates `env.g.dart`. `go_router_builder` generates `router.g.dart`. `flutter_gen` generates `lib/gen/assets.gen.dart`. **Always run `build_runner` after changing any of these files.** Do not manually edit `*.mapper.dart`, `*.g.dart`, or `lib/gen/` files.

### Architecture

**Feature module layout** (example: `lib/features/sales/`):

```
sales/
├── entities/       # Immutable domain models + their .mapper.dart
├── repositories/   # Abstract interface + Impl that calls API layer
├── state/          # Riverpod AsyncNotifier / StateNotifier providers
├── use_cases/      # (optional) single-responsibility use cases
└── view/           # Screens and dialogs (HookConsumerWidget)
```

Implemented features: `auth`, `catalog`, `device_transfer`, `menu`, `onboarding`, `ordering`, `reports`, `sales`, `settings`, `users`.

`device_transfer` — admin/supervisor "Backup & Transfer" hub (`MenuType.backupTransfer` → `DeviceTransferRoute`). Export writes an encrypted `.posbackup` file via `file_picker`; import replaces all device data from one. Both flows gate on a passphrase plus `SupervisorAuthorizationDialog`; import also needs a typed `REPLACE` confirmation and signs the user out on success. Talks to the backend `device-transfer` module (see Backend section).

**Data flow:** View → Riverpod provider → Repository → API source (`lib/data/backend_api/sources/`) → Dio HTTP client → Backend

**State management** — Hooks Riverpod (`hooks_riverpod`). Prefer `HookConsumerWidget` for screens that need both `flutter_hooks` and Riverpod. Providers are declared in `state/` files and consumed via `ref.watch` / `ref.read`.

**HTTP layer** — `lib/data/backend_api/` holds:
- `sources/` — one class per backend resource (e.g., `ProductsApi`)
- `schemas/` — DTOs annotated with `@MappableClass` for JSON ↔ Dart mapping (these parallel the backend's DTO types)
- `mappers/` — custom `dart_mappable` type mappers (e.g., `ImageUrlMapper`, `DateTimeWithOffsetMapper`)
- `api_clients.dart` — Dio provider wired with the auth interceptor

**Navigation** — GoRouter (`lib/navigation/router.dart`) with typed routes from go_router_builder code gen. Initial route is `OnboardingRoute`.

**Responsive values** — use `context.responsive.value(kiosk: ..., tablet: ..., phone: ...)` throughout; it selects the appropriate value based on screen size. Never hard-code pixel values that should vary by screen size.

**Brand colors** (defined in `lib/styles/color_set.dart`):
- Primary: `0xFF1B7A8C` (teal)
- Secondary: `0xFFBCBE68` (olive)
- Background: `0xFFF3F1ED`

Semantic color tokens from `lib/theme/pos_design.dart` (e.g., `POSColors.textPrimary`, `POSRadius.md`) should be preferred over raw `ColorSet` values in new UI code.

**UI redesign guide** — `kiosk/CLAUDE.md` contains the full UI/UX modernization brief (touch-friendly, kiosk-quality design). All visual changes must follow that guide.

**Windows-specific** — `window_manager` and `win32` handle fullscreen mode and high-DPI awareness. Entry point (`main.dart`) sets the window to fullscreen in production and 1536×864 in dev mode.

**Printing** — `esc_pos_utils_plus` handles receipt printing via the `printer` feature module.

---

## Installer (Windows deployment)

The backend ships as a Windows installer that bundles the Flutter app, NestJS as a Single Executable App (SEA), and portable PostgreSQL 16.

### Building

Prerequisites: Inno Setup 6, portable PostgreSQL 16 at `C:\pgsql\`, NSSM at `C:\nssm\`, `be\.env.prod`.

```powershell
# From repo root — prompts for version, then builds everything
.\build-installer.bat
```

Output: `be\installer\output\POSKiosk-Setup-<version>.exe`

What it does in order:
1. Verifies prerequisites
2. Optionally bumps `#define MyAppVersion` in `installer.iss`
3. Flutter codegen (`pub get` + `build_runner`)
4. Parallel: `npm run build:sea` (backend SEA) + `fvm flutter build windows`
5. Auto-strips curly/smart quotes from `installer.iss` (see warning below)
6. Compiles with `ISCC.exe`

### Installed components

| Component | Runs as |
|---|---|
| Flutter app (`pos_app.exe`) → `C:\POSKiosk\` | Desktop app |
| NestJS SEA (`POSBackend.exe`) → `C:\POSKiosk\backend\` | Windows service `POSBackendService` (NSSM) |
| PostgreSQL 16 → `C:\POSKiosk\pgsql\` | Windows service `POSPostgres` |

Database data lives in `C:\posdata\`, logs in `C:\POSKiosk\logs\`.

### Smart-quote warning

**Never edit `installer.iss` in an editor with smart-quote autocorrect.** Curly quotes (`" "`) in `[Run]` / `[Files]` directives cause `CreateProcess failed; code 2` because Inno Setup treats them as filename characters, not delimiters. The build script strips them automatically, but manual edits can reintroduce them. Use `npm run check:quotes` / `npm run fix:quotes` to detect and repair.

Install paths have no spaces on purpose — `pg_ctl` cannot register a service whose binary path contains spaces.

---

## Shared conventions

- `develop` is the main integration branch. Feature branches merge into it.
- Backend DTOs in `products/dto/product-details/` define the contract consumed by Flutter's `ProductDetailsDto` / `ProductVariantDetailsDto` — changes to either side require updating both.
- Plans and specs are tracked under `docs/superpowers/plans/` and `docs/superpowers/specs/`.

## Git Rules

- NEVER create git commits unless I explicitly ask.
- NEVER run git commit.
- NEVER run git push.
- Only stage or commit changes when instructed.
