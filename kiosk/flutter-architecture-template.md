# Flutter App Architecture Template

Reusable architecture reference, adapted from this WMS mobile app. Adjusted here for a
**Flutter Windows desktop app**: no camera scanner module, `flutter_secure_storage` used via
its Windows (Credential Manager) backend, and no dev/prod flavor split unless you need one.

Copy this file into a new project's `CLAUDE.md` (or `docs/`) and fill in the feature list.

---

## Core Principle: Feature-First Clean Architecture

Every feature lives under `lib/features/<feature>/` with three layers:

```
lib/features/<feature>/
├── data/
│   ├── datasources/     # remote (Dio) and/or local (Drift) datasources
│   ├── dtos/             # @freezed + @JsonSerializable request/response models
│   └── repositories/     # implements the domain repository contract
├── domain/
│   ├── entities/          # pure Dart @freezed models, no Flutter/infra imports
│   ├── repositories/      # abstract contracts (interfaces) consumed by data + presentation
│   └── usecases/          # one usecase per class, single `call()` method
└── presentation/
    ├── providers/          # Riverpod notifiers (@riverpod codegen)
    ├── screens/
    └── widgets/
```

**Dependency direction:** `presentation → domain ← data`. Domain has zero Flutter or
infrastructure imports. `data/repositories` implement the interfaces declared in
`domain/repositories`.

Shared, non-feature-specific code goes in `lib/core/` (infra) and `lib/shared/`
(cross-feature widgets/providers reused by 2+ features but not infra).

---

## lib/core/ layout

```
lib/core/
├── di/            # GetIt + Injectable setup, injection.config.dart (generated, gitignored)
├── network/       # ApiClient (Dio), NetworkHandler, ApiEndpoints
│   └── interceptors/   # e.g. AuthInterceptor
├── auth/          # SessionExpiredNotifier, SessionManager
├── router/        # GoRouter setup, RouterNotifier, AppRoutes constants, route_guards.dart
├── database/       # Drift local DB (app_database.dart)
├── storage/        # secure storage wrapper (flutter_secure_storage)
├── theme/          # AppColors, AppTextStyles, AppSpacing, AppTheme
├── error/          # Failure (freezed sealed class), AppException
├── config/         # EnvConfig (.env reader), AppConfig
├── utils/          # AppLogger, validators, extensions/
└── widgets/         # app-root widgets, e.g. SessionExpiredListener
```

---

## Dependency Injection — GetIt + Injectable

```dart
@LazySingleton(as: SomeRepository)
class SomeRepositoryImpl implements SomeRepository { ... }
```

- Register datasources/repositories/services with `@LazySingleton` / `@Injectable`.
- If you need mock-vs-real swapping (e.g. offline dev mode), use Injectable environments:
  `@LazySingleton(env: [Environment.dev])` vs `@LazySingleton(env: [Environment.prod])`,
  and select at startup: `configureDependencies(environment: EnvConfig.flavor)`.
- **Inside Riverpod notifiers**, resolve dependencies at call-time with `getIt<X>()` inside
  methods — not as constructor parameters — since notifiers are instantiated by the
  code-generated Riverpod factory, not by you.

`bootstrap()` sequence:
```dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(environment: EnvConfig.flavor);
  await getIt<SettingsService>().init(); // warm up before runApp
  runApp(const ProviderScope(child: App()));
}
```

---

## State Management — Riverpod (codegen)

```dart
part 'foo_provider.g.dart';

@riverpod
class FooNotifier extends _$FooNotifier {
  @override
  FooState build() => const FooState.initial();

  Future<void> doThing() async {
    final repo = getIt<FooRepository>();
    final result = await repo.fetch();
    result.fold(
      (failure) => state = FooState.error(failure.toMessage()),
      (data) => state = FooState.loaded(data),
    );
  }
}
```

- Widgets that read providers are `ConsumerWidget` / `ConsumerStatefulWidget`.
- Multi-field state classes use `@freezed` for `copyWith` + union states
  (`initial/loading/loaded/error`).
- No business logic in widgets — it lives in notifiers or usecases.

---

## Network Layer — Dio + Either<Failure, T>

```dart
class NetworkHandler {
  Future<Either<Failure, T>> call<T>({
    required Future<Response> Function() request,
    required T Function(dynamic json) parser,
  }) async {
    try {
      final response = await request();
      return Right(parser(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDioException(e));
    }
  }
}
```

- **Never** call `dio` directly from a repository or screen — always go through
  `NetworkHandler.call(...)`.
- `Failure` is a `@freezed` sealed class (network, server, cache, validation, unknown, …)
  with a `.toMessage()` extension for UI-facing strings.
- Repositories return `Either<Failure, Entity>`; usecases pass that straight through;
  notifiers `.fold()` it into UI state.

---

## Local Database — Drift (offline-capable)

- One `AppDatabase` (`@DriftDatabase(tables: [...])`) in `lib/core/database/`.
- Feature datasources depend on `AppDatabase` (injected via GetIt) for local reads/writes.
- Use Drift for anything that needs to work offline or be queried locally (caches, drafts,
  offline queues) — keep it out of `domain/`, only `data/datasources` talk to it.

---

## Routing — GoRouter

- `AppRoutes` — route path constants.
- `RouterNotifier extends ChangeNotifier` (or Riverpod `Listenable`) listens to
  `authNotifierProvider` and triggers `router.refresh()` on auth state changes.
- `redirect:` callback in `GoRouter` gates all routes based on auth state
  (see `route_guards.dart` for reusable guard functions).
- Navigation always via `context.go()` / `context.push()` — never raw `Navigator`.

---

## Session Expiry Pattern (if the app has auth)

1. `AuthInterceptor` (Dio interceptor) catches 401 responses.
2. Calls `getIt<SessionExpiredNotifier>().signalExpired()` (a broadcast stream/notifier).
3. `SessionExpiredListener` — mounted once near the widget tree root — subscribes and
   calls `authNotifier.logout()` + navigates to the login route.
4. `SessionManager` deduplicates repeated 401s (e.g. from parallel requests) until
   `resetNotifying()` is called after logout completes.

---

## Windows Desktop Adjustments (vs. the mobile WMS original)

| Mobile WMS app | Windows desktop equivalent |
|---|---|
| `mobile_scanner` (camera barcode scan) | Drop it. If you need barcode input, accept USB/HID scanner input as raw keyboard events, or add manual entry — no camera constraint applies on desktop. |
| `flutter_secure_storage` (Keychain/Keystore) | Same package works — backed by Windows Credential Manager. No changes needed. |
| `connectivity_plus` for online/offline banner | Still works on Windows; verify behavior over Ethernet/Wi-Fi transitions. |
| Dev/prod flavors via `main_dev.dart`/`main_prod.dart` + `.env.dev`/`.env.prod` | Optional — only add this if you actually need separate mock vs. real backends. A single `main.dart` + one `.env` is simpler if not. |
| `AppScaffold` sized for phone screens | Redesign for desktop: resizable window, wider layouts, keyboard/mouse-first interactions (hover states, right-click menus), no bottom nav — prefer a side nav rail. |

---

## Core Conventions to Carry Over

- No business logic in widgets — logic lives in providers/notifiers or usecases.
- No `print()` — use a centralized `AppLogger`.
- No hardcoded colors/text styles — use `AppColors` / `AppTextStyles` constants.
- Every screen wrapped in a common `AppScaffold` (adapt its internals for desktop chrome).
- Generated files (`*.g.dart`, `*.freezed.dart`, `injection.config.dart`) are gitignored;
  rebuild after any `@freezed`/`@riverpod`/`@injectable`/`@JsonSerializable` change:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  # or, during active development:
  dart run build_runner watch --delete-conflicting-outputs
  ```
- Never commit changes unless explicitly asked.

---

## Suggested pubspec.yaml dependencies (Windows desktop starter)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Routing
  go_router: ^14.0.0

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Models / codegen
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

  # Networking
  dio: ^5.4.3
  pretty_dio_logger: ^1.3.1
  connectivity_plus: ^6.0.5

  # DI
  get_it: ^7.7.0
  injectable: ^2.4.2

  # Storage
  flutter_secure_storage: ^9.2.2

  # Local database
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0

  # Environment (optional, only if using .env)
  flutter_dotenv: ^5.1.0

  # Utilities
  equatable: ^2.0.5
  dartz: ^0.10.1
  intl: ^0.19.0
  logger: ^2.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  injectable_generator: ^2.6.1
  drift_dev: ^2.14.0
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10
  flutter_lints: ^6.0.0
```

`mobile_scanner` intentionally omitted — add it back only if the Windows app needs camera
barcode scanning (uncommon on desktop; USB HID scanners typically just inject keystrokes).
