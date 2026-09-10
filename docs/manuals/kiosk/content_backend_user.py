# -*- coding: utf-8 -*-
from manual_helpers import p, lead, h3, h4, steps, ol, ul, note, table, pre

SECTIONS = []
def S(title, *body): SECTIONS.append((title, "".join(body)))

S("What the backend is",
  lead("The &ldquo;backend&rdquo; is a small program that runs in the background on the same Windows machine "
       "as the kiosk. It is the brain and the filing cabinet of the POS: the kiosk screen only draws "
       "pictures and buttons \u2014 every product, price, sale, payment, refund and report is created, "
       "checked and stored by the backend."),
  h3("1.1 The three pieces on the machine"),
  table(["Piece", "Windows service name", "Job"], [
      ["Backend service", "<code>POSBackendService</code>", "Answers the kiosk's requests; enforces the rules; generates receipts and reports."],
      ["Database", "<code>POSPostgres</code>", "Stores the data on disk (PostgreSQL 16)."],
      ["Kiosk app", "(not a service)", "The touch screen staff use."],
  ]),
  h3("1.2 Where things live on disk"),
  table(["Folder", "Contents"], [
      ["<code>C:\\POSKiosk\\</code>", "The installed programs (kiosk app + <code>backend\\</code> + <code>pgsql\\</code>)."],
      ["<code>C:\\posdata\\</code>", "The actual database files. <b>This is what you back up.</b>"],
      ["<code>C:\\POSKiosk\\logs\\</code>", "Log files \u2014 useful for IT when something goes wrong."],
      ["<code>C:\\POSKiosk\\settings.txt</code>", "One line, <code>kiosk.no=&lt;number&gt;</code> \u2014 this lane's number, used in every invoice number."],
  ]),
  note("You normally never touch the backend. It starts with Windows and keeps running. This manual "
       "covers the occasional times you do: first-day setup, checking it's healthy, backups, and "
       "restarting it."))

S("First day: what is already there",
  lead("A fresh install seeds a starter dataset so the kiosk can open."),
  h3("2.1 The seeded administrator"),
  table(["Field", "Value"], [
      ["Name (shown on the kiosk)", "Cody Admin"],
      ["User ID", "<code>admin</code>"],
      ["Email", "<code>admin@cody.inc</code>"],
      ["Password (API only)", "<code>password</code>"],
      ["Kiosk PIN", "<code>123456</code>"],
      ["Role", "Admin"],
  ]),
  note("Sign in on the kiosk as <b>Cody Admin</b> with PIN <code>123456</code>, immediately set a new PIN when "
       "prompted, then create real staff accounts. On a production machine, change this account's "
       "password and PIN before going live.", kind="warn"),
  h3("2.2 Other seeded data"),
  p("The installer optionally seeds sample currencies, tax categories, units of measure, and a starter "
    "set of products / modifiers. Tick <b>&ldquo;Seed initial data&rdquo;</b> only on the very first install; leave it "
    "unticked on upgrades so you don't get duplicates. You can replace the sample products at any time "
    "from the kiosk (Inventory &rarr; Import CSV)."))

S("Checking the backend is healthy",
  h3("3.1 The quick check (any browser on the machine)"),
  table(["Open this address", "A healthy system shows"], [
      ["<code>http://localhost:3000/api/v1/health</code>", "A page of JSON with <code>\"status\":\"ok\"</code> (memory, disk and database all &ldquo;up&rdquo;)."],
      ["<code>http://localhost:3000/api/v1/health/live</code>", "<code>ok</code> \u2014 the service is running."],
      ["<code>http://localhost:3000/api/v1/health/ready</code>", "<code>ok</code> \u2014 the database is reachable."],
  ]),
  p("If the page won't load at all, the backend service is stopped (Section 7)."),
  h3("3.2 The Windows Services check"),
  steps([
      "Press <b>Win + R</b>, type <code>services.msc</code>, press Enter.",
      "Find <b>POSPostgres</b> and <b>POSBackendService</b> in the list.",
      "Both should say <b>Running</b> and <b>Automatic</b> start-up.",
  ]))

S("The Swagger page \u2014 looking inside the backend",
  lead("The backend publishes a self-documenting web page listing every operation it can perform. "
       "You don't need it day to day, but it's the fastest way for a manager or auditor to see what the "
       "system does."),
  steps([
      "On the machine, open <code>http://localhost:3000/api/docs</code>.",
      "You'll see a grouped list (Auth, Users, Products, Sales Orders, Payments, Reports&hellip;). Click a group to expand its operations.",
      "Each operation has a plain-English summary, the information it needs, and an example of what it returns.",
      "To actually try one, first get a token: expand <b>Auth &rarr; POST /auth/login/email</b>, click <b>Try it out</b>, enter the admin email and password, and <b>Execute</b>. Copy the <code>accessToken</code> from the response.",
      "Click the green <b>Authorize</b> button at the top, paste the token, and close the dialog. Now <b>Try it out</b> works on the other operations.",
  ]),
  note("Treat <code>/api/docs</code> as read-only unless you know what you are doing \u2014 some operations change "
       "or delete data."))

S("What each module does (plain language)",
  lead("The backend is organised into modules. Here is what each one is responsible for. Most of them "
       "are driven entirely from the kiosk screens described in the <i>Kiosk \u2014 User Manual</i>."),
  h4("People & access"),
  table(["Module", "Responsible for"], [
      ["Auth", "Signing staff in (by email, user ID, or 6-digit PIN), issuing and refreshing security tokens, and the &ldquo;who am I&rdquo; check."],
      ["Users", "The staff list: create, edit, delete, list &ldquo;authorizers&rdquo; (supervisors/admins who can approve voids &amp; refunds), verify a PIN, and the public login roster the kiosk shows."],
      ["User Groups / User Permissions", "Optional finer-grained permission sets that can be attached to staff."],
      ["User Details / User Addresses", "Extra profile and address information for a staff member."],
  ]),
  h4("The menu / catalogue"),
  table(["Module", "Responsible for"], [
      ["Products / Product Variants", "Every sellable item and its size/price variants; CSV import of a whole menu."],
      ["Product Groups", "Categories that group products, each with an optional cover image."],
      ["Modifier Groups", "Add-on and choice lists (sugar level, extra shot) with min/max rules and per-option prices."],
      ["Catalog", "The fast, read-only feed the kiosk uses to show the menu (active products/categories, with a separate admin feed that also shows hidden items)."],
      ["Menus / Store Menus", "The underlying menu structure and the per-store menu items."],
      ["Tax Categories", "VAT / tax rates that can be applied to products."],
      ["Currencies", "Currency definitions (symbol, code)."],
      ["UOM (Units of Measure)", "Units such as piece, gram, millilitre \u2014 used by inventory."],
  ]),
  h4("Stock & recipes"),
  table(["Module", "Responsible for"], [
      ["Materials / Material Types", "Raw ingredients and supplies, grouped by type."],
      ["Recipes / Recipe Items", "How much of each material a product consumes when sold."],
      ["Inventory Stocks", "Current on-hand quantity of each material."],
      ["Inventory Counts", "Physical stock-take sessions that reconcile the system figure to a real count."],
  ]),
  h4("Selling"),
  table(["Module", "Responsible for"], [
      ["POS Terminals", "The identity of each lane (legal name, address, TIN, kiosk number) and its list of payment methods."],
      ["Sales Orders", "The order itself: line items, discounts, confirm (complete the sale), void (with supervisor PIN)."],
      ["Payments", "Recording how an order was paid \u2014 cash (with tendered/change), card (reference + last 4), or e-wallet (reference)."],
      ["Refunds", "Full or partial refunds against a completed sale, with a reason and supervisor authorisation."],
      ["Discounts", "The discount schemes available at checkout (e.g. Senior/PWD, promos)."],
  ]),
  h4("Reporting"),
  table(["Report", "Shows"], [
      ["Sales report (overall)", "Revenue, transaction count and averages for a date range."],
      ["Hourly / Daily / Monthly", "The same figures broken down by hour, day, or month."],
      ["By Product Group / By Product", "Revenue and quantity per category / per item (top sellers)."],
      ["By User", "Sales performance per cashier."],
      ["By Payment Method", "Cash vs card vs e-wallet split."],
      ["Exportable report / Mark exported", "Transactions not yet sent to an external accounting system, and the action to flag them as sent."],
      ["Cashier X-Reading", "A cashier's running total for today on their terminal (can be read repeatedly; can be &ldquo;closed&rdquo; into history)."],
      ["Cashier Daily Report", "The BIR-style daily summary for a cashier, closable into history."],
      ["Z-Reading", "The store-wide end-of-day close, authorised, with a Z counter and sales-by-cashier."],
  ]),
  h4("Housekeeping"),
  table(["Module", "Responsible for"], [
      ["Device Transfer", "Export the entire device to one encrypted <code>.posbackup</code> file, or restore one onto a replacement machine (full replace). Admin/Supervisor only."],
      ["ERP Sync", "Optional link to a back-office system: pulls the menu in and pushes orders / reports out on a schedule."],
      ["Health", "The status pages in Section 3."],
      ["Cron Jobs", "Scheduled background tasks \u2014 e.g. syncing ERP-managed stock levels every couple of minutes."],
  ]))

S("Routine jobs you may need to do",
  h3("6.1 Back up the data (do this regularly)"),
  p("Everything lives in <code>C:\\posdata\\</code>. Two ways to protect it:"),
  ol([
      "<b>From the kiosk</b> (simplest): <b>Backup &amp; Transfer &rarr; Export Backup</b> writes one encrypted "
      "<code>.posbackup</code> file. Keep it and its passphrase safe. Do this daily / weekly and before any upgrade.",
      "<b>Database dump</b> (for IT): run <code>pg_dump</code> from <code>C:\\POSKiosk\\pgsql\\bin\\</code> against <code>pos_db</code> "
      "on port 5432 and copy the output off the machine.",
  ]),
  note("A backup file contains everyone's PINs (encrypted). Store it like a key list.", kind="warn"),
  h3("6.2 Move to a replacement machine"),
  p("Use <b>Backup &amp; Transfer</b> on both machines \u2014 export on the old one, install the software on the "
    "new one, then <b>Import &amp; Restore</b>. Full step-by-step is in the <i>Kiosk \u2014 User Manual</i>, "
    "&ldquo;Backup &amp; Transfer&rdquo;."),
  h3("6.3 Free up disk space"),
  ul(["Old log files in <code>C:\\POSKiosk\\logs\\</code> can be deleted when the system is healthy.",
      "Do <b>not</b> delete anything in <code>C:\\posdata\\</code>."]))

S("Restarting the backend",
  p("A restart fixes many transient problems and is safe \u2014 no data is lost. Try the database first if "
    "both seem stuck."),
  h3("7.1 From Windows Services"),
  steps([
      "Open <code>services.msc</code>.",
      "Right-click <b>POSPostgres</b> &rarr; <b>Restart</b>. Wait until it says Running.",
      "Right-click <b>POSBackendService</b> &rarr; <b>Restart</b>.",
      "Re-check <code>http://localhost:3000/api/v1/health</code>.",
  ]),
  h3("7.2 The recovery script"),
  p("If the services won't come back, run <code>recover-services.bat</code> as administrator from "
    "<code>C:\\POSKiosk\\scripts\\</code>. It re-checks the database, re-applies any pending updates and "
    "restarts both services."),
  note("If problems persist after a restart, collect the newest lines of "
       "<code>C:\\POSKiosk\\logs\\backend-error.log</code> and give them to your IT contact."))

S("Troubleshooting",
  table(["Symptom", "Likely cause &amp; action"], [
      ["Kiosk stuck on &ldquo;Starting up&rdquo;",
       "Backend or database not running. Restart both services (Section 7); if that fails run the recovery script."],
      ["<code>/api/v1/health</code> won't load",
       "<code>POSBackendService</code> is stopped \u2014 start it in <code>services.msc</code>."],
      ["Health page shows database &ldquo;down&rdquo;",
       "<code>POSPostgres</code> is stopped or <code>C:\\posdata\\</code> is unreachable. Restart <code>POSPostgres</code>; check the disk isn't full."],
      ["&ldquo;Internal server error&rdquo; when saving a sale",
       "<code>C:\\POSKiosk\\settings.txt</code> is missing. Re-create it with <code>kiosk.no=&lt;this lane's number&gt;</code> and restart the backend."],
      ["Invoice numbers show the wrong lane number",
       "Wrong value in <code>settings.txt</code>. Fix it and restart the backend."],
      ["Kiosk lists no products after a fresh install",
       "Initial data wasn't seeded. Import your menu from the kiosk (Inventory &rarr; Import CSV) or re-run the installer's seed step."],
      ["Reports are empty for a date you know had sales",
       "Confirm the terminal is registered and that the sales were actually confirmed (not left as drafts / voided)."],
  ]))
