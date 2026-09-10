# -*- coding: utf-8 -*-
"""Technical-manual content for Cartivo Merchant (mobile_merchant/)."""

from manual_helpers import p, lead, h3, h4, ul, ol, steps, note, table, pre

SECTIONS = []


def add(title, body):
    SECTIONS.append((title, body))


# ---------------------------------------------------------------------------
add("Overview & tech stack", "".join([
    lead("Cartivo Merchant is a single-screen Flutter Android app that "
         "authenticates a device against the Cartivo / DPO backend, opens a "
         "WebSocket to the merchant's live order-event stream, and lets an "
         "operator patch order status back over REST. There is no user auth, "
         "no catalogue, and no reporting — it is a thin real-time client."),
    table(["Concern", "Choice"], [
        ["Language / SDK", "Dart <code>^3.11.5</code>, Flutter (stable)"],
        ["State management", "<code>flutter_riverpod</code> 3.x + "
         "<code>riverpod_annotation</code> / <code>riverpod_generator</code>"],
        ["DI", "<code>get_it</code> 8 + <code>injectable</code> 2 "
         "(<code>configureDependencies()</code> in <code>bootstrap.dart</code>)"],
        ["HTTP", "<code>dio</code> 5, one instance owned by <code>ApiClient</code>"],
        ["Realtime", "<code>web_socket_channel</code> 3 "
         "(<code>IOWebSocketChannel</code>)"],
        ["Routing", "<code>go_router</code> 16 via "
         "<code>go_router_builder</code>-style codegen (<code>appRouterProvider</code>)"],
        ["Local DB", "<code>drift</code> 2.28 + "
         "<code>sqlite3_flutter_libs</code>"],
        ["Secure storage", "<code>flutter_secure_storage</code> 9"],
        ["Models", "<code>freezed</code> 3 + <code>json_serializable</code> 6 "
         "(DTOs); some hand-written DTOs where leniency is needed"],
        ["Notifications", "<code>flutter_local_notifications</code> 22"],
        ["Device fingerprint", "<code>device_info_plus</code> 11, "
         "<code>package_info_plus</code> 8"],
        ["Env", "<code>flutter_dotenv</code> 5 — <code>.env</code> is a "
         "bundled asset"],
        ["Result type", "<code>Either&lt;Failure, T&gt;</code> "
         "(<code>dartz</code>) at the repository boundary"],
    ]),
    note("<code>custom_lint</code> / <code>riverpod_lint</code> are "
         "intentionally omitted (incompatible plugin entrypoints on this "
         "analyzer). Re-add them together with the <code>custom_lint</code> "
         "line in <code>analysis_options.yaml</code> once a compatible pair "
         "ships.", "note"),
]))

# ---------------------------------------------------------------------------
add("Repository layout", "".join([
    pre(
        "mobile_merchant/\n"
        "|- lib/\n"
        "|  |- main.dart               # entry -> bootstrap()\n"
        "|  |- bootstrap.dart          # dotenv.load -> DI -> SettingsService.init -> notifications -> runApp\n"
        "|  |- app.dart                # MaterialApp.router, SessionExpiredListener shell\n"
        "|  |- core/\n"
        "|  |  |- config/              env_config.dart, app_config.dart\n"
        "|  |  |- di/                  injection.dart (+ injection.config.dart)\n"
        "|  |  |- network/             api_client.dart, api_endpoints.dart, interceptors/\n"
        "|  |  |- auth/                session_expired_notifier.dart, session_manager.dart\n"
        "|  |  |- router/              app_router.dart, app_routes.dart, route_guards.dart (stub)\n"
        "|  |  |- database/            app_database.dart, tables/, daos/\n"
        "|  |  |- storage/             secure_storage.dart, merchant_device_storage.dart\n"
        "|  |  |- services/            settings_service.dart, services/notifications/\n"
        "|  |  |- notifications/       order_toast.dart\n"
        "|  |  |- providers/          connectivity_provider.dart\n"
        "|  |  |- theme/ utils/ widgets/ error/\n"
        "|  |- shared/                 app_scaffold, app_button, app_snackbar, ...\n"
        "|  |- features/\n"
        "|  |  |- dashboard/           the only screen; toolbar + orders body\n"
        "|  |  |- merchant/            merchant profile + device registration / approval\n"
        "|  |  |- orders/              live feed, orders list state, order cards, DTOs\n"
        "|- android/                   the only platform folder (no ios/ windows/ macos/ linux/)\n"
        "|- assets/                    app icon\n"
        "|- .env / .env.sample\n"
        "|- test/\n"
    ),
    h3("Feature-module convention"),
    p("Feature-first clean architecture. Each feature is a vertical slice "
      "with <code>data/</code> (datasources, models, repositories impl), "
      "<code>domain/</code> (pure Dart entities, repository interfaces, use "
      "cases), and <code>presentation/</code> (Riverpod providers, screens, "
      "widgets). <code>domain/</code> imports no Flutter or infra. Riverpod "
      "notifiers resolve dependencies with <code>getIt&lt;T&gt;()</code> "
      "at call time, never via constructor injection. Full rules in "
      "<code>lib/features/README.md</code>."),
    note("Only <code>merchant</code> and <code>orders</code> are fully "
         "built out. <code>auth</code> does not exist yet — "
         "<code>core/router/route_guards.dart</code>, "
         "<code>session_manager.dart</code> and "
         "<code>SessionExpiredListener</code> are stubs wired to activate "
         "once it does. The router has exactly one route: "
         "<code>'/'</code> -> <code>DashboardScreen</code>.", "note"),
]))

# ---------------------------------------------------------------------------
add("Environment (.env) reference", "".join([
    lead("<code>.env</code> is loaded by <code>dotenv.load()</code> at the top "
         "of <code>bootstrap()</code> and is declared as an asset in "
         "<code>pubspec.yaml</code>. All reads go through "
         "<code>EnvConfig</code>; nothing else touches <code>dotenv</code> "
         "directly. Every getter has a safe fallback so widget tests run "
         "without a file."),
    table(["Key", "Used for", "Fallback"], [
        ["<code>API_BASE_URL</code>", "Base URL for every REST call. The "
         "WebSocket URL is <i>derived</i> from it (see below). May or may not "
         "include a path suffix like <code>/api/v1</code> depending on the "
         "target backend.", "<code>http://10.0.2.2:3000/api/v1</code>"],
        ["<code>APP_NAME</code>", "<code>MaterialApp.title</code>", "<code>DPO Merchant</code>"],
        ["<code>ENABLE_LOGGING</code>", "Verbose HTTP + app logging "
         "(<code>\"true\"</code> / <code>\"false\"</code>)", "<code>false</code>"],
        ["<code>SETTINGS_PASSWORD</code>", "Password gating the (not yet "
         "surfaced) custom-endpoint settings dialog", "<code>\"\"</code>"],
        ["<code>WEBHOOK_SECRET</code>", "Sent as <code>webhook_secret</code> "
         "in the <code>POST /auth/token</code> body — the shared secret "
         "that identifies your integration", "<code>\"\"</code>"],
        ["<code>CLIENT_ID</code>", "Read by <code>EnvConfig.clientId</code>; "
         "reserved for the auth handshake", "<code>\"\"</code>"],
        ["<code>CSV_EXPORT_PASSWORD</code>", "Present in some <code>.env</code> "
         "files for parity with <code>mobile/</code>; unused by this app", "n/a"],
    ]),
    h3("WebSocket URL derivation"),
    p("<code>EnvConfig.wsBaseUrl</code> parses <code>API_BASE_URL</code>, "
      "swaps the scheme (<code>http-&gt;ws</code>, <code>https-&gt;wss</code>), "
      "keeps the host, drops the path, and drops the port only when it is the "
      "scheme default. <code>OrdersLiveFeedRepository</code> then appends "
      "<code>/ws</code> and a <code>?merchant_id=</code> query param."),
    pre(
        "API_BASE_URL=https://api.example.com/api/v1\n"
        "  -> REST : https://api.example.com/api/v1/...\n"
        "  -> WS   : wss://api.example.com/ws?merchant_id=ABC123\n\n"
        "API_BASE_URL=http://192.168.1.34:4000\n"
        "  -> REST : http://192.168.1.34:4000/...\n"
        "  -> WS   : ws://192.168.1.34:4000/ws?merchant_id=ABC123\n"
    ),
    note("New keys must be added as typed getters on <code>EnvConfig</code> "
         "with a fallback — never read <code>dotenv</code> elsewhere.", "warn"),
]))

# ---------------------------------------------------------------------------
add("Local development & code generation", "".join([
    h3("First run"),
    pre(
        "cd mobile_merchant\n"
        "cp .env.sample .env            # then fill in values\n"
        "flutter pub get\n"
        "dart run build_runner build --delete-conflicting-outputs\n"
        "flutter run                    # a connected Android device / emulator\n"
    ),
    h3("Codegen"),
    p("Re-run <code>build_runner</code> after touching any "
      "<code>@freezed</code>, <code>@riverpod</code>, <code>@injectable</code>, "
      "<code>@JsonSerializable</code>, or Drift-annotated file. During active "
      "work:"),
    pre("dart run build_runner watch --delete-conflicting-outputs\n"),
    p("Generated files (<code>*.freezed.dart</code>, <code>*.g.dart</code>, "
      "<code>injection.config.dart</code>, <code>app_database.g.dart</code>, "
      "<code>app_router.g.dart</code>) are committed and must never be edited "
      "by hand."),
    h3("Checks"),
    pre(
        "dart analyze                   # static analysis (flutter_lints 6)\n"
        "flutter test                  # unit tests under test/\n"
    ),
    note("Per the project convention for <code>mobile_merchant/</code>, keep "
         "changes inside this folder and verify with <code>dart analyze</code> "
         "— do not build or run <code>be/</code> or <code>kiosk/</code> to "
         "test a change here.", "note"),
    h3("Emulator networking"),
    p("From the Android emulator, the host machine is "
      "<code>10.0.2.2</code> (the default fallback). A physical device needs "
      "the host's LAN IP in <code>API_BASE_URL</code> and the backend bound "
      "to <code>0.0.0.0</code>."),
]))

# ---------------------------------------------------------------------------
add("The device authentication chain", "".join([
    lead("Every launch runs a three-call chain before the socket can open. "
         "<code>deviceStartupProvider</code> (a <code>FutureProvider</code>) "
         "runs it once per launch and memoizes the result; "
         "<code>MerchantNotifier.recheckDeviceStatus()</code> refreshes it on "
         "demand. All three calls are on <code>MerchantApi</code>."),
    h3("1 — POST /auth/token"),
    table(["", ""], [
        ["Body", "<code>{ webhook_secret, merchant_id }</code> "
         "(<code>webhook_secret</code> from <code>EnvConfig.webhookSecret</code>)"],
        ["Accepts", "<code>200</code>"],
        ["Returns", "<code>{ merchant_id, merchant_name, token, exp }</code> "
         "— a short-lived webhook JWT scoped to that one merchant"],
        ["Stored", "<code>MerchantDeviceStorage.writeToken(token, exp, "
         "merchantId)</code> — token, expiry, and the merchant it is "
         "scoped to"],
    ]),
    p("<code>ensureWebhookToken(merchantId)</code> re-mints when the stored "
      "token is missing, within 1 minute of expiry, or "
      "<code>tokenMerchantId != merchantId</code> (left over from a previous "
      "merchant). This guard is the single source of truth for token "
      "freshness — callers must never use <code>storage.token</code> "
      "directly."),
    h3("2 — POST /devices/register"),
    table(["", ""], [
        ["Headers", "<code>Authorization: Bearer &lt;webhook JWT&gt;</code>, "
         "<code>Idempotency-Key: &lt;install_id&gt;</code>"],
        ["Body", "<code>RegisterDeviceRequest</code>: <code>platform</code>, "
         "<code>install_id</code>, <code>name</code>, <code>app_version</code>, "
         "<code>platform_version</code>, <code>device_model</code>, "
         "<code>platform_details</code> (android_id, manufacturer, brand, "
         "device, sdk_int, is_physical_device)"],
        ["Accepts", "<code>200</code> (idempotent replay) or <code>202</code> "
         "(fresh enrolment)"],
        ["Returns", "<code>{ device_id, status, device_secret?, merchant_id?, "
         "merchant_name?, requested_at?, reviewed_at?, review_note? }</code>"],
        ["<code>device_secret</code>", "returned <b>only on 202</b>, once. "
         "Persisted then; never overwritten with null on a later 200."],
    ]),
    p("<code>install_id</code> is a v4 UUID generated once "
      "(<code>ensureInstallId()</code>) and <b>never cleared</b>, even on a "
      "merchant switch — it identifies the install, not the merchant link. "
      "<code>status</code> is one of <code>pending</code> / "
      "<code>approved</code> / <code>deactivated</code> (<code>rejected</code> "
      "is bucketed as <code>deactivated</code>; anything else is "
      "<code>unknown</code>). It is cached in secure storage "
      "(<code>merchant_device_status</code>) as an optimistic gate read on the "
      "next cold start."),
    h3("3 — POST /devices/token"),
    table(["", ""], [
        ["Headers", "<code>Authorization: Bearer &lt;webhook JWT&gt;</code>"],
        ["Body", "<code>{ device_id, device_secret }</code>"],
        ["Accepts", "<code>200</code>"],
        ["Returns", "<code>{ device_id, merchant_id, token, exp }</code> "
         "— a short-lived JWT used as the WS handshake bearer"],
        ["Caching", "<b>Not cached across launches.</b> "
         "<code>DeviceTokenRepository.mint()</code> is called on every connect "
         "attempt. The value is still written to storage "
         "(<code>merchant_device_ws_token*</code>) so "
         "<code>invalidate()</code> can clear it on a 401/403 handshake "
         "rejection."],
    ]),
    h3("Approval polling"),
    ul([
        "<code>DashboardScreen</code> polls "
        "<code>recheckDeviceStatus()</code> every <b>15 s</b> while the "
        "resolved status is non-approved and not <code>tokenUnavailable</code>.",
        "It also re-probes on every <code>AppLifecycleState.resumed</code>.",
        "On the <code>approved</code> transition the poll stops, any open "
        "status dialog is popped, and <code>OrdersFeedNotifier</code> — "
        "which watches <code>deviceStartupProvider</code> — reconnects on "
        "its own. No restart.",
    ]),
]))

# ---------------------------------------------------------------------------
add("The live-orders WebSocket feed", "".join([
    lead("<code>OrdersFeedNotifier</code> (an "
         "<code>AsyncNotifier&lt;OrdersFeedState&gt;</code>, kept alive with "
         "<code>ref.keepAlive()</code>) owns the socket lifecycle. "
         "<code>OrdersLiveFeedRepository</code> is the transport."),
    h3("Handshake"),
    pre(
        "GET {wsBaseUrl}/ws?merchant_id={merchantId}\n"
        "Authorization: Bearer {device token from POST /devices/token}\n"
        "pingInterval: 20s\n"
    ),
    p("Connect order mirrors <code>mobile/</code>: "
      "<code>ensureWebhookToken</code> -> mint <code>/devices/token</code> "
      "-> <code>IOWebSocketChannel.connect</code> -> await "
      "<code>channel.ready</code> with a <b>10 s</b> timeout."),
    h3("Connection state machine"),
    table(["State", "Meaning"], [
        ["<code>connecting</code>", "Initial attempt in flight"],
        ["<code>connected</code>", "<code>ready</code> resolved, subscription live"],
        ["<code>reconnecting</code>", "Dropped or failed; retry scheduled"],
        ["<code>disconnected</code>", "No merchant / not approved / deactivated "
         "— nothing to connect to"],
    ]),
    h3("Reconnect / resilience"),
    ul([
        "Exponential backoff <b>1 s -> 30 s</b> (<code>* 2</code> each try). "
        "Reset to 1 s after a connection that stayed up &gt; 5 s.",
        "A <code>_connectGeneration</code> counter supersedes stale in-flight "
        "attempts so a slow handshake can't clobber a newer one.",
        "<code>connectivityStatusProvider</code> transition offline->online "
        "triggers an immediate reconnect when the feed is "
        "reconnecting/disconnected.",
        "401/403-looking errors call "
        "<code>DeviceTokenRepository.invalidate()</code> so the next attempt "
        "re-mints.",
        "De-dupe: a 200-entry ring of <code>event_id</code>s survives "
        "reconnects (the upstream replays a backlog on every resubscribe); "
        "only a full <code>_teardown</code> (dispose / merchant change) "
        "clears it.",
        "Hydration mute: for <b>4 s</b> after the first successful connect, "
        "toasts and OS notifications are suppressed to kill the backlog-replay "
        "notification storm.",
    ]),
    h3("Wire frame"),
    p("The WS envelope is <code>{ event_id, event_type, data }</code> — "
      "no <code>id</code> / <code>received_at</code> / <code>created_at</code> "
      "wrapper (those are synthesized). "
      "<code>OrderEventDto.fromWireJson</code> returns <code>null</code> "
      "(never throws) for: a non-string frame, non-object JSON, an "
      "<code>event_type</code> not starting <code>order.</code>, a missing "
      "<code>event_id</code>, or a non-object <code>data</code>. "
      "<code>OrderDataDto.fromWireJson</code> requires only <code>id</code>; "
      "every other field is lenient with defaults (the feed mixes full order "
      "events with identity-only <code>order.deleted</code> tombstones)."),
    table(["<code>event_type</code>", "Handling"], [
        ["<code>order.created</code>", "Upsert row, prepend to list, notify"],
        ["<code>order.updated</code>", "Upsert row, replace list entry by "
         "<code>data.id</code>, notify"],
        ["<code>order.cancelled</code>", "Same as updated; status -> "
         "<code>cancelled</code>"],
        ["<code>order.deleted</code>", "Delete local row + line items, remove "
         "from list"],
    ]),
]))

# ---------------------------------------------------------------------------
add("REST endpoints", "".join([
    lead("Two calls, both authenticated with the webhook JWT (not the device "
         "token). Paths are relative to <code>API_BASE_URL</code> and listed "
         "in <code>ApiEndpoints</code>."),
    h3("GET /merchant/orders"),
    table(["", ""], [
        ["Query", "<code>merchant_id</code>"],
        ["Header", "<code>Authorization: Bearer &lt;webhook JWT&gt;</code>"],
        ["Returns", "<code>MerchantOrdersDto</code> — a paginated "
         "order-event stream. <code>result.events</code> is already "
         "current-state: <code>order.deleted</code> tombstones are applied and "
         "unparseable events dropped."],
        ["On success", "<code>OrderEventsDao.replaceAll(merchantId, events)</code> "
         "then <code>OrdersState(events)</code>"],
        ["On failure", "fall back to "
         "<code>dao.getEvents(merchantId)</code>; if that is also empty, "
         "rethrow (drives the “Couldn't load orders” state); "
         "otherwise <code>OrdersState(events: cached, isStale: true)</code> "
         "-> the red cached-data banner"],
    ]),
    h3("PATCH /merchant/orders/{orderId}"),
    table(["", ""], [
        ["Body", "<code>{ \"updates\": { \"status\": \"&lt;status&gt;\" } }</code> "
         "— <code>cancelled</code> included"],
        ["Header", "<code>Authorization: Bearer &lt;webhook JWT&gt;</code>"],
        ["Accepts", "<code>200</code>"],
        ["Returns", "<code>OrderStatusUpdateResultDto</code> — echoes the "
         "canonical <code>order.updated</code> event the backend also "
         "broadcasts on the feed, so the caller converges the list on it"],
        ["Errors", "<code>DioException</code> is caught and rethrown as a "
         "<code>MerchantApiException</code> with a user-facing message "
         "(<code>&gt;=500</code> vs. connection error)"],
    ]),
    p("<code>OrdersNotifier</code> keeps a 200-entry "
      "<code>_appliedEventIds</code> ring so the socket echo of a change it "
      "just made via PATCH is not folded in a second time (which, with an "
      "out-of-order echo, could briefly revert the status)."),
    h3("Auth model summary"),
    table(["Token", "Minted by", "Used on", "Lifetime"], [
        ["Webhook JWT", "<code>POST /auth/token</code>", "All REST calls "
         "(<code>/devices/register</code>, <code>/devices/token</code>, "
         "<code>/merchant/orders</code> GET + PATCH)", "Short; re-minted "
         "&lt;1 min before <code>exp</code> or on merchant mismatch"],
        ["Device JWT", "<code>POST /devices/token</code>", "WS handshake "
         "<code>Authorization</code> header only", "Short; re-minted every "
         "connect attempt"],
        ["User JWT", "<code>POST /auth/login</code> (not wired)", "Attached by "
         "<code>AuthInterceptor</code> if present; a stray 401 signals "
         "session-expiry", "n/a — no login screen yet"],
    ]),
]))

# ---------------------------------------------------------------------------
add("Local database & secure storage", "".join([
    h3("Drift database"),
    p("<code>AppDatabase</code> (<code>@DriftDatabase</code>), one SQLite file "
      "<code>mobile_merchant.sqlite</code> in the app documents directory, "
      "opened in a background isolate. <code>schemaVersion = 4</code> with a "
      "stepwise <code>onUpgrade</code>."),
    table(["Table", "Holds"], [
        ["<code>merchant_table</code>", "The single merchant row "
         "(<code>id</code>, <code>merchant_id</code>, <code>merchant_name</code>). "
         "Added in v2."],
        ["<code>order_events_table</code>", "Cached order events — plus "
         "<code>fulfillment_type</code>, <code>facility_name</code>, "
         "<code>district_name</code> added in v4. Added in v3."],
        ["<code>order_items_table</code>", "Line items per cached order. "
         "Added in v3."],
    ]),
    p("Accessed only through <code>MerchantDao</code> / "
      "<code>OrderEventsDao</code> from the <code>data/</code> layer — "
      "never from <code>domain/</code>. Adding a table: add the "
      "<code>Table</code> class, list it in <code>@DriftDatabase</code>, bump "
      "<code>schemaVersion</code>, add an <code>onUpgrade</code> branch, "
      "re-run codegen."),
    h3("Secure storage — MerchantDeviceStorage"),
    p("A dedicated wrapper over <code>flutter_secure_storage</code>, separate "
      "from the user-auth <code>SecureStorage</code>. Keys:"),
    table(["Key", "Value"], [
        ["<code>merchant_webhook_token</code> / <code>_exp</code> / "
         "<code>_merchant_id</code>", "The <code>/auth/token</code> JWT, its "
         "unix expiry, and the merchant it is scoped to"],
        ["<code>merchant_device_id</code>", "<code>device_id</code> from "
         "<code>/devices/register</code>"],
        ["<code>merchant_device_secret</code>", "<code>device_secret</code> "
         "(written once, on the 202)"],
        ["<code>merchant_install_id</code>", "v4 UUID, generated once, never "
         "cleared"],
        ["<code>merchant_registered_merchant_id</code>", "Which merchant this "
         "device is enrolled under"],
        ["<code>merchant_device_status</code>", "Last seen enrolment status "
         "(optimistic gate)"],
        ["<code>merchant_device_ws_token</code> / <code>_exp</code> / "
         "<code>_merchant_id</code>", "The <code>/devices/token</code> JWT "
         "(cleared on handshake rejection)"],
        ["<code>custom_api_base_url</code>", "Runtime endpoint override "
         "(<code>AppConfig.customApiBaseUrlKey</code>)"],
    ]),
    p("<code>clearForMerchantChange()</code> wipes everything above "
      "<b>except</b> <code>merchant_install_id</code>. Called from "
      "<code>MerchantNotifier.save()</code> when the Merchant ID changes, "
      "followed by a fresh <code>activateDevice()</code>."),
]))

# ---------------------------------------------------------------------------
add("State management & providers", "".join([
    table(["Provider", "Type", "Responsibility"], [
        ["<code>merchantProvider</code>", "<code>AsyncNotifier&lt;Merchant?&gt;</code>",
         "Loads / creates / updates the single merchant row. "
         "<code>register()</code>, <code>save()</code>, "
         "<code>recheckDeviceStatus()</code>, <code>syncOnStartup()</code>."],
        ["<code>deviceStartupProvider</code>", "<code>FutureProvider&lt;DeviceStartupResult&gt;</code>",
         "Runs the launch auth chain once and memoizes. Awaited by the "
         "dashboard and by <code>OrdersFeedNotifier.build()</code> so the feed "
         "can't mint a device token before registration resolves. Invalidated "
         "explicitly by <code>MerchantNotifier.save()</code>."],
        ["<code>ordersFeedNotifierProvider</code>", "<code>AsyncNotifier&lt;OrdersFeedState&gt;</code>",
         "Socket lifecycle + connection state. <code>keepAlive</code>. "
         "<code>checkConnection()</code> is the idempotent re-probe called "
         "from the dashboard post-frame callback and after each approval "
         "re-check."],
        ["<code>ordersProvider</code>", "<code>AsyncNotifier&lt;OrdersState&gt;</code>",
         "The order <i>list</i>: initial REST fetch + cache fallback, "
         "<code>applyLiveEvent()</code>, <code>updateStatus()</code> / "
         "<code>cancelOrder()</code>, <code>refresh()</code>."],
        ["<code>connectivityStatusProvider</code>", "<code>Stream/AsyncValue&lt;bool&gt;</code>",
         "Wraps <code>connectivity_plus</code>; drives socket reconnect on "
         "the offline->online edge."],
    ]),
    h3("List-merge rules (subtle, easy to regress)"),
    ul([
        "<code>orders_body</code> de-dupes by <code>data.id</code> keeping "
        "the highest synthetic <code>id</code>, then sorts desc.",
        "<code>mergeLiveOrderEvent</code> drops any existing entry for the "
        "same <code>data.id</code> and prepends the incoming event.",
        "<code>OrdersNotifier._withStatus</code> rebuilds an "
        "<code>OrderEventDto</code> locally only when PATCH succeeds but "
        "echoes no usable event.",
        "<code>MerchantNotifier.syncOnStartup()</code> only re-emits "
        "<code>merchantProvider</code> when the row actually changed — a "
        "blind reassignment double-flashes the dashboard spinner.",
    ]),
]))

# ---------------------------------------------------------------------------
add("Notifications", "".join([
    p("<code>OrderNotificationsService</code> "
      "(<code>flutter_local_notifications</code>). "
      "<code>initialize()</code> runs in <code>bootstrap()</code> before "
      "<code>runApp</code>: it sets up the Android channel "
      "<code>live_orders</code> (“Live orders”, high importance) and "
      "calls <code>requestNotificationsPermission()</code> (Android 13+ "
      "runtime prompt). Every call is wrapped in a bare "
      "<code>try/catch</code> — a notification failure must never affect "
      "the feed."),
    p("<code>orderNotificationText(event)</code> is the single source of "
      "copy, shared by the OS notification and the in-app toast "
      "(<code>showOrderToast</code> via the global "
      "<code>appScaffoldMessengerKey</code>) so the two never drift. "
      "Notification id is <code>event.eventId.hashCode</code>."),
    table(["<code>event_type</code>", "Title", "Body"], [
        ["<code>order.created</code>", "New order #id", "“N items · CUR total”"],
        ["<code>order.cancelled</code>", "Order #id cancelled", "(empty)"],
        ["<code>order.deleted</code>", "Order #id removed", "(empty)"],
        ["other", "Order #id updated", "“Status: …”"],
    ]),
    note("Both toast and OS notification are gated behind the 4 s "
         "hydration-mute window after first connect (see the feed section).",
         "note"),
]))

# ---------------------------------------------------------------------------
add("Android configuration", "".join([
    note("<b>The single most important deployment fact.</b> "
         "<code>android/app/src/main/AndroidManifest.xml</code> declares only "
         "<code>POST_NOTIFICATIONS</code>. The <code>INTERNET</code> "
         "permission is present <b>only</b> in the "
         "<code>src/debug/AndroidManifest.xml</code> (Flutter adds it there "
         "for the dev tooling). A <b>release</b> build therefore ships with "
         "<b>no INTERNET permission</b> — and this app is useless without "
         "the network. You must add "
         "<code>&lt;uses-permission android:name=\"android.permission.INTERNET\"/&gt;</code> "
         "to the <b>main</b> manifest before shipping.", "warn"),
    h3("Manifest facts"),
    table(["Item", "Value"], [
        ["<code>android:label</code>", "<code>Cartivo Merchant</code>"],
        ["Launch activity", "<code>.MainActivity</code>, "
         "<code>singleTop</code>, exported"],
        ["Permissions (main)", "<code>POST_NOTIFICATIONS</code> only"],
        ["Permissions (debug overlay)", "<code>INTERNET</code>"],
        ["Icon", "<code>@mipmap/ic_launcher</code> "
         "(<code>flutter_launcher_icons</code>, source "
         "<code>assets/icon/app_icon.png</code>, <code>min_sdk_android: 21</code>)"],
    ]),
    h3("Recommended main-manifest additions before release"),
    pre(
        "<uses-permission android:name=\"android.permission.INTERNET\"/>\n"
        "<uses-permission android:name=\"android.permission.POST_NOTIFICATIONS\"/>\n"
        "<uses-permission android:name=\"android.permission.ACCESS_NETWORK_STATE\"/>\n"
    ),
    p("<code>ACCESS_NETWORK_STATE</code> is pulled in transitively by "
      "<code>connectivity_plus</code> but is worth making explicit."),
    h3("Platform coverage"),
    p("Android only. There is no <code>ios/</code>, <code>windows/</code>, "
      "<code>macos/</code>, or <code>linux/</code> folder. "
      "<code>flutter_launcher_icons</code> is configured with "
      "<code>ios: false</code>. The notification service references "
      "<code>DarwinInitializationSettings</code> for future parity only."),
]))

# ---------------------------------------------------------------------------
add("Building a release", "".join([
    h3("APK / App Bundle"),
    pre(
        "cd mobile_merchant\n"
        "cp .env.sample .env            # production values — real API_BASE_URL,\n"
        "                              # WEBHOOK_SECRET, CLIENT_ID\n"
        "flutter pub get\n"
        "dart run build_runner build --delete-conflicting-outputs\n"
        "flutter build apk --release            # or: flutter build appbundle --release\n"
    ),
    h3("Pre-flight checklist"),
    ul([
        "<code>INTERNET</code> permission added to the <b>main</b> manifest "
        "(see previous section).",
        "<code>.env</code> holds the production <code>API_BASE_URL</code> "
        "(with <code>https://</code> so the socket upgrades to <code>wss</code>).",
        "<code>WEBHOOK_SECRET</code> and <code>CLIENT_ID</code> are the "
        "real integration credentials, not the sample values.",
        "<code>ENABLE_LOGGING=false</code> for production.",
        "App signing configured in "
        "<code>android/app/build.gradle(.kts)</code> "
        "(<code>flutter build</code> uses the debug key otherwise).",
        "<code>version:</code> in <code>pubspec.yaml</code> bumped "
        "(currently <code>1.0.0+1</code>).",
        "Test on a <b>physical device</b> with a real (non-emulator) backend "
        "URL — the emulator's <code>10.0.2.2</code> fallback masks the "
        "INTERNET-permission bug.",
    ]),
    note("<code>.env</code> is bundled into the APK as an asset. Anything in "
         "it — including <code>WEBHOOK_SECRET</code> — is extractable "
         "from the built APK. Treat the webhook secret as a low-trust "
         "integration key, scope it tightly server-side, and rotate it if an "
         "APK leaks.", "warn"),
]))

# ---------------------------------------------------------------------------
add("Troubleshooting", "".join([
    h3("Socket never reaches “connected”"),
    ul([
        "<b>Release build, no orders, pill stuck:</b> missing "
        "<code>INTERNET</code> permission. #1 cause. Check the merged "
        "manifest in the built APK.",
        "<b><code>disconnected</code> not <code>reconnecting</code>:</b> the "
        "guard in <code>build()</code> / <code>checkConnection()</code> found "
        "no merchant, no webhook token, or a cached non-approved status. Not a "
        "network problem — check <code>deviceStartupProvider</code>.",
        "<b>Handshake 401/403:</b> device token rejected — check "
        "<code>device_secret</code> is present, the webhook JWT is for the "
        "right merchant, and the device is <code>approved</code> server-side.",
        "<b><code>ready</code> times out (10 s):</b> wrong "
        "<code>wsBaseUrl</code> (check the <code>[OrdersFeed] handshake — "
        "uri:</code> debug line), or the backend has no <code>/ws</code> "
        "route on that host.",
    ]),
    h3("Enable verbose logging"),
    p("Set <code>ENABLE_LOGGING=true</code> in <code>.env</code>. "
      "<code>LoggingInterceptor</code> then logs every request/response; "
      "<code>OrdersFeedNotifier</code> and "
      "<code>OrdersLiveFeedRepository</code> emit "
      "<code>[OrdersFeed]</code>-prefixed <code>debugPrint</code>s "
      "(handshake URI, decoded JWT claims, close code/reason, uptime on "
      "drop). Filter <code>flutter logs</code> / logcat on "
      "<code>OrdersFeed</code>."),
    h3("Orders load but status changes fail"),
    p("PATCH uses the webhook JWT via "
      "<code>ensureWebhookToken(merchant.merchantId)</code>. A 403 "
      "“merchant_id does not match” means a stale token scoped to a "
      "previous merchant — should self-heal on the next call; if not, "
      "clear storage and re-register."),
    h3("Reset a device completely"),
    ol([
        "Android <b>Settings › Apps › Cartivo Merchant › "
        "Storage › Clear storage</b> (wipes secure storage + the SQLite "
        "file, including <code>install_id</code>).",
        "Re-open the app; the <b>Register Merchant</b> dialog returns.",
        "Re-register — the backend sees a new <code>install_id</code>, so "
        "this enrols as a brand-new device needing fresh approval.",
    ]),
    h3("Network retry behaviour"),
    p("<code>RetryInterceptor</code> retries <b>only</b> pure connection "
      "errors / connection timeouts, up to "
      "<code>AppConfig.maxNetworkRetries</code> (2). It never retries once "
      "the server has responded. Timeouts: <code>connectTimeout 10 s</code>, "
      "<code>receiveTimeout 30 s</code>. <code>validateStatus</code> treats "
      "anything <code>&lt; 500</code> as a non-throwing response — "
      "<code>MerchantApi._assertSuccess</code> does the real status check."),
]))

# ---------------------------------------------------------------------------
add("Known constraints & current state", "".join([
    ul([
        "<b>Android only.</b> No other platform folders.",
        "<b>No user auth.</b> No login screen, no PIN, no per-user "
        "audit. The <code>auth</code> feature, route guards, "
        "<code>SessionManager</code> and <code>SessionExpiredListener</code> "
        "are stubs.",
        "<b>One route.</b> <code>'/' -> DashboardScreen</code>. "
        "<code>AppRoutes.login</code> is reserved but unwired.",
        "<b>Custom-endpoint UI is not surfaced.</b> "
        "<code>SettingsService</code> + <code>SETTINGS_PASSWORD</code> support "
        "a runtime <code>API_BASE_URL</code> override "
        "(<code>custom_api_base_url</code> in secure storage), but the toolbar "
        "gear opens <code>MerchantFormDialog</code>, not an endpoint dialog. "
        "The override can only be set programmatically / from a future "
        "screen.",
        "<b>No offline write queue.</b> Status changes and cancellations "
        "require a live connection; a failed change is simply lost and must "
        "be redone.",
        "<b>Single merchant per device.</b> Switching Merchant ID is a "
        "destructive re-enrolment.",
        "<b><code>device_secret</code> is single-issue.</b> If secure storage "
        "is cleared without a matching server-side device delete, the device "
        "row is orphaned — re-register produces a new "
        "<code>install_id</code> and a new device.",
        "<b>Currency symbol is hard-coded</b> to <code>₱</code> in the "
        "order card / sheet, regardless of the order's actual "
        "<code>currency</code> field (which <i>is</i> used in notification "
        "text).",
    ]),
    h3("Parity note"),
    p("Much of this app is a deliberate port of the live-orders subsystem in "
      "the sibling <code>mobile/</code> POS app — the device-status buckets "
      "and copy (<code>DeviceStatusVisual</code>), the connect-chain order, "
      "the de-dupe ring, and the hydration mute all mirror it. When changing "
      "behaviour here, check whether <code>mobile/</code> needs the same "
      "change.")
]))
