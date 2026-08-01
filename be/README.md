# POS Backend

## Prerequisites

- **Node.js** 18+
- **npm**
- **Docker** and **Docker Compose** (for running with Docker)

## Quick start

1. **Environment** — Copy `.env.example` to `.env` and set your database and JWT values (see [Environment variables](#environment-variables) below).

   ```
   cp .env.example .env
   ```

2. **Install** — `npm install --legacy-peer-deps`
3. **Build and start Postgres and the app** — Builds both and starts them:

   ```bash
   npm run docker:build:up
   ```

   Or in the foreground: `npm run docker:dev`

4. **Migrations** — Run migrations (Postgres must be running, e.g. from step 3):

   ```bash
   npm run migration:up
   ```

5. **Seeders** — Run seeders:

   ```bash
   npm run seed:run
   ```

Then open **http://localhost:3000/api/v1** and **http://localhost:3000/api/docs** (Swagger).

### Run without Docker

Start Postgres (e.g. `docker compose up -d postgres`), then:

```bash
npm install --legacy-peer-deps
npm run migration:up
# Wipe all data and re-run every seeder from scratch
npm run db:reset
npm run seed:run
npm run start:dev
```
