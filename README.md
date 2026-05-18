# POS System

A Point of Sale system consisting of a NestJS REST API backend and a Flutter Windows kiosk app.

## Repository structure

```
POS/
├── be/      # NestJS backend (Node.js / TypeScript / PostgreSQL)
└── kiosk/   # Flutter kiosk app (Windows desktop)
```

## Backend (`be/`)

**Stack:** NestJS · TypeScript · PostgreSQL · Docker

**Covers:** auth, users & permissions, products, menus, modifier groups, materials & recipes, inventory, sales orders, payments, refunds, discounts, tax categories, currencies, reports, and cron jobs.

See [`be/README.md`](be/README.md) for full setup and environment variable details.

### Quick start

```bash
cd be
cp .env.example .env   # fill in DB and JWT values
npm install --legacy-peer-deps
npm run docker:build:up   # starts Postgres + app
npm run migration:up
npm run seed:run
```

API root: `http://localhost:3000/api/v1`  
Swagger docs: `http://localhost:3000/api/docs`

## Kiosk (`kiosk/`)

**Stack:** Flutter · Dart · Riverpod · ESC/POS printing · Win32

A Windows desktop POS kiosk app. Uses [FVM](https://fvm.app) to pin the Flutter version.

See [`kiosk/README.md`](kiosk/README.md) for FVM setup and environment variable details.

### Quick start

```bash
cd kiosk
dart pub global activate fvm   # install FVM (once)
fvm use stable                 # install pinned Flutter version
cp .env.sample .env            # fill in API base URL and keys
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run -d windows
```

## Prerequisites

| Tool | Version | Used by |
|------|---------|---------|
| Node.js | 18+ | `be/` |
| npm | bundled with Node | `be/` |
| Docker & Docker Compose | any recent | `be/` |
| Dart SDK | ^3.7.2 | `kiosk/` |
| Flutter (via FVM) | stable | `kiosk/` |
