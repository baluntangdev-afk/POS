# mobile_merchant

A mobile app for DPO third-party merchants.

Feature-first clean architecture: Riverpod (codegen) · GetIt + Injectable DI ·
Dio wrapped in `Either<Failure, T>` · GoRouter · Drift for offline-capable local
storage.

## Getting started

```bash
cp .env.sample .env          # then fill in the values
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Re-run `build_runner` after changing any `@freezed`, `@riverpod`, `@injectable`,
`@JsonSerializable`, or Drift-annotated file.

```bash
dart analyze                 # static analysis
flutter test                 # tests
dart run build_runner watch --delete-conflicting-outputs   # during active dev
```

## Layout

```
lib/
├── main.dart        # entry — loads .env then bootstrap()
├── bootstrap.dart   # DI init + service warm-up + runApp
├── app.dart         # root MaterialApp.router
├── core/            # cross-cutting infrastructure (no feature logic)
│   ├── config/      env_config, app_config
│   ├── di/          injection (GetIt + Injectable)
│   ├── network/     api_client, network_handler, api_endpoints, interceptors/
│   ├── auth/        session-expiry contract + broadcast-stream impl
│   ├── router/      app_router, app_routes, route_guards (stub)
│   ├── database/    app_database (Drift — no tables yet)
│   ├── storage/     secure_storage
│   ├── services/    settings_service (runtime API base URL)
│   ├── theme/       app_colors, app_text_styles, app_spacing, app_theme
│   ├── error/       failure (Either side), app_exception (datasource boundary)
│   ├── providers/   connectivity_provider
│   ├── widgets/     session_expired_listener
│   └── utils/       app_logger, validators, extensions/
├── shared/          # reused by 2+ features: app_scaffold, app_button, ...
└── features/
    └── dashboard/   # landing screen — deliberately empty for now
```

See [`lib/features/README.md`](lib/features/README.md) for the per-feature layer
layout and the rules for adding a feature.

## Current state

Scaffold only. The dashboard is the landing route and renders a placeholder.
There is no `auth` feature yet — `core/router/route_guards.dart` and
`core/widgets/session_expired_listener.dart` are stubs wired to activate once it
exists. The Drift database has no tables and no datasource talks to it yet.

## Notes

- Package versions follow the reusable architecture template, except the codegen
  stack (freezed / riverpod / drift / injectable) which is on current majors —
  the template's older pins do not resolve on this Dart SDK.
- `custom_lint` / `riverpod_lint` are omitted until a compatible pair is
  available (see `pubspec.yaml`).
- Single-flavor: one `main.dart`, one `.env`. Add `main_dev` / `main_prod`
  entry points if per-environment builds become necessary.
