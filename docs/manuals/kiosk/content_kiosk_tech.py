# -*- coding: utf-8 -*-
from manual_helpers import p, lead, h3, h4, steps, ol, ul, note, table, pre

SECTIONS = []
def S(title, *body): SECTIONS.append((title, "".join(body)))

S("Overview & architecture",
  lead("The kiosk is a Flutter desktop application targeting Windows (Android is also buildable). "
       "It is a thin client: all business logic and persistence live in the NestJS backend."),
  h3("1.1 Stack"),
  table(["Concern", "Choice"], [
      ["UI toolkit", "Flutter (Dart <code>^3.7.2</code>), pinned via FVM (<code>.fvmrc</code>)"],
      ["State management", "Hooks Riverpod (<code>hooks_riverpod</code> + <code>flutter_hooks</code>)"],
      ["Navigation", "GoRouter with typed routes (<code>go_router_builder</code> codegen)"],
      ["Serialization", "<code>dart_mappable</code> (<code>*.mapper.dart</code>)"],
      ["HTTP", "Dio, with an auth interceptor"],
      ["Config", "<code>envied</code> (compile-time env, <code>env.g.dart</code>)"],
      ["Windows integration", "<code>window_manager</code>, <code>win32</code>, <code>screen_retriever</code>, <code>desktop_multi_window</code>"],
      ["Printing", "<code>esc_pos_utils_plus</code> (ESC/POS receipts)"],
      ["Assets", "<code>flutter_gen</code> (<code>lib/gen/assets.gen.dart</code>)"],
  ]),
  h3("1.2 Data flow"),
  pre("View (HookConsumerWidget)\n"
      "  -> Riverpod provider (state/)\n"
      "    -> Repository (repositories/)\n"
      "      -> API source (lib/data/backend_api/sources/)\n"
      "        -> Dio client (api_clients.dart, auth interceptor)\n"
      "          -> Backend  http://<host>:3000/api/v1"),
  h3("1.3 Feature module layout"),
  pre("lib/features/<feature>/\n"
      "  entities/       immutable domain models + .mapper.dart\n"
      "  repositories/   abstract interface + Impl calling the API layer\n"
      "  state/          Riverpod AsyncNotifier / StateNotifier providers\n"
      "  use_cases/      (optional) single-responsibility operations\n"
      "  view/           screens & dialogs (HookConsumerWidget)"),
  h3("1.4 HTTP layer"),
  pre("lib/data/backend_api/\n"
      "  sources/        one class per backend resource (ProductsApi, ...)\n"
      "  schemas/        @MappableClass DTOs mirroring backend DTOs\n"
      "  mappers/        custom dart_mappable type mappers\n"
      "                  (ImageUrlMapper, DateTimeWithOffsetMapper, ...)\n"
      "  api_clients.dart  Dio provider wired with the auth interceptor"),
  note("Clean-architecture rule: <code>lib/data/</code> must never import <code>lib/features/</code>. "
       "Error translation (DioException &rarr; ApiException) belongs in the data layer."))

S("Prerequisites",
  table(["Tool", "Version", "Notes"], [
      ["Flutter SDK", "3.x (stable), pinned by FVM", "<code>dart pub global activate fvm</code> then <code>fvm use stable</code>"],
      ["Dart SDK", "<code>^3.7.2</code>", "Bundled with Flutter"],
      ["Node.js", "18+", "Only needed if you also build the backend / installer"],
      ["Visual Studio (Desktop C++)", "2022", "Required by <code>flutter build windows</code>"],
      ["A running backend", "\u2014", "The app checks <code>/api/v1/health/live</code> on start-up"],
  ]),
  p("Confirm the toolchain with <code>fvm flutter doctor</code>."))

S("Environment configuration",
  p("Copy <code>kiosk/.env.sample</code> to <code>kiosk/.env</code> and fill every value. Variables are read at "
    "<b>compile time</b> by <code>envied</code>, so you must re-run code generation after changing them."),
  table(["Variable", "Purpose"], [
      ["<code>BACKEND_API_BASE_URL</code>", "Base URL of the NestJS API, including <code>/api/v1</code> (e.g. <code>http://localhost:3000/api/v1</code>)."],
      ["<code>SECURE_STORAGE_KEY</code>", "Key used to encrypt tokens in secure local storage."],
      ["<code>ORDERS_LIVE_FEED_WS_URL</code>", "WebSocket URL for the live channel-orders feed (Orders board)."],
      ["<code>CARTIVO_AUTH_API_BASE_URL</code>", "Base URL for the external ordering-platform auth service."],
      ["<code>ORDERS_EVENTS_API_BASE_URL</code>", "Base URL for the channel-order events / history API."],
      ["<code>CLIENT_ID</code>", "Client identifier for the external orders integration."],
      ["<code>WEBHOOK_SECRET</code>", "Shared secret used to verify inbound order webhooks."],
  ]),
  note("Every new variable must also be declared as an <code>@EnviedField()</code> on the <code>Env</code> class in "
       "<code>lib/config/environment/</code>, or the build will not see it."))

S("Install, generate, run",
  h3("4.1 First-time setup"),
  pre("cd kiosk\n"
      "dart pub global activate fvm            # once per machine\n"
      "fvm use stable                          # install the pinned Flutter\n"
      "cp .env.sample .env                     # then edit .env\n"
      "fvm flutter pub get\n"
      "fvm dart run build_runner build --delete-conflicting-outputs"),
  h3("4.2 Run"),
  pre("fvm flutter run -d windows              # desktop\n"
      "fvm flutter run -d android              # android (optional)"),
  p("In dev mode <code>main.dart</code> sizes the window to <b>1536&times;864</b>; in a release build it goes full-screen."),
  h3("4.3 Analyze"),
  pre("fvm dart analyze"),
  note("For <b>mobile-only</b> work in the sibling <code>mobile/</code> and <code>mobile_merchant/</code> apps, verify with "
       "<code>dart analyze</code> and do not run or modify <code>be/</code> or <code>kiosk/</code>."))

S("Code generation",
  p("Four generators run through <code>build_runner</code>. Re-run it after touching any annotated file. "
    "Never hand-edit generated output."),
  table(["Generator", "Produces", "From"], [
      ["<code>dart_mappable</code>", "<code>*.mapper.dart</code>", "<code>@MappableClass</code> types (entities, API schemas)"],
      ["<code>envied_generator</code>", "<code>env.g.dart</code>", "The <code>Env</code> class + <code>.env</code>"],
      ["<code>go_router_builder</code>", "<code>router.g.dart</code>", "<code>@TypedGoRoute</code> route classes"],
      ["<code>flutter_gen</code>", "<code>lib/gen/assets.gen.dart</code>", "<code>pubspec.yaml</code> assets"],
  ]),
  pre("fvm dart run build_runner build --delete-conflicting-outputs\n"
      "# or, while iterating:\n"
      "fvm dart run build_runner watch  --delete-conflicting-outputs"))

S("Navigation & routes",
  p("Routes are defined as typed <code>GoRouteData</code> classes under <code>lib/navigation/</code> and assembled in "
    "<code>router.dart</code>. Initial location is <code>StartupRoute</code>."),
  table(["Route", "Path", "Screen"], [
      ["StartupRoute", "<code>/</code>", "Backend health poll, then redirects to Login"],
      ["OnboardingRoute", "<code>/onboarding</code>", "Welcome / Touch To Start"],
      ["LoginRoute", "<code>/login</code>", "Roster + PIN pad"],
      ["SetupPinRoute", "<code>/setup-pin</code>", "Forced PIN change"],
      ["MenuRoute", "<code>/menu</code>", "Main menu grid (role-filtered)"],
      ["OrderingRoute", "<code>/ordering</code>", "New Order (product grid + order panel)"],
      ["CartRoute / DiscountRoute / PaymentRoute / ReceiptRoute", "<code>/cart</code> &hellip;", "Checkout flow"],
      ["OrdersRoute", "<code>/orders</code>", "Channel-orders kanban board"],
      ["TransactionsRoute", "<code>/transactions</code>", "Sales history + report launchers"],
      ["RefundRoute", "<code>/refund</code>", "Process Refund"],
      ["ProductsRoute (Inventory)", "<code>/inventory</code>", "Inventory Management (Products / Categories)"],
      ["UserManagementRoute", "<code>/user-management</code>", "Employee accounts"],
      ["DeviceTransferRoute", "<code>/device-transfer</code>", "Backup &amp; Transfer hub"],
      ["CashierReportRoute / CashierDailyReportRoute / ZReadingRoute / CashierReportsRoute", "<code>/cashier-report</code>, <code>/z-reading</code>, &hellip;", "X-Reading, Cashier Daily Report, Z-Reading, history (with <code>/history/:id</code> detail variants)"],
  ]),
  note("A <code>WindowsTouchKeyboardObserver</code> is registered as a navigator observer to manage the on-screen keyboard."))

S("Feature \u2192 backend endpoint map",
  p("Which API each screen talks to (all under <code>/api/v1</code>). Keep DTO schemas in "
    "<code>lib/data/backend_api/schemas/</code> in sync with the backend."),
  table(["Feature / screen", "Primary endpoints"], [
      ["Start-up", "<code>GET /health/live</code>"],
      ["Login roster / PIN", "<code>GET /users/roster</code>, <code>POST /auth/login/pin</code>, <code>POST /auth/refresh</code>, <code>GET /auth/me</code>"],
      ["PIN change", "<code>PATCH /users/:id</code>, <code>POST /users/verify-pin</code>"],
      ["Main menu / terminal gate", "<code>GET /pos-terminals/my-terminal</code>"],
      ["New Order (products)", "<code>GET /catalog/products</code>, <code>GET /catalog/categories</code>, <code>GET /products/:id</code>, <code>GET /product-variants/by-product/:id</code>, <code>GET /catalog/modifier-groups</code>"],
      ["Checkout / sale", "<code>POST /sales-orders</code>, <code>PATCH /sales-orders/:id/item/:itemId</code>, <code>PATCH /sales-orders/:id/discount</code>, <code>PATCH /sales-orders/:id/confirm</code>, <code>POST /payments</code>"],
      ["Transactions", "<code>GET /sales-orders</code>, <code>GET /sales-orders/:id/with-items</code>"],
      ["Void / Refund", "<code>PATCH /sales-orders/:id/void</code>, <code>POST /refunds</code>, <code>POST /users/verify-pin</code>"],
      ["Orders board", "WS <code>ORDERS_LIVE_FEED_WS_URL</code>, <code>ORDERS_EVENTS_API_BASE_URL</code>, <code>CARTIVO_AUTH_API_BASE_URL</code>"],
      ["Inventory Management", "<code>GET/POST/PATCH /products</code>, <code>POST /products/import-csv</code>, <code>catalog/admin</code> category endpoints, <code>/product-variants</code>, <code>/modifier-groups</code>"],
      ["User management", "<code>GET/POST /users</code>, <code>PATCH/DELETE /users/:id</code>, <code>GET /users/authorizers</code>"],
      ["Settings / terminal", "<code>GET/PATCH /pos-terminals/my-terminal</code>, <code>POST /pos-terminals/register</code>, <code>.../my-terminal/payment-methods</code>"],
      ["X / Daily / Z readings", "<code>reports/cashier-x-reading*</code>, <code>reports/cashier-daily-report*</code>, <code>reports/z-reading*</code>"],
      ["Backup &amp; Transfer", "<code>POST /device-transfer/export</code>, <code>POST /device-transfer/import</code>"],
  ]))

S("Windows specifics",
  h3("8.1 Fullscreen & DPI"),
  ul(["<code>main.dart</code> initialises <code>window_manager</code>; production builds go borderless full-screen, dev builds use 1536&times;864.",
      "<code>win32</code> is used for high-DPI awareness."]),
  h3("8.2 Customer display second window"),
  p("<code>main.dart</code> checks the window argument: the normal engine runs the cashier app, a second engine "
    "(<code>desktop_multi_window</code>) runs the customer display. <code>screen_retriever</code> finds the non-primary "
    "monitor (falling back to visible-position comparison when a display reports an empty id) and positions "
    "the window there without stealing focus. <code>CustomerDisplayHost</code> in the cashier engine pushes "
    "debounced snapshots to it."),
  h3("8.3 On-screen keyboard"),
  p("Text fields use <code>KeyboardSuppress</code> helpers plus a <code>PhysicalKeyboardDetector</code> so that a hardware "
    "keyboard, when attached, disables the touch keyboard automatically."),
  h3("8.4 Printing"),
  p("Receipts and X/Z/daily reports are encoded to ESC/POS byte streams (<code>encode_esc_pos_*</code> use cases) "
    "and also rendered to PDF (<code>render_*_pdf</code>) for preview / archive."))

S("Building a release & packaging",
  h3("9.1 Standalone Windows build"),
  pre("cd kiosk\n"
      "fvm flutter build windows --release\n"
      "# output: kiosk\\build\\windows\\x64\\runner\\Release\\\n"
      "#   pos_app.exe, *.dll, data\\"),
  h3("9.2 As part of the one-click installer"),
  p("From the repo root, <code>build-installer.bat</code> runs Flutter codegen, then builds the Flutter app and the "
    "backend SEA in parallel, then compiles the Inno Setup installer. See the <i>Backend \u2014 Technical Manual</i> "
    "for the full installer walkthrough."),
  table(["Installed component", "Location", "Runs as"], [
      ["Flutter app (<code>pos_app.exe</code>)", "<code>C:\\POSKiosk\\</code>", "Desktop app / autostart"],
      ["Backend SEA (<code>POSBackend.exe</code>)", "<code>C:\\POSKiosk\\backend\\</code>", "Service <code>POSBackendService</code> (NSSM)"],
      ["PostgreSQL 16", "<code>C:\\POSKiosk\\pgsql\\</code>", "Service <code>POSPostgres</code>"],
  ]),
  note("Runtime kiosk identity on an installed machine comes from <code>C:\\POSKiosk\\settings.txt</code> "
       "(<code>kiosk.no=&lt;n&gt;</code>), written by the installer wizard \u2014 not from <code>.env</code>."))

S("Troubleshooting",
  table(["Symptom", "Cause / fix"], [
      ["App stays on start-up screen",
       "Health poll to <code>/health/live</code> failing. Check <code>POSBackendService</code> and <code>POSPostgres</code> are Running; check <code>BACKEND_API_BASE_URL</code>. On an installed machine run <code>C:\\POSKiosk\\scripts\\recover-services.bat</code> as admin."],
      ["<code>build_runner</code> errors after a pull",
       "Run with <code>--delete-conflicting-outputs</code>; if still broken, <code>fvm flutter clean &amp;&amp; fvm flutter pub get</code> then regenerate."],
      ["Env value not picked up",
       "It was added to <code>.env</code> but not to the <code>Env</code> class, or codegen wasn't re-run."],
      ["Blank product grid vs. real error",
       "The grid distinguishes empty-category from load failure; a failure shows &ldquo;Could not load products&rdquo; with Retry \u2014 inspect the Dio error / token."],
      ["Customer display on wrong monitor",
       "Empty display ids on some hardware; fix the Windows primary display or cabling and restart."],
      ["&ldquo;Internal server error&rdquo; creating a sale",
       "Backend can't resolve the kiosk number \u2014 verify <code>settings.txt</code> and restart the backend service."],
  ]),
  h4("Log locations (installed machine)"),
  table(["Log", "Contents"], [
      ["<code>C:\\POSKiosk\\logs\\backend-output.log</code> / <code>backend-error.log</code>", "Live NestJS stdout / stderr"],
      ["<code>C:\\POSKiosk\\logs\\setup-postgres-install.log</code>", "DB init, service registration, migrations"],
      ["<code>C:\\posdata\\log\\postgresql.log</code>", "PostgreSQL server log"],
      ["<code>customer-display-receiver.log</code>", "Customer-display sub-window diagnostics"],
  ]))
