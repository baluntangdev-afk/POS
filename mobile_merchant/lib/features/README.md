# Feature modules

Feature-first clean architecture. Each feature is a self-contained vertical
slice with three layers:

```
<feature>/
├── data/
│   ├── datasources/
│   │   ├── <feature>_remote_datasource.dart   # abstract contract + Impl (Dio via NetworkHandler)
│   │   └── <feature>_local_datasource.dart    # abstract contract + Impl (Drift / AppDatabase)
│   ├── models/
│   │   └── <thing>_model.dart                 # @freezed + @JsonSerializable DTO + toEntity / toModel
│   └── repositories/
│       └── <feature>_repository_impl.dart     # @LazySingleton(as: <Feature>Repository)
├── domain/                                    # pure Dart — ZERO Flutter / infra imports
│   ├── entities/
│   │   └── <thing>_entity.dart                # @freezed, no JSON
│   ├── repositories/
│   │   └── <feature>_repository.dart          # abstract contract, returns Either<Failure, T>
│   └── usecases/
│       └── <verb>_<noun>_usecase.dart         # one class, one call(), params in a <X>Params class
└── presentation/                             # depends only on domain/
    ├── providers/
    │   └── <feature>_provider.dart            # @riverpod notifier (+ @freezed state)
    ├── screens/
    └── widgets/
```

## Rules

- `domain/` never imports Flutter or any infrastructure package.
- `data/` implements the contracts declared in `domain/repositories/`.
- `presentation/` depends only on `domain/` (entities, use cases, repo interfaces).
- Layer wiring is done by GetIt at runtime, never by direct construction.
- Riverpod notifiers resolve dependencies at call-time (`getIt<T>()` inside a
  method), never as constructor parameters.

## Data flow

```
View → Riverpod provider → UseCase → Repository (interface)
      → RepositoryImpl → DataSource Impl → NetworkHandler / AppDatabase → wire / SQLite
```

- `NetworkHandler.call(...)` is the only path from a datasource to the network.
- Datasource `Impl` methods throw typed `AppException`s;
  repository `Impl` methods catch them and return `Left(Failure.…)`.

## Adding a feature

1. Create the folder tree above under `lib/features/<feature>/`.
2. Register the repository impl and datasource impls with `@LazySingleton(as: …)`.
3. Add endpoint paths to `core/network/api_endpoints.dart`.
4. Add any local tables to `core/database/app_database.dart` (bump `schemaVersion`).
5. Add the route path to `core/router/app_routes.dart` and a `GoRoute` in
   `core/router/app_router.dart`.
6. Run `dart run build_runner build --delete-conflicting-outputs`.

## Current state

- `dashboard/` — landing screen only, deliberately empty. No data/domain code yet.
- No `auth` feature yet. `core/router/route_guards.dart` and
  `core/widgets/session_expired_listener.dart` are stubs waiting on it.
