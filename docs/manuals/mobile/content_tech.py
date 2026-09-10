# -*- coding: utf-8 -*-
"""Technical-manual content for POS Mobile."""

from manual_helpers import p, lead, h3, h4, ul, ol, steps, note, table, pre

SECTIONS = []


def add(title, body):
    SECTIONS.append((title, body))


# ---------------------------------------------------------------------------
add("Overview & tech stack", "".join([
    lead("POS Mobile is an <b>offline-first Flutter application</b> in the "
         "<code>mobile/</code> folder of the POS monorepo. It targets Android "
         "primarily (also builds for Windows). All business data lives in a "
         "local SQLite database; the only network dependency is the live "
         "online-orders feed and its device registration."),
    table(["Concern", "Choice"], [
        ["Language / SDK", "Dart <code>^3.7.2</code>, Flutter"],
        ["Local database", "<code>drift</code> + <code>drift_flutter</code> "
         "(SQLite), schema version <b>14</b>"],
        ["State management", "<code>hooks_riverpod</code> + "
         "<code>flutter_hooks</code>"],
        ["Navigation", "<code>go_router</code> (hand-written routes, no "
         "codegen router)"],
        ["Models / JSON", "<code>dart_mappable</code> "
         "(<code>*.mapper.dart</code>)"],
        ["Config", "<code>envied</code> — <code>.env</code> baked in at "
         "build time (<code>env.g.dart</code>)"],
        ["Auth", "local PIN, <code>bcrypt</code> hashes; no server, no "
         "session persistence"],
        ["Realtime", "<code>web_socket_channel</code>, "
         "<code>connectivity_plus</code>, "
         "<code>flutter_local_notifications</code>"],
        ["HTTP", "<code>dio</code> (device registration, order status "
         "updates)"],
        ["Printing", "<code>esc_pos_utils_plus</code>, "
         "<code>print_bluetooth_thermal</code>, a platform channel for a "
         "built-in printer, <code>pdf</code> / <code>printing</code>"],
        ["Backups", "<code>archive</code> (zip), <code>media_store_plus</code> "
         "(Downloads), <code>workmanager</code> (periodic job)"],
        ["Email", "<code>mailer</code> (SMTP via Gmail app password)"],
        ["Charts", "<code>fl_chart</code> (reports screen, currently "
         "hidden)"],
    ]),
    note("App identity: package <code>com.dpo.mobile</code>, Android label "
         "<b>POS Mobile</b>, in-app brand <b>Cartivo</b>, "
         "<code>MaterialApp</code> title <code>POS Mobile</code>. "
         "pubspec version <code>1.2.0+3</code>."),
]))

# ---------------------------------------------------------------------------
add("Repository layout", "".join([
    pre(
        "mobile/\n"
        "  lib/\n"
        "    main.dart                 app bootstrap (DB, seeder, backup, notifications)\n"
        "    config/environment/       AppEnv interface + Env (envied) + env.g.dart\n"
        "    core/\n"
        "      database/               Drift: app_database.dart, tables/, daos/\n"
        "      navigation/router.dart  GoRouter + redirect guard\n"
        "      seeder/                 AdminSeeder (default admin / PIN 000000)\n"
        "      services/               backup/, notifications/, printing, bluetooth, csv email\n"
        "      workers/                backup_worker.dart (WorkManager dispatcher)\n"
        "      csv/                    CSV importers + report exporter\n"
        "      theme/  widgets/  utils/  providers/  result/  crypto/\n"
        "    data/\n"
        "      backend_api/            sources/ schemas/ errors/ (online-orders API)\n"
        "      secure_storage/         flutter_secure_storage wrappers\n"
        "    features/<name>/          one folder per feature (see below)\n"
        "  android/  windows/  assets/\n"
        "  .env / .env.sample\n"
    ),
    h3("Feature module layout"),
    pre(
        "features/<feature>/\n"
        "  entities/       immutable domain models (+ .mapper.dart)\n"
        "  repositories/   abstract interface + Impl (calls DAO / API source)\n"
        "  state/          Riverpod notifiers / providers\n"
        "  use_cases/      (optional) single-purpose operations\n"
        "  view/           screens + dialogs (HookConsumerWidget)\n"
    ),
    p("Features present: <code>auth</code>, <code>dashboard</code>, "
      "<code>ordering</code>, <code>transactions</code>, <code>orders</code> + "
      "<code>live_orders</code>, <code>cashier_accounting</code> (x_reading / "
      "z_reading / daily_report), <code>inventory</code>, <code>users</code>, "
      "<code>settings</code>, <code>reports</code> (built but not linked from "
      "the dashboard)."),
    note("Clean-architecture rule: <code>lib/data/</code> must never import "
         "<code>lib/features/</code>. Error translation "
         "(<code>DioException</code> &rarr; <code>ApiException</code>) lives in "
         "the data layer."),
]))

# ---------------------------------------------------------------------------
add("Environment configuration", "".join([
    lead("Config is compiled in via <code>envied</code>. Copy "
         "<code>.env.sample</code> to <code>.env</code> and fill it before "
         "building — a missing <code>.env</code> fails code generation."),
    table(["Variable", "Purpose", "Obfuscated"], [
        ["<code>ORDERS_LIVE_FEED_WS_URL</code>",
         "WebSocket base URL for the live orders feed.", "no"],
        ["<code>ORDERS_EVENTS_API_BASE_URL</code>",
         "REST base URL for order-status updates &amp; auth token exchange "
         "(often the same host).", "no"],
        ["<code>CLIENT_ID</code>",
         "Client identifier presented to the orders service.", "no"],
        ["<code>WEBHOOK_SECRET</code>",
         "Shared secret for the orders <code>/auth/token</code> exchange.",
         "<b>yes</b>"],
        ["<code>CSV_EXPORT_PASSWORD</code>",
         "If non-empty, users must enter it before downloading any report CSV. "
         "Empty = no gate.", "<b>yes</b>"],
        ["<code>SENDER_EMAIL</code>",
         "Gmail address that sends report CSV emails.", "no"],
        ["<code>SENDER_APP_PASSWORD</code>",
         "Gmail <b>App Password</b> (needs 2-Step Verification on the sender "
         "account) — not the normal password.", "<b>yes</b>"],
    ]),
    note("Obfuscated fields are XOR-masked in <code>env.g.dart</code>, not "
         "encrypted — they deter casual inspection of the APK, nothing "
         "more. Rotate them like any embedded secret."),
    p("New variables must be added in three places: <code>.env.sample</code>, "
      "the <code>AppEnv</code> interface, and as an <code>@EnviedField()</code> "
      "on <code>Env</code> in <code>lib/config/environment/</code>. Then re-run "
      "<code>build_runner</code>."),
    p("<code>Env()</code> is provided at the root via "
      "<code>appEnvProvider.overrideWithValue(Env())</code> in "
      "<code>main.dart</code>."),
]))

# ---------------------------------------------------------------------------
add("Development setup", "".join([
    pre(
        "cd mobile\n"
        "cp .env.sample .env          # then fill in the values\n"
        "flutter pub get\n"
        "dart run build_runner build --delete-conflicting-outputs\n"
        "\n"
        "flutter run -d android        # or: flutter run -d windows\n"
        "dart analyze                  # static analysis (flutter_lints)\n"
    ),
    note("There is a <code>dependency_overrides</code> pin on "
         "<code>path_provider_android: 2.2.22</code> — keep it unless you "
         "verify a newer version works."),
    h3("Code generation"),
    p("Re-run <code>build_runner</code> after touching any of:"),
    table(["Generator", "Produces", "Trigger"], [
        ["<code>drift_dev</code>", "<code>*.g.dart</code> for the database",
         "table / DAO changes"],
        ["<code>dart_mappable_builder</code>", "<code>*.mapper.dart</code>",
         "any <code>@MappableClass</code> model"],
        ["<code>envied_generator</code>", "<code>env.g.dart</code>",
         "<code>.env</code> or <code>Env</code> field changes"],
    ]),
    p("Never hand-edit <code>*.g.dart</code> or <code>*.mapper.dart</code>."),
]))

# ---------------------------------------------------------------------------
add("Local database", "".join([
    lead("<code>AppDatabase</code> (<code>lib/core/database/app_database.dart</code>) "
         "opens a Drift/SQLite database named <code>mobile_pos</code> via "
         "<code>driftDatabase(name: 'mobile_pos')</code>. "
         "<code>schemaVersion = 14</code>."),
    ul([
        "<b>Migrations</b> — <code>MigrationStrategy</code> with an "
        "<code>onUpgrade</code> that steps <code>from &rarr; to</code>. Add a "
        "new block per version bump; never <code>synchronize</code>-style "
        "auto-migrate.",
        "<b>Seeding</b> — <code>AdminSeeder(db).seed()</code> runs in "
        "<code>main()</code>. If no admin row exists it inserts one "
        "(<code>name: 'Admin'</code>, <code>role: 'admin'</code>, PIN "
        "<code>000000</code> bcrypt-hashed, <code>isPinChanged: false</code>). "
        "The migration also seeds a default <code>Regular</code> product "
        "variant path.",
        "<b>Product images</b> — stored as files under the app documents dir "
        "(<code>product_images/</code>); the DB holds the path or a remote URL "
        "in <code>products.image_url</code>.",
    ]),
    h3("Table reference (key columns)"),
    table(["Table", "Purpose / notable columns"], [
        ["<code>users</code>",
         "<code>name, role, pinHash, isActive, employeeId, phone, avatarUrl, "
         "isPinChanged</code>"],
        ["<code>store_info</code>",
         "<code>storeId, storeName, address, taxRate, currency (PHP), "
         "receiptFooter, tin, terminalName</code>"],
        ["<code>payment_methods</code>",
         "<code>label, accountName, accountNumber, sortOrder</code>"],
        ["<code>product_groups</code>", "categories: "
         "<code>name, sortOrder, isActive</code>"],
        ["<code>products</code>",
         "<code>groupId, name, isAvailable, imageUrl, sortOrder</code>"],
        ["<code>product_variants</code>",
         "<code>productId, name, price, isDefault, isActive</code>"],
        ["<code>modifier_groups</code>",
         "<code>name, isRequired, maxSelections, isActive</code>"],
        ["<code>modifier_options</code>",
         "<code>groupId, name, additionalPrice, isActive</code>"],
        ["<code>product_modifier_groups</code>",
         "join table product &harr; modifier group (unique pair)"],
        ["<code>sales</code>",
         "<code>cashierId, total, discount, status, type, createdAt, soNumber, "
         "voidReason, voidedAt</code>"],
        ["<code>sale_items</code>",
         "<code>saleId, productId, variantName, qty, unitPrice, discountType, "
         "discountBeneficiaryId/Name, discountAmount, vatExemptAmount</code>"],
        ["<code>sale_item_modifiers</code>",
         "<code>itemId, modifierName, additionalPrice</code>"],
        ["<code>payments</code>",
         "<code>saleId, method, amount, cashReceived, reference, createdAt</code>"],
        ["<code>refunds</code> / <code>refund_items</code>",
         "refund records (UI currently exposes void, not partial refund)"],
        ["<code>x_readings</code>",
         "per-cashier snapshot: totals, breakdown JSON blobs, VAT, cash"],
        ["<code>z_readings</code>",
         "store close: <code>zCounter</code>, begin/end balance, closedBy / "
         "authorizedBy, salesByCashier JSON"],
        ["<code>daily_reports</code>",
         "per-cashier VAT / cash summary + <code>salesByProductJson</code>, "
         "<code>cashLedgerJson</code>"],
        ["<code>order_events</code>",
         "one row per online order (<code>orderId</code> PK), latest "
         "<code>eventType</code> + <code>payload</code> JSON. Not the local "
         "sales ledger."],
    ]),
]))

# ---------------------------------------------------------------------------
add("Authentication & roles", "".join([
    ul([
        "PINs are 6 digits, hashed with <code>bcrypt</code> in "
        "<code>users.pinHash</code>. No plaintext, no server.",
        "<b>No session persistence.</b> <code>AuthNotifier.build()</code> "
        "returns <code>AuthInitial</code> every launch — the app always "
        "starts at <code>/login</code>.",
        "<code>isPinChanged == false</code> &rarr; "
        "<code>AuthAuthenticated.mustChangePin</code> &rarr; the router forces "
        "<code>/setup-pin</code> and won't release to <code>/dashboard</code> "
        "until a new PIN (&ne; <code>000000</code>) is set and confirmed.",
        "<code>verifyPinForUser(userId, pin)</code> backs the in-place "
        "supervisor authorization for voids and Z-Reading closes (no logout).",
        "<code>isAdminOrSupervisor</code> treats <code>admin</code> and "
        "<code>supervisor</code> alike for most gating.",
    ]),
    h3("Router guard"),
    p("<code>lib/core/navigation/router.dart</code> redirect logic:"),
    ul([
        "Unauthenticated &rarr; <code>/login</code>.",
        "Authenticated + <code>mustChangePin</code> &rarr; <code>/setup-pin</code>.",
        "Cashiers are bounced back to <code>/dashboard</code> from any path "
        "starting with: <code>/inventory</code>, <code>/users</code>, "
        "<code>/settings/csv-import</code>, <code>/settings/backup</code>, "
        "<code>/settings/store-info</code>.",
    ]),
    note("Recovery from total admin lockout: restore a backup, or reinstall "
         "(the seeder recreates the default Admin / <code>000000</code>). "
         "There is no back-door reset."),
]))

# ---------------------------------------------------------------------------
add("Navigation & routes", "".join([
    table(["Route", "Screen", "Notes"], [
        ["<code>/login</code>", "LoginScreen", "initial location"],
        ["<code>/setup-pin</code>", "SetupPinScreen", "forced PIN change"],
        ["<code>/dashboard</code>", "DashboardScreen",
         "owns the live-orders socket"],
        ["<code>/order</code>", "OrderingScreen", ""],
        ["<code>/order/discount</code>", "DiscountScreen", ""],
        ["<code>/order/payment</code>", "PaymentScreen", ""],
        ["<code>/order/receipt/:id</code>", "ReceiptScreen",
         "type = order"],
        ["<code>/transactions</code>", "TransactionsScreen", ""],
        ["<code>/transactions/:id</code>", "ReceiptScreen",
         "type = transaction"],
        ["<code>/orders</code>", "OrdersScreen", "live online orders"],
        ["<code>/cashier-accounting</code>", "CashierAccountingHubScreen", ""],
        ["<code>/cashier-accounting/x-reading[/history[/:id]]</code>",
         "X-Reading + history + reprint", ""],
        ["<code>/cashier-accounting/daily-report[/history[/:id]]</code>",
         "Daily Report + history + reprint", ""],
        ["<code>/cashier-accounting/z-reading[/history[/:id]]</code>",
         "Z-Reading + history + reprint", ""],
        ["<code>/inventory</code>", "InventoryScreen",
         "tabs: Products / Categories / Modifiers"],
        ["<code>/inventory/products/:id/modifiers</code>",
         "ModifierGroupsScreen", ""],
        ["<code>/users</code>", "UsersScreen", "Admin / Supervisor"],
        ["<code>/settings</code>", "SettingsScreen", ""],
        ["<code>/settings/csv-import</code>", "CsvImportScreen", "Admin"],
        ["<code>/settings/backup</code>", "BackupScreen", "Admin"],
        ["<code>/settings/store-info</code>", "StoreInfoScreen", "Admin"],
        ["<code>/settings/printer</code>", "PrinterSetupScreen", "all"],
        ["<code>/settings/csv-export-key</code>", "CsvExportKeyScreen",
         "informational only"],
    ]),
    note("The <code>reports</code> feature (<code>ReportsScreen</code>, "
         "fl_chart sales health) is fully built but the dashboard tile is "
         "commented out (<code>_kTileReports hidden for now</code>) and no "
         "route is registered. Wire a <code>GoRoute</code> + tile to expose "
         "it."),
]))

# ---------------------------------------------------------------------------
add("State management & data flow", "".join([
    p("Flow: <b>View &rarr; Riverpod notifier (state/) &rarr; Repository "
      "&rarr; DAO (local) or API source (<code>lib/data/backend_api/</code>) "
      "&rarr; Dio</b>."),
    ul([
        "Screens are <code>HookConsumerWidget</code>; providers are watched "
        "with <code>ref.watch</code> / read with <code>ref.read</code>.",
        "After a sale, void, or refund, the acting code explicitly "
        "<code>ref.invalidate</code>s <code>transactionsProvider</code>, "
        "<code>xReadingProvider</code>, <code>zReadingProvider</code>, "
        "<code>dailyReportProvider</code> — Drift raw writes are invisible "
        "to Riverpod otherwise.",
        "<code>restoreBackup</code> similarly invalidates "
        "<code>storeInfoProvider</code>, <code>paymentMethodsProvider</code>, "
        "<code>usersProvider</code>, <code>inventoryNotifierProvider</code>, "
        "<code>allModifierGroupsProvider</code>.",
        "The dashboard's first-run flow is a gated chain "
        "(store &rarr; employees &rarr; products); only one prompt shows at a "
        "time.",
    ]),
]))

# ---------------------------------------------------------------------------
add("Live orders architecture", "".join([
    lead("The only online feature. Everything else runs offline."),
    h3("Pieces"),
    table(["Piece", "Detail"], [
        ["Socket",
         "<code>OrdersFeedNotifier</code> connects a WebSocket to "
         "<code>ORDERS_LIVE_FEED_WS_URL</code>, kept alive with "
         "<code>ref.keepAlive</code>. <b>Owned by <code>DashboardScreen</code></b> "
         "— it boots / checks the connection; the Orders screen only "
         "observes it. <code>main.dart</code> listens at the root so toasts "
         "surface on any screen."],
        ["Bearer token",
         "A device token from <code>/devices/token</code> authenticates the "
         "socket. A rejected token &rarr; "
         "<code>deviceTokenStatusProvider</code> &rarr; error toast."],
        ["Events API",
         "Order-status changes (Pending/Preparing/Ready/Fulfilled/Cancelled) "
         "are POSTed to <code>ORDERS_EVENTS_API_BASE_URL</code> with "
         "<code>CLIENT_ID</code> + a token from the "
         "<code>/auth/token</code> exchange (<code>WEBHOOK_SECRET</code>). "
         "A rejected exchange &rarr; <code>webhookAuthStatusProvider</code>."],
        ["Persistence",
         "<code>order_events</code> — one row per order, keyed by "
         "<code>orderId</code>; later events overwrite. "
         "<code>persistedOrdersProvider</code> feeds the Orders list; "
         "<code>ordersCountProvider</code> feeds the dashboard badge."],
        ["Notifications",
         "<code>OrderNotificationsService</code> — Android channel "
         "<code>live_orders</code>, one local notification per event, plus an "
         "in-app <code>SnackBar</code>. Both best-effort; failure never "
         "affects the feed."],
    ]),
    h3("Device registration"),
    p("Saving <b>Store Information</b> triggers "
      "<code>merchantDeviceNotifierProvider</code> to register this device "
      "(store ID + device info from <code>device_info_plus</code> / "
      "<code>package_info_plus</code>) with the merchant service. Outcomes:"),
    ul([
        "<b>pending</b> — waiting for the provider to approve the device; "
        "shown by the status card on the Store Info screen and a one-time "
        "dialog.",
        "<b>approved</b> — the socket can connect.",
        "<b>error</b> — a dialog; it retries the next time Store Info is "
        "saved. <b>Check status</b> on the card re-polls.",
    ]),
    h3("Auth-failure meanings (Orders screen)"),
    table(["Reason", "Blocks the list?"], [
        ["network / serverError / rateLimited / unexpectedResponse / unknown",
         "No — cached list stays, toast only"],
        ["invalidWebhookSecret / invalidClient / unauthorized / invalidRequest",
         "Yes — “Can't load orders” (build config or store ID is "
         "wrong)"],
    ]),
]))

# ---------------------------------------------------------------------------
add("Printing", "".join([
    ul([
        "<b>Receipt layout</b> — built with <code>esc_pos_utils_plus</code> "
        "(ESC/POS). <code>PrintService</code> is the entry point: "
        "<code>printXReading</code>, <code>printZReading</code>, "
        "<code>printDailyReport</code>, receipt printing, "
        "<code>printCalibration</code> / <code>printWidthProbe</code>.",
        "<b>Bluetooth</b> — <code>print_bluetooth_thermal</code> for "
        "connect / print; discovery / pairing via "
        "<code>BluetoothDiscoveryService</code> "
        "(<code>android_intent_plus</code>, <code>permission_handler</code>). "
        "Each print job opens its own connection; the setup screen "
        "disconnects after verifying so later connects don't fail on a held "
        "socket.",
        "<b>Built-in printer</b> — <code>BuiltInPrinter</code> platform "
        "channel; <code>isAvailable()</code> decides whether the "
        "“Print (Built-in)” button shows.",
        "<b>Saved printer</b> — MAC + name in preferences via "
        "<code>PrintService.getSavedMac()</code> / <code>getSavedName()</code>.",
    ]),
    note("Permission ordering matters: on API 31+ "
         "<code>print_bluetooth_thermal</code> hangs forever (never resolves) "
         "if <code>BLUETOOTH_CONNECT</code> isn't granted before the first "
         "call — the setup screen requests permission first, then checks "
         "adapter state."),
]))

# ---------------------------------------------------------------------------
add("Backups", "".join([
    ul([
        "<b>Format</b> — a <code>.zip</code> containing a full dump of every "
        "Drift table plus the <code>product_images/</code> directory. "
        "<code>BackupService.createBackup</code> always writes one; "
        "<code>createBackupIfChanged</code> hashes the dump and skips if "
        "unchanged.",
        "<b>Location</b> — <code>media_store_plus</code> saves into the public "
        "<b>Downloads/POS Backups</b> folder "
        "(<code>MediaStore.appFolder = 'POS Backups'</code>), file "
        "<code>pos_backup_&lt;timestamp&gt;.zip</code>. A manifest "
        "(<code>BackupManifestStore</code>) tracks entries + hashes.",
        "<b>Schedule</b> — <code>schedulePeriodicBackup()</code> registers a "
        "<code>workmanager</code> periodic task "
        "(<code>periodic_pos_backup</code>, ~3h, "
        "<code>ExistingPeriodicWorkPolicy.keep</code>). Dispatcher: "
        "<code>backupCallbackDispatcher</code> "
        "(<code>@pragma('vm:entry-point')</code>).",
        "<b>App-open safety net</b> — <code>_runStartupBackupSafetyNet</code> "
        "in <code>main.dart</code> runs a foreground backup if the last one is "
        "&gt; 3h old (covers Doze / device-off).",
        "<b>Retention</b> — <code>retentionWindow = 7 days</code>; older zips "
        "are deleted from Downloads and the manifest on each write.",
        "<b>Restore</b> — <code>BackupService.restoreBackup(db, zipFile:)</code>: "
        "makes a safety backup of current data, then raw-writes the archive "
        "over SQLite (full replace). Callers must invalidate cached providers "
        "(see State section). <code>BackupArchiveException</code> for a bad "
        "archive.",
    ]),
]))

# ---------------------------------------------------------------------------
add("CSV import & export", "".join([
    h3("Importers"),
    p("<code>lib/core/csv/</code>. All expect a header row; headers are "
      "lower-cased and trimmed."),
    table(["Importer", "Columns"], [
        ["Products (<code>ProductsCsvImporter</code>)",
         "<code>Category, Category Description, Product Name, Product "
         "Description, Product Base Price, Variant Name, Variant Price, "
         "[Product Image URL]</code>. Modes: "
         "<code>upsert</code> (default) or <code>replace</code> — replace "
         "deletes anything absent from the file (items with sales are disabled, "
         "not deleted). Own dialog with a copyable template header + "
         "confirmation."],
        ["Modifiers (<code>ModifiersCsvImporter</code>)",
         "<code>Modifier Group, Modifier Name</code>"],
        ["Users (<code>UsersCsvImporter</code>)",
         "<code>name, role</code> (admin/cashier), <code>pin</code> "
         "(6-digit). Duplicate names are skipped."],
        ["Store Info (<code>StoreInfoCsvImporter</code>)",
         "<code>key, value</code> — keys: <code>store_name, address, "
         "tax_rate, currency, receipt_footer</code>"],
    ]),
    p("Generic importers return an <code>ImportResult</code> "
      "(<code>successCount</code>, <code>skippedCount</code>, per-row "
      "<code>errors</code>) rendered as an in-card banner + expandable error "
      "list."),
    h3("Report export"),
    ul([
        "<code>reportCsvExporterProvider</code> — "
        "<code>exportTransactions(from, to)</code> writes to Downloads; "
        "<code>writeTransactionsTempFile</code> feeds the email path.",
        "<code>ReportEmailSender</code> (<code>mailer</code>) sends via "
        "<code>SENDER_EMAIL</code> / <code>SENDER_APP_PASSWORD</code>. "
        "Recipients are persisted (<code>ReportEmailRecipients</code>). "
        "<code>ReportEmailException</code> for SMTP failures.",
        "<code>CSV_EXPORT_PASSWORD</code>, when set, gates every export "
        "(prompt before download / email). The "
        "<code>CsvExportKeyScreen</code> is purely informational — the "
        "value is only editable in <code>.env</code>.",
    ]),
]))

# ---------------------------------------------------------------------------
add("Android configuration", "".join([
    table(["Setting", "Value / source"], [
        ["applicationId", "<code>com.dpo.mobile</code>"],
        ["minSdk / targetSdk / compileSdk",
         "<code>flutter.*</code> (Flutter defaults); launcher-icon "
         "<code>min_sdk_android: 21</code>"],
        ["label", "<code>POS Mobile</code>"],
        ["launchMode", "<code>singleTop</code>, "
         "<code>windowSoftInputMode=adjustResize</code>"],
        ["launcher icons", "<code>flutter_launcher_icons</code> from "
         "<code>assets/icon/app_icon.png</code>"],
        ["<code>requestLegacyExternalStorage</code>", "<code>true</code> "
         "(backup file writes on older Android)"],
    ]),
    h4("Declared permissions (main manifest)"),
    ul([
        "<code>BLUETOOTH</code>, <code>BLUETOOTH_ADMIN</code>, "
        "<code>ACCESS_FINE_LOCATION</code> — all "
        "<code>maxSdkVersion=\"30\"</code> (legacy pre-Android 12 pairing)",
        "<code>BLUETOOTH_SCAN</code> "
        "(<code>neverForLocation</code>), <code>BLUETOOTH_CONNECT</code> — "
        "API 31+",
        "<code>POST_NOTIFICATIONS</code> — live-order notifications "
        "(Android 13+ also needs runtime consent, requested at startup)",
    ]),
    note("<b>INTERNET is only declared in the debug and profile manifests</b> "
         "(<code>android/app/src/{debug,profile}/AndroidManifest.xml</code>), "
         "<u>not</u> in <code>src/main/AndroidManifest.xml</code>. Flutter "
         "injects it for debug builds, so live orders work in debug but a "
         "<b>release</b> build may have no network access. If live orders / "
         "device registration fail only in release, add "
         "<code>&lt;uses-permission "
         "android:name=\"android.permission.INTERNET\"/&gt;</code> to the main "
         "manifest.", "warn"),
]))

# ---------------------------------------------------------------------------
add("Building a release", "".join([
    pre(
        "cd mobile\n"
        "# 1. ensure .env is the PRODUCTION file (secrets, prod URLs)\n"
        "flutter pub get\n"
        "dart run build_runner build --delete-conflicting-outputs\n"
        "\n"
        "# 2a. APK (sideload / MDM push)\n"
        "flutter build apk --release\n"
        "#    -> build/app/outputs/flutter-apk/app-release.apk\n"
        "\n"
        "# 2b. App Bundle (Play / managed Play)\n"
        "flutter build appbundle --release\n"
    ),
    ul([
        "Version comes from <code>pubspec.yaml</code> "
        "(<code>version: 1.2.0+3</code> &rarr; versionName 1.2.0, versionCode "
        "3). Bump before each release.",
        "Configure release signing in "
        "<code>android/app/build.gradle(.kts)</code> + a keystore / "
        "<code>key.properties</code> (not committed).",
        "Verify the INTERNET permission note above before shipping a "
        "networked build.",
        "The <code>.env</code> used at build time is <b>baked into the "
        "binary</b> — build prod artifacts from a machine with the prod "
        "<code>.env</code>, and never commit it.",
    ]),
    h4("Windows"),
    p("<code>flutter build windows</code> compiles, but the app is "
      "Android-first: <code>media_store_plus</code> (backups to Downloads), "
      "<code>print_bluetooth_thermal</code>, <code>workmanager</code> and "
      "<code>flutter_local_notifications</code> are Android-oriented. Treat "
      "Windows as unsupported for production unless each of those is "
      "validated.")
]))

# ---------------------------------------------------------------------------
add("Troubleshooting", "".join([
    table(["Symptom", "Cause / fix"], [
        ["<code>build_runner</code> fails / stale generated code",
         "<code>dart run build_runner build --delete-conflicting-outputs</code>; "
         "if still stuck, <code>flutter clean &amp;&amp; flutter pub get</code> "
         "first."],
        ["Codegen error mentioning <code>.env</code>",
         "<code>.env</code> is missing or missing a key that "
         "<code>Env</code> declares. Copy from <code>.env.sample</code>."],
        ["Bluetooth scan hangs forever (no error)",
         "<code>BLUETOOTH_CONNECT</code> not granted before the first plugin "
         "call. Grant it; the setup screen already requests permission first "
         "— check it wasn't permanently denied."],
        ["Live orders never connect in a release build",
         "Missing INTERNET permission in the main manifest (see Android "
         "Configuration)."],
        ["Orders screen: “Can't load orders”",
         "<code>invalidWebhookSecret</code> / <code>invalidClient</code> / "
         "<code>unauthorized</code> / <code>invalidRequest</code> — wrong "
         "<code>.env</code> values or a store ID the service rejects. Check "
         "the device-registration card in Store Info."],
        ["Backups not appearing in Downloads",
         "<code>media_store_plus</code> needs storage access on the Android "
         "version in use; check <code>MediaStore.ensureInitialized()</code> "
         "ran (it's in <code>main()</code>). WorkManager jobs can be delayed "
         "by Doze — the app-open safety net covers this."],
        ["Report emails not sending",
         "<code>SENDER_APP_PASSWORD</code> must be a Gmail <b>App "
         "Password</b> with 2-Step Verification on "
         "<code>SENDER_EMAIL</code>. <code>ReportEmailException</code> carries "
         "the SMTP message."],
        ["Totals wrong after a manual DB edit / restore",
         "Riverpod caches. Invalidate the relevant providers (see State "
         "section) or restart the app."],
        ["Admin locked out",
         "Restore a backup, or reinstall (seeder recreates Admin / "
         "<code>000000</code>)."],
    ]),
]))

# ---------------------------------------------------------------------------
add("Notes & constraints", "".join([
    ul([
        "<b>Single-tenant, single-device.</b> Each install is its own store "
        "with its own database. No cross-device sync — data moves only via "
        "backup / restore.",
        "<b>No user session persistence</b> by design — every launch "
        "requires sign-in.",
        "<b>Currency</b> is effectively fixed to <code>PHP</code> "
        "(<code>store_info.currency</code> default); VAT / Senior-PWD logic is "
        "Philippines-shaped (12% VAT, statutory Senior/PWD discount &amp; VAT "
        "exemption).",
        "<b>Refunds</b>: schema (<code>refunds</code>, "
        "<code>refund_items</code>) and a <code>RefundScreen</code> exist, but "
        "the receipt UI currently exposes <b>Void</b> only.",
        "<b>Reports feature</b> is dormant — build it into the router / "
        "dashboard to use it.",
        "<b>Secrets in the binary</b>: obfuscated <code>envied</code> fields "
        "are XOR-masked, not secure. Anyone with the APK can recover them. "
        "Scope the webhook secret / Gmail app password accordingly and rotate "
        "on staff turnover.",
        "Keep the <code>path_provider_android</code> override until a newer "
        "version is verified.",
    ]),
]))
