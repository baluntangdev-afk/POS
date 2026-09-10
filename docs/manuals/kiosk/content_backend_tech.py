# -*- coding: utf-8 -*-
from manual_helpers import p, lead, h3, h4, steps, ol, ul, note, table, pre

SECTIONS = []
def S(title, *body): SECTIONS.append((title, "".join(body)))

S("Architecture",
  lead("NestJS (TypeScript) REST API over PostgreSQL, using TypeORM. One process, deployed either via "
       "Docker (dev) or as a Node SEA Windows service (production installer)."),
  h3("1.1 Module layout"),
  p("Each domain lives under <code>be/src/&lt;domain&gt;/</code>:"),
  pre("products/\n"
      "  dto/            input/output DTOs (class-validator)\n"
      "  entities/       TypeORM entities\n"
      "  mapper/         entity <-> DTO mappers (pure static classes)\n"
      "  services/       one file per use-case (CreateProductService, ...)\n"
      "  products.controller.ts\n"
      "  products.service.ts   orchestrates the feature services\n"
      "  products.module.ts"),
  h3("1.2 Cross-cutting"),
  table(["Concern", "Mechanism"], [
      ["Auth", "JWT via Passport. Global JWT guard; <code>@Public()</code> opts out. <code>@CurrentUser()</code> injects identity. Role guards: <code>@RequireAdminOrSupervisor()</code>, <code>AdminOrSupervisorGuard</code>, <code>@RequireAdminOrSupervisorOrSelf('id')</code>."],
      ["Events", "<code>EventEmitterModule</code> (in-process)."],
      ["Scheduling", "<code>ScheduleModule</code> + <code>CronJobsModule</code>."],
      ["Validation", "<code>class-validator</code> / <code>class-transformer</code> on DTOs, global <code>ValidationPipe</code>."],
      ["API docs", "Swagger at <code>/api/docs</code>."],
      ["Global prefix", "<code>api/v1</code> (health also mounted under it)."],
  ]),
  h3("1.3 Data access rules"),
  ul(["TypeORM with PostgreSQL. <b>Never</b> <code>synchronize: true</code>.",
      "Schema changes only via migrations in <code>src/database/migrations/</code> (timestamp-named).",
      "<code>src/database/migrations/index.ts</code> must stay in sync \u2014 <code>npm run migration:sync-index</code> (also run automatically by <code>build:sea</code>).",
      "Seeders in <code>src/database/seeders/</code>; their index is likewise synced."]))

S("Prerequisites & install",
  table(["Tool", "Version"], [
      ["Node.js", "18+ for dev; <b>22 LTS</b> to run <code>build:sea</code> for the installer"],
      ["npm", "bundled with Node"],
      ["Docker + Compose", "any recent (manages Postgres + app)"],
      ["PostgreSQL", "16 (via Docker in dev; portable binaries bundled in the installer)"],
  ]),
  pre("cd be\n"
      "cp .env.example .env            # then edit\n"
      "npm install --legacy-peer-deps  # REQUIRED flag\n"
      "npm run docker:build:up         # build image + start Postgres & app\n"
      "npm run migration:up\n"
      "npm run seed:run\n"
      "# API:     http://localhost:3000/api/v1\n"
      "# Swagger: http://localhost:3000/api/docs"),
  h4("Without Docker"),
  pre("docker compose up -d postgres   # or a local Postgres 16\n"
      "npm install --legacy-peer-deps\n"
      "npm run migration:up\n"
      "npm run db:reset               # wipe + re-run every seeder\n"
      "npm run seed:run\n"
      "npm run start:dev"),
  note("<code>npm run lint</code> is <code>eslint --fix</code> across the whole tree \u2014 it rewrites unrelated files. "
       "Scope lint to changed files and use <code>npm run build</code> for a full type-check.", kind="warn"))

S("Environment variables",
  table(["Variable", "Default / example", "Purpose"], [
      ["<code>NODE_ENV</code>", "<code>development</code>", "Runtime mode"],
      ["<code>PORT</code>", "<code>3000</code>", "HTTP port"],
      ["<code>POSTGRES_HOST</code>", "<code>localhost</code>", "DB host"],
      ["<code>POSTGRES_PORT</code>", "<code>5432</code>", "DB port"],
      ["<code>POSTGRES_USER</code>", "<code>postgres</code>", "DB user (needs superuser for device-transfer import)"],
      ["<code>POSTGRES_PASSWORD</code>", "<code>postgres</code>", "DB password \u2014 set a strong one in prod"],
      ["<code>POSTGRES_DB</code>", "<code>pos_db</code>", "Database name"],
      ["<code>JWT_SECRET</code>", "random hex", "Access-token signing key"],
      ["<code>JWT_EXPIRES_IN</code>", "<code>15m</code>", "Access-token lifetime"],
      ["<code>JWT_REFRESH_SECRET</code>", "random hex", "Refresh-token signing key (separate from above)"],
      ["<code>JWT_REFRESH_EXPIRES_IN</code>", "<code>7d</code>", "Refresh-token lifetime"],
      ["<code>KIOSK_NO</code>", "<code>1</code>", "Kiosk number \u2014 <b>dev only</b>; in prod it is read from <code>C:\\POSKiosk\\settings.txt</code>"],
      ["<code>ERP_SYNC_ENABLED</code>", "<code>true</code>", "Enable the back-office integration"],
      ["<code>ERP_BASE_URL</code>", "<code>http://localhost:5000</code>", "ERP base URL"],
      ["<code>ERP_USERNAME</code> / <code>ERP_PASSWORD</code>", "\u2014", "ERP credentials"],
      ["<code>ERP_TERMINAL_ID</code>", "<code>POS-1</code>", "Terminal id reported to the ERP"],
      ["<code>ERP_STORE_CODE</code>", "<code>MAIN</code>", "Store code reported to the ERP"],
  ]),
  note("The installer bundles <code>.env.prod</code> as the runtime <code>.env</code>. Generate JWT secrets with "
       "<code>openssl rand -hex 48</code>. Never commit <code>.env*</code>."))

S("Commands reference",
  table(["Command", "Does"], [
      ["<code>npm run start:dev</code>", "Dev server with hot reload"],
      ["<code>npm run build</code>", "Full <code>nest build</code> / type-check"],
      ["<code>npm run lint</code> / <code>format</code> / <code>format:check</code>", "ESLint --fix (whole tree) / Prettier"],
      ["<code>npm run test</code> / <code>test:watch</code> / <code>test:e2e</code> / <code>test:cov</code>", "Unit / watch / e2e / coverage"],
      ["<code>npx jest --testPathPattern=src/products/products.service.spec.ts</code>", "Single test file"],
      ["<code>npm run migration:up</code> / <code>:down</code> / <code>:show</code>", "Apply / revert last / list status"],
      ["<code>npm run migration:generate</code> / <code>:create</code>", "Generate from entity diff / blank file"],
      ["<code>npm run migration:sync-index</code>", "Rebuild <code>migrations/index.ts</code>"],
      ["<code>npm run seed:run</code> / <code>seed:create</code>", "Run all seeders / scaffold one"],
      ["<code>npm run db:reset</code>", "Drop + recreate (dev only)"],
      ["<code>npm run docker:build:up</code> / <code>docker:dev</code> / <code>docker:down</code> / <code>docker:logs</code>", "Container lifecycle"],
      ["<code>npm run pm2:start</code> / <code>:restart</code> / <code>:logs</code> / <code>:monit</code>", "PM2 process management (alt. production runner)"],
      ["<code>npm run build:sea</code>", "Sync indexes + nest build + package to <code>be/POSBackend.exe</code> (Node SEA)"],
      ["<code>npm run check:quotes</code> / <code>fix:quotes</code>", "Detect / repair curly quotes in <code>installer.iss</code>"],
  ]))

S("Authentication flow",
  table(["Endpoint", "Body", "Returns"], [
      ["<code>POST /api/v1/auth/login/email</code>", "email + password (LocalAuthGuard)", "access + refresh tokens"],
      ["<code>POST /api/v1/auth/login/user-id</code>", "userId + password", "tokens"],
      ["<code>POST /api/v1/auth/login/pin</code>", "userId + 6-digit PIN (kiosk login)", "tokens + <code>isPinChanged</code> flag"],
      ["<code>POST /api/v1/auth/refresh</code>", "refresh token", "new token pair"],
      ["<code>GET /api/v1/auth/me</code>", "Bearer token", "current user"],
  ]),
  p("The kiosk uses <b>PIN login</b>; a <code>false</code> <code>isPinChanged</code> forces the client through the "
    "PIN-setup screen (<code>PATCH /users/:id</code>). <code>POST /users/verify-pin</code> backs the on-the-spot "
    "supervisor authorisation for voids, refunds and report closes. <code>GET /users/roster</code> is "
    "<code>@Public()</code> and feeds the kiosk's &ldquo;Who's working?&rdquo; screen."))

S("API reference \u2014 catalogue & menu",
  h4("Products \u2014 <code>/api/v1/products</code>"),
  table(["Method", "Path", "Summary"], [
      ["POST", "<code>/products</code>", "Create a product"],
      ["POST", "<code>/products/import-csv</code>", "Import categories/products/variants from a CSV (upsert or replace)"],
      ["GET", "<code>/products</code>", "List all products"],
      ["GET", "<code>/products/:id</code>", "Get a product by id (kiosk product-details contract)"],
      ["PATCH", "<code>/products/:id</code>", "Update a product"],
  ]),
  h4("Product Variants \u2014 <code>/api/v1/product-variants</code>"),
  table(["Method", "Path", "Summary"], [
      ["POST", "<code>/product-variants</code>", "Create a variant (admin/supervisor)"],
      ["GET", "<code>/product-variants/names</code>", "Distinct variant names used across products"],
      ["GET", "<code>/product-variants/by-product/:productId</code>", "Variants for a product"],
      ["GET", "<code>/product-variants/:id</code>", "Get a variant"],
      ["PATCH", "<code>/product-variants/:id</code>", "Update a variant (admin/supervisor)"],
  ]),
  h4("Product Groups \u2014 <code>/api/v1/product-groups</code>"),
  table(["Method", "Path", "Summary"], [
      ["POST", "<code>/product-groups</code>", "Create a group (multipart, optional <code>image</code>)"],
      ["GET", "<code>/product-groups</code>", "List all groups"],
      ["GET", "<code>/product-groups/:id</code>", "Get a group"],
      ["GET", "<code>/product-groups/:id/products</code>", "Products in a group (paginated)"],
      ["PATCH", "<code>/product-groups/:id</code>", "Update a group (multipart)"],
      ["DELETE", "<code>/product-groups/:id</code>", "Remove a group"],
  ]),
  h4("Modifier Groups \u2014 <code>/api/v1/modifier-groups</code>"),
  table(["Method", "Path", "Summary"], [
      ["POST", "<code>/modifier-groups</code>", "Create a group with options"],
      ["GET", "<code>/modifier-groups</code> &middot; <code>/:id</code>", "List / get"],
      ["PATCH", "<code>/modifier-groups/:id</code>", "Update"],
      ["DELETE", "<code>/modifier-groups/:id</code>", "Remove"],
  ]),
  h4("Catalog (kiosk read path) \u2014 <code>/api/v1/catalog</code>"),
  table(["Method", "Path", "Summary"], [
      ["GET", "<code>/catalog/categories</code>", "Active categories + available product counts"],
      ["GET", "<code>/catalog/products</code>", "Available products with nested category + modifier groups (raw SQL, fast)"],
      ["GET", "<code>/catalog/modifier-groups</code>", "All modifier groups with nested modifiers"],
      ["GET", "<code>/catalog/admin/categories</code>", "All categories incl. inactive (authed)"],
      ["GET", "<code>/catalog/admin/products</code>", "All products incl. disabled/unavailable (authed)"],
      ["POST", "<code>/catalog/admin/categories</code>", "Create category (admin/supervisor)"],
      ["PATCH", "<code>/catalog/admin/categories/:id</code>", "Update category (admin/supervisor)"],
  ]),
  note("<code>GET /catalog/products</code> and <code>GET /products/:id</code> use different data paths and must be "
       "kept consistent. Migration <code>1779582100000</code> dropped the <code>catalog_</code>-prefixed tables; "
       "migration <code>1779582000000</code> changed <code>products.image_url</code> BYTEA&rarr;TEXT and added "
       "<code>price</code>, <code>is_available</code>, <code>sort_order</code>, <code>category</code> plus the "
       "<code>product_modifier_groups</code> junction. Keep the <code>Product</code> entity and "
       "<code>FindProductDetailsService</code> in sync."),
  h4("Menus / Store Menus / Tax / Currency / UOM"),
  table(["Base", "Endpoints"], [
      ["<code>/api/v1/menus</code>", "CRUD (<code>POST</code>, <code>GET</code>, <code>GET/:id</code>, <code>PATCH/:id</code>, <code>DELETE/:id</code>)"],
      ["<code>/api/v1/store-menus</code>", "CRUD, plus <code>POST|GET|PATCH|DELETE /store-menus/menu-items[/:id]</code> against the default store menu"],
      ["<code>/api/v1/tax-categories</code>", "CRUD"],
      ["<code>/api/v1/currencies</code>", "CRUD"],
      ["<code>/api/v1/uom</code>", "CRUD"],
  ]))

S("API reference \u2014 selling",
  h4("Sales Orders \u2014 <code>/api/v1/sales-orders</code>"),
  table(["Method", "Path", "Summary"], [
      ["POST", "<code>/sales-orders</code>", "Create a sales order"],
      ["GET", "<code>/sales-orders</code>", "List (paged/sortable \u2014 Transactions screen)"],
      ["GET", "<code>/sales-orders/current</code>", "The current (open) order"],
      ["GET", "<code>/sales-orders/:id</code> &middot; <code>/:id/with-items</code>", "Order header / order with line items"],
      ["GET", "<code>/sales-orders/:id/item/:itemId</code>", "One line item"],
      ["PATCH", "<code>/sales-orders/:id/item/:itemId</code>", "Update a line item"],
      ["DELETE", "<code>/sales-orders/:id/item/:itemId</code>", "Remove a line item"],
      ["PATCH", "<code>/sales-orders/:id/discount</code>", "Apply a discount to the order"],
      ["PATCH", "<code>/sales-orders/:id/confirm</code>", "Confirm / complete the sale"],
      ["PATCH", "<code>/sales-orders/:id/void</code>", "Void \u2014 requires admin or supervisor PIN"],
  ]),
  h4("Payments \u2014 <code>/api/v1/payments</code>, Refunds \u2014 <code>/api/v1/refunds</code>, Discounts \u2014 <code>/api/v1/discounts</code>"),
  table(["Base", "Endpoints"], [
      ["<code>/payments</code>", "<code>POST</code>, <code>GET</code>, <code>GET/:id</code>, <code>PATCH/:id</code>, <code>DELETE/:id</code>"],
      ["<code>/refunds</code>", "<code>POST</code> (with reason + authoriser), <code>GET</code>, <code>GET/:id</code>, <code>PATCH/:id</code>, <code>DELETE/:id</code>"],
      ["<code>/discounts</code>", "<code>POST</code>, <code>GET</code>, <code>GET/:id</code>, <code>PATCH/:id</code>, <code>DELETE/:id</code>"],
  ]),
  h4("POS Terminals \u2014 <code>/api/v1/pos-terminals</code>"),
  table(["Method", "Path", "Summary"], [
      ["GET", "<code>/pos-terminals/my-terminal</code>", "Terminal assigned to the current user"],
      ["PATCH", "<code>/pos-terminals/my-terminal</code>", "Update terminal details (legal name, address, TIN)"],
      ["POST", "<code>/pos-terminals/register</code>", "Register a new terminal for the current admin"],
      ["POST", "<code>/pos-terminals/my-terminal/payment-methods</code>", "Add a payment method"],
      ["PATCH", "<code>/pos-terminals/my-terminal/payment-methods/:id</code>", "Update a payment method"],
      ["DELETE", "<code>/pos-terminals/my-terminal/payment-methods/:id</code>", "Remove a payment method"],
  ]),
  note("The kiosk number in every sales-order number (e.g. <code>SO-001-2026-0001</code>) comes from "
       "<code>KIOSK_NO</code> in dev and <code>C:\\POSKiosk\\settings.txt</code> in production."))

S("API reference \u2014 users, inventory, reports",
  h4("Users \u2014 <code>/api/v1/users</code>"),
  table(["Method", "Path", "Summary / guard"], [
      ["POST", "<code>/users</code>", "Create \u2014 <code>@RequireAdminOrSupervisor()</code>"],
      ["GET", "<code>/users</code>", "List \u2014 <code>@RequireAdminOrSupervisor()</code>"],
      ["GET", "<code>/users/authorizers</code>", "Supervisors/admins who can authorise"],
      ["GET", "<code>/users/roster</code>", "Public login roster (kiosk)"],
      ["POST", "<code>/users/verify-pin</code>", "Verify a PIN (on-the-spot authorisation)"],
      ["GET", "<code>/users/:id</code>", "Get a user"],
      ["PATCH", "<code>/users/:id</code>", "Update \u2014 <code>@RequireAdminOrSupervisorOrSelf('id')</code> (also the PIN-change path)"],
      ["DELETE", "<code>/users/:id</code>", "Delete \u2014 <code>@RequireAdminOrSupervisor()</code>"],
  ]),
  p("Supporting: <code>/api/v1/user-groups</code>, <code>/user-permissions</code>, <code>/user-details</code>, "
    "<code>/user-addresses</code> \u2014 each standard CRUD."),
  h4("Inventory \u2014 materials, recipes, stock, counts"),
  table(["Base", "Endpoints"], [
      ["<code>/api/v1/materials</code>", "CRUD (<code>POST</code>, <code>GET</code>, <code>GET/:id</code>, <code>PATCH/:id</code>, <code>DELETE/:id</code>)"],
      ["<code>/api/v1/material-types</code>", "CRUD"],
      ["<code>/api/v1/recipes</code>", "CRUD \u2014 material components + quantities per product"],
      ["<code>/api/v1/inventory-stocks</code>", "On-hand quantities"],
      ["<code>/api/v1/inventory-counts</code>", "Physical count / reconciliation sessions"],
  ]),
  h4("Reports \u2014 <code>/api/v1/reports</code>"),
  table(["Method", "Path", "Summary"], [
      ["GET", "<code>/reports</code>", "Overall sales report (date range)"],
      ["GET", "<code>/reports/type/hourly</code> &middot; <code>/type/daily</code> &middot; <code>/type/monthly</code>", "Time-bucketed breakdowns"],
      ["GET", "<code>/reports/product-group</code> &middot; <code>/product</code>", "Revenue by category / by item"],
      ["GET", "<code>/reports/user</code> &middot; <code>/payment</code>", "By cashier / by payment method"],
      ["GET", "<code>/reports/exportable</code>", "Aggregated unexported transactions for a date"],
      ["PATCH", "<code>/reports/mark-exported</code>", "Mark that date's transactions exported"],
      ["GET", "<code>/reports/cashier-x-reading</code>", "Current cashier X-Reading (today, self, own terminal)"],
      ["POST", "<code>/reports/cashier-x-reading/close</code>", "Close the X-Reading into history"],
      ["GET", "<code>/reports/cashier-x-reading/history[/:id]</code>", "List / get past X-Readings"],
      ["GET", "<code>/reports/cashier-daily-report</code>", "Current cashier daily report"],
      ["POST", "<code>/reports/cashier-daily-report/close</code>", "Close it into history"],
      ["GET", "<code>/reports/cashier-daily-report/history[/:id]</code>", "List / get past daily reports"],
      ["GET", "<code>/reports/z-reading</code>", "Current store-wide Z-Reading"],
      ["POST", "<code>/reports/z-reading/close</code>", "Close (authorised) \u2014 advances the Z counter"],
      ["GET", "<code>/reports/z-reading/history[/:id]</code>", "List / get past Z-Readings (store-wide)"],
  ]))

S("Health, ERP sync & cron",
  h3("10.1 Health"),
  table(["Endpoint", "Checks"], [
      ["<code>GET /api/v1/health</code>", "memory + disk + postgres"],
      ["<code>GET /api/v1/health/live</code>", "memory only (liveness)"],
      ["<code>GET /api/v1/health/ready</code>", "postgres (readiness)"],
  ]),
  p("<code>GET /health/live</code> <b>without</b> the <code>api/v1</code> prefix returns 404 \u2014 expected."),
  h3("10.2 ERP sync \u2014 <code>/api/v1/erp-sync</code>"),
  table(["Method", "Path", "Summary"], [
      ["POST", "<code>/erp-sync/menu</code>", "Pull the menu from the ERP into the POS"],
      ["POST", "<code>/erp-sync/reports/backfill</code>", "Re-push historical reports to the ERP"],
      ["GET", "<code>/erp-sync/status</code>", "Last sync status"],
  ]),
  p("Configured by the <code>ERP_*</code> env vars. Disabled entirely with <code>ERP_SYNC_ENABLED=false</code>."),
  h3("10.3 Cron jobs"),
  p("<code>CronJobsModule</code> runs scheduled work \u2014 e.g. syncing ERP-managed inventory stock every 2 minutes "
    "(<code>*/2 * * * *</code>) for products that carry an SKU."))

S("Device transfer internals",
  p("<code>src/device-transfer/</code>. Endpoints (admin/supervisor only):"),
  table(["Method", "Path", "Summary"], [
      ["POST", "<code>/api/v1/device-transfer/export</code>", "Export the full <code>public</code> schema as one gzipped-then-AES-256-GCM-encrypted <code>.posbackup</code>"],
      ["POST", "<code>/api/v1/device-transfer/import</code>", "Replace the full dataset from a <code>.posbackup</code> (destructive)"],
  ]),
  ul([
      "Export includes every base table plus the <code>migrations</code> table.",
      "Import runs in one transaction: <code>SET LOCAL session_replication_role='replica'</code> (needs a superuser DB role \u2014 true for the bundled Postgres), <code>TRUNCATE &hellip; CASCADE</code>, bulk re-insert preserving primary keys, then reset every sequence (parsed from <code>column_default</code>, so standalone sequences like <code>z_readings_z_counter_seq</code> are covered).",
      "A <b>strict</b> import is refused unless the archive's migration history is identical to the target's.",
      "<code>partialRestore: 'true'</code> skips the migration gate, keeps the target's own <code>migrations</code> table, and imports only tables/columns present on both devices; a table is dropped whole if the target added a required column the archive lacks, a column is dropped if its Postgres <code>udt</code> changed. Everything skipped is returned in <code>DeviceImportSummaryDto.skipped</code> (<code>{ tables, columns }</code>).",
  ]),
  note("See <code>docs/runbooks/kiosk-device-migration.md</code> for the operational procedure."))

S("Migrations & schema",
  steps([
      "Change an entity.",
      "<code>npm run migration:generate</code> (diff-based) or <code>npm run migration:create</code> (blank), name it with a timestamp.",
      "Review the generated SQL. Migrations are the <b>only</b> way the schema changes.",
      "<code>npm run migration:up</code> to apply; <code>npm run migration:show</code> to check status; <code>npm run migration:down</code> reverts the last one.",
      "<code>npm run migration:sync-index</code> to refresh <code>migrations/index.ts</code> (<code>build:sea</code> does this automatically).",
  ]),
  h4("Notable migrations"),
  table(["Migration", "Effect"], [
      ["<code>1779582000000</code>", "<code>products.image_url</code> BYTEA&rarr;TEXT; adds <code>price</code>, <code>is_available</code>, <code>sort_order</code>, <code>category</code>; creates <code>product_modifier_groups</code> junction"],
      ["<code>1779582100000</code>", "Drops the <code>catalog_</code>-prefixed tables; kiosk now reads via <code>/catalog/products</code> + <code>/products/:id</code>"],
  ]),
  p("The installer runs all migrations (79 at time of writing) on first install and again via "
    "<code>POSBackend.exe --migrate</code> during recovery."))

S("Production build & Windows installer",
  h3("13.1 Backend SEA"),
  pre("cd be\n"
      "npm install\n"
      "npm run build:sea      # sync indexes -> nest build -> @vercel/ncc bundle\n"
      "                       # -> SEA blob -> inject into node -> be\\POSBackend.exe"),
  p("Output <code>be\\POSBackend.exe</code> (~80\u2013120 MB). Build machine needs <b>Node 22 LTS</b>."),
  h3("13.2 Full installer"),
  pre("# repo root, prompts for version:\n"
      ".\\build-installer.bat\n"
      "# 1 verify prereqs (Inno Setup 6, C:\\pgsql, C:\\nssm, be\\.env.prod)\n"
      "# 2 optionally bump #define MyAppVersion in installer.iss\n"
      "# 3 flutter codegen (pub get + build_runner)\n"
      "# 4 parallel: npm run build:sea  +  fvm flutter build windows\n"
      "# 5 auto-strip curly quotes from installer.iss\n"
      "# 6 compile with ISCC.exe\n"
      "# -> be\\installer\\output\\POSKiosk-Setup-<version>.exe"),
  h3("13.3 What the installer does on the target"),
  table(["Step", "Action"], [
      ["0", "Silently installs VC++ 2015\u20132022 redistributable"],
      ["1", "Extracts to <code>C:\\POSKiosk\\</code>"],
      ["2\u20135", "Inits PostgreSQL data dir <code>C:\\posdata\\</code>, configures <code>postgresql.conf</code>, grants <code>NT AUTHORITY\\NetworkService</code>, registers + starts <code>POSPostgres</code>"],
      ["6\u20137", "Waits for Postgres, creates <code>pos_db</code>"],
      ["8\u20139", "Runs all TypeORM migrations; optionally seeds"],
      ["10", "Installs <code>POSBackendService</code> via NSSM (auto-start)"],
      ["11", "Writes <code>C:\\POSKiosk\\settings.txt</code> with the wizard's kiosk number"],
  ]),
  note("Install paths contain no spaces on purpose \u2014 <code>pg_ctl</code> cannot register a service whose "
       "binary path has spaces. Never edit <code>installer.iss</code> in an editor with smart-quote "
       "autocorrect; use <code>npm run check:quotes</code> / <code>fix:quotes</code>.", kind="warn"))

S("Verification & troubleshooting",
  h4("Verify an install (elevated PowerShell on the target)"),
  pre("Get-Service POSPostgres, POSBackendService | Format-Table Name, Status\n"
      '& "C:\\POSKiosk\\pgsql\\bin\\pg_isready.exe" -h 127.0.0.1 -p 5432\n'
      'Invoke-WebRequest http://localhost:3000/api/v1/health -UseBasicParsing   # 401 = endpoint up, auth active\n'
      'Get-Content "C:\\POSKiosk\\settings.txt"                                   # kiosk.no=<n>'),
  h4("Common issues"),
  table(["Symptom", "Fix"], [
      ['App: &ldquo;no internet connection&rdquo;', "Check both services Running; <code>pg_isready</code>; tail <code>setup-postgres-install.log</code> and <code>backend-error.log</code>."],
      ["Internal server error on payment / sales order", "<code>settings.txt</code> missing \u2014 recreate <code>kiosk.no=1</code> (ASCII) and <code>Restart-Service POSBackendService</code>."],
      ["Missing tables / <code>42P01</code>", "Migrations didn't run: <code>Set-Location C:\\POSKiosk\\backend; .\\POSBackend.exe --migrate; Restart-Service POSBackendService</code>."],
      ["<code>POSPostgres</code> not registered", "Old install path had spaces \u2014 reinstall with the current installer (<code>C:\\POSKiosk</code>)."],
      ["<code>CreateProcess failed; code 2</code> during install", "Curly quotes in <code>installer.iss</code> <code>[Run]</code>/<code>[Files]</code> \u2014 run <code>npm run fix:quotes</code> and recompile."],
  ]),
  h4("Log locations"),
  table(["Log", "Contents"], [
      ["<code>C:\\POSKiosk\\logs\\setup-postgres-install.log</code>", "DB init, service registration, migrations"],
      ["<code>C:\\POSKiosk\\logs\\install-backend-service-install.log</code>", "NSSM service install + health check"],
      ["<code>C:\\POSKiosk\\logs\\backend-output.log</code> / <code>backend-error.log</code>", "Live NestJS stdout / stderr"],
      ["<code>C:\\posdata\\log\\postgresql.log</code>", "PostgreSQL server log"],
  ]))
