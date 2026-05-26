# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

```
POS/
├── be/      # NestJS backend (TypeScript · PostgreSQL · Docker)
└── kiosk/   # Flutter Windows kiosk app (Dart · Riverpod · Win32)
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

# Tests
npm run test              # unit tests
npm run test:e2e          # end-to-end
npm run test:cov          # with coverage

# Database migrations (Postgres must be running)
npm run migration:up      # apply pending migrations
npm run migration:down    # revert last migration
npm run migration:generate  # generate from entity changes
npm run migration:create    # blank migration file
npm run migration:show    # list status

# Seeding
npm run seed:run          # run all seeders
npm run seed:create       # scaffold a new seeder

# Docker (manages both Postgres and the app)
npm run docker:build:up   # build image + start containers
npm run docker:dev        # start containers in foreground
npm run docker:down       # stop containers
npm run docker:logs       # stream logs
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

**Data access** — TypeORM with PostgreSQL. Migrations are the only way to change the DB schema — never use `synchronize: true`. Migration files live in `src/database/migrations/` with timestamp-based names.

**Auth** — JWT via Passport. `@Public()` decorator opts out of the default JWT guard. User identity injected with `@CurrentUser()`. Tokens returned from `POST /api/v1/auth/login`.

**Cross-cutting** — `EventEmitterModule` for in-process events; `ScheduleModule` + `CronJobsModule` for scheduled work.

**Important schema note** — Migration `1779582000000` changed `products.image_url` from `BYTEA` to `TEXT` and added `price`, `is_available`, `sort_order`, `category` columns. Migration `1779582000000` also created the `product_modifier_groups` junction table (product → modifier_group, bypassing the store-menu/menu-item chain). The `Product` entity and `FindProductDetailsService` must stay in sync with this newer schema.

---

## Kiosk (`kiosk/`)

### Commands

```bash
# One-time FVM setup
dart pub global activate fvm
fvm use stable

# Install deps + generate code (run after any pubspec or annotated-class change)
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs

# Run on Windows
fvm flutter run -d windows

# Run on Android
fvm flutter run -d android

# Build Windows release
fvm flutter build windows

# Analyze
fvm dart analyze
```

The `.env` file (copy from `.env.sample`) must contain `API_BASE_URL` before running.

### Code generation

`dart_mappable` generates `.mapper.dart` files alongside every `@MappableClass` annotated file. `envied_generator` generates `env.g.dart`. `go_router_builder` generates `router.g.dart`. **Always run `build_runner` after changing any of these files.** Do not manually edit `*.mapper.dart`, `*.g.dart`, or `lib/gen/` files.

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

**Data flow:** View → Riverpod provider → Repository → API source (`lib/data/backend_api/sources/`) → Dio HTTP client → Backend

**State management** — Hooks Riverpod (`hooks_riverpod`). Prefer `HookConsumerWidget` for screens that need both `flutter_hooks` and Riverpod. Providers are declared in `state/` files and consumed via `ref.watch` / `ref.read`.

**HTTP layer** — `lib/data/backend_api/` holds:
- `sources/` — one class per backend resource (e.g., `ProductsApi`)
- `schemas/` — DTOs annotated with `@MappableClass` for JSON ↔ Dart mapping
- `mappers/` — custom `dart_mappable` type mappers (e.g., `ImageUrlMapper` for `Uint8List`)
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

---

## Shared conventions

- **Branch `feature/catalog_migration`** is the active development branch; `develop` is the main integration branch.
- **Catalog migration context** — the `catalog_` prefixed tables were dropped in migration `1779582100000`. The kiosk now reads products via `GET /api/v1/catalog/products` (raw SQL in `CatalogService`) and individual product details via `GET /api/v1/products/:id`. These two endpoints use different data paths and must be kept consistent.
- Backend DTOs in `products/dto/product-details/` define the contract consumed by Flutter's `ProductDetailsDto` / `ProductVariantDetailsDto` — changes to either side require updating both.
