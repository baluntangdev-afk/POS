# Tile Grid + PIN Login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the kiosk's typed-username login step with a tap-to-select tile grid of active staff, backed by a new public `GET /users/roster` endpoint.

**Architecture:** A new public backend endpoint returns a minimal roster (id, name, image) for active/unlocked users. The kiosk fetches it through a new `AuthRepository.getLoginRoster()` method (reusing the existing unauthenticated Dio client the same way login already does) and renders it as a grid; tapping a tile moves the existing `LoginView` into its current PIN-entry step, now scoped to the selected user instead of a typed username.

**Tech Stack:** NestJS + TypeORM (backend), Flutter + Hooks Riverpod + dart_mappable (kiosk).

---

## Note on test coverage vs. the spec

The spec's Testing section calls for a "widget test for the grid step." This codebase has no working `pumpWidget`-based test harness for any feature (`test/widget_test.dart` is an untouched placeholder) — the actual established pattern for testing view logic is a state-notifier/provider test with a fake repository injected via `ProviderContainer` overrides (see `test/features/cashier_report/state/z_reading_notifier_test.dart`). This plan follows that established pattern instead of introducing a new, unproven widget-test setup: `LoginRosterNotifier` gets a provider-level test covering loading/error/data states, which is the testable unit the grid step's behavior actually depends on. The grid/tile widgets themselves are simple, presentation-only `StatelessWidget`s with no branching logic beyond what the notifier test already covers.

---

## Task 1: Backend — `LoginRosterItemDto`

**Files:**
- Create: `be/src/users/dto/login-roster-item.dto.ts`

- [ ] **Step 1: Create the DTO file**

```ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserSuffix } from '../users.enum';
import type { FindOptionsSelect } from 'typeorm';
import type { User } from '../entities/user.entity';

/**
 * Minimal, public-safe shape of a user for the kiosk's pre-login staff tile grid.
 * Excludes email, phone, role, and status — anything not needed to render a tile.
 */
export class LoginRosterItemDto {
  @ApiProperty({ description: 'User ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'User identifier', example: 'USR-001' })
  userId: string;

  @ApiProperty({ description: 'First name', example: 'John' })
  firstName: string;

  @ApiPropertyOptional({ description: 'Middle name' })
  middleName: string | null;

  @ApiProperty({ description: 'Last name', example: 'Doe' })
  lastName: string;

  @ApiPropertyOptional({ description: 'Name suffix', enum: UserSuffix })
  suffix: UserSuffix | null;

  @ApiPropertyOptional({ description: 'Profile image URL' })
  image: string | null;
}

/**
 * TypeORM select option for the login roster query (matches LoginRosterItemDto fields).
 */
export const LOGIN_ROSTER_SELECT: FindOptionsSelect<User> = {
  id: true,
  userId: true,
  firstName: true,
  middleName: true,
  lastName: true,
  suffix: true,
  image: true,
};
```

- [ ] **Step 2: Verify the backend still type-checks**

Run: `cd be && npm run build`
Expected: build completes with no TypeScript errors.

- [ ] **Step 3: Commit**

```bash
git add be/src/users/dto/login-roster-item.dto.ts
git commit -m "feat: add LoginRosterItemDto for public staff roster"
```

---

## Task 2: Backend — `UsersService.findLoginRoster()`

**Files:**
- Modify: `be/src/users/users.service.ts`
- Test: `be/src/users/users.service.spec.ts`

- [ ] **Step 1: Write the failing test**

Add to `be/src/users/users.service.spec.ts`, inside the existing `describe('UsersService', ...)` block (after the `describe('create', ...)` block, before its closing `});`):

```ts
  describe('findLoginRoster', () => {
    it('queries only active, unlocked users and selects roster fields', async () => {
      mockUserRepo.find.mockResolvedValue([
        { id: 1, userId: 'USR-001', firstName: 'Jane', middleName: null, lastName: 'Doe', suffix: null, image: null },
      ]);

      const result = await service.findLoginRoster();

      expect(mockUserRepo.find).toHaveBeenCalledWith({
        where: { status: BaseStatus.ACTIVE, locked: false },
        select: LOGIN_ROSTER_SELECT,
        order: { firstName: 'ASC' },
      });
      expect(result).toEqual([
        { id: 1, userId: 'USR-001', firstName: 'Jane', middleName: null, lastName: 'Doe', suffix: null, image: null },
      ]);
    });
  });
```

Add these imports at the top of `be/src/users/users.service.spec.ts`:

```ts
import { BaseStatus } from '../utils/shared-enums';
import { LOGIN_ROSTER_SELECT } from './dto/login-roster-item.dto';
```

Also add `find: jest.fn(),` to the `mockUserRepo` object at the top of the file (it currently only has `create`, `save`, `update`, `findOne`):

```ts
const mockUserRepo = {
  create: jest.fn(),
  save: jest.fn(),
  update: jest.fn(),
  findOne: jest.fn(),
  find: jest.fn(),
};
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd be && npx jest --testPathPattern=src/users/users.service.spec.ts -t "findLoginRoster"`
Expected: FAIL with `TypeError: service.findLoginRoster is not a function` (or similar).

- [ ] **Step 3: Implement `findLoginRoster()`**

In `be/src/users/users.service.ts`:

Add to the imports at the top:

```ts
import { BaseStatus } from '../utils/shared-enums';
import { LOGIN_ROSTER_SELECT } from './dto/login-roster-item.dto';
```

Add this method to the `UsersService` class, immediately after `findAuthorizers()`:

```ts
  async findLoginRoster() {
    return this.userRepository.find({
      where: { status: BaseStatus.ACTIVE, locked: false },
      select: LOGIN_ROSTER_SELECT,
      order: { firstName: 'ASC' },
    });
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd be && npx jest --testPathPattern=src/users/users.service.spec.ts`
Expected: PASS, all tests in the file green.

- [ ] **Step 5: Commit**

```bash
git add be/src/users/users.service.ts be/src/users/users.service.spec.ts
git commit -m "feat: add UsersService.findLoginRoster for public staff roster"
```

---

## Task 3: Backend — `GET /users/roster` route

**Files:**
- Modify: `be/src/users/users.controller.ts`
- Test: `be/src/users/users.controller.spec.ts`

- [ ] **Step 1: Write the failing test**

Replace the contents of `be/src/users/users.controller.spec.ts` with:

```ts
import { Test, TestingModule } from '@nestjs/testing';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

describe('UsersController', () => {
  let controller: UsersController;
  let service: { findLoginRoster: jest.Mock };

  beforeEach(async () => {
    service = { findLoginRoster: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [{ provide: UsersService, useValue: service }],
    }).compile();

    controller = module.get<UsersController>(UsersController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('findLoginRoster', () => {
    it('delegates to usersService.findLoginRoster', async () => {
      const roster = [{ id: 1, userId: 'USR-001', firstName: 'Jane' }];
      service.findLoginRoster.mockResolvedValue(roster);

      const result = await controller.findLoginRoster();

      expect(service.findLoginRoster).toHaveBeenCalled();
      expect(result).toBe(roster);
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd be && npx jest --testPathPattern=src/users/users.controller.spec.ts`
Expected: FAIL with `TypeError: controller.findLoginRoster is not a function`.

- [ ] **Step 3: Add the route**

In `be/src/users/users.controller.ts`, add to the imports:

```ts
import { Public } from '../auth/decorators/public.decorator';
import { LoginRosterItemDto } from './dto/login-roster-item.dto';
```

Add this method immediately after `findAuthorizers()` and **before** the `@Post('verify-pin')` method (must come before the `@Get(':id')` handler so the literal path isn't shadowed):

```ts
  @Get('roster')
  @Public()
  @ApiOkResponse({ type: [LoginRosterItemDto] })
  findLoginRoster() {
    return this.usersService.findLoginRoster();
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd be && npx jest --testPathPattern=src/users/users.controller.spec.ts`
Expected: PASS.

- [ ] **Step 5: Run the full backend test suite to check for regressions**

Run: `cd be && npm run test`
Expected: no new failures introduced by this change (pre-existing unrelated failures, if any, are out of scope).

- [ ] **Step 6: Commit**

```bash
git add be/src/users/users.controller.ts be/src/users/users.controller.spec.ts
git commit -m "feat: expose public GET /users/roster endpoint for kiosk login"
```

---

## Task 4: Kiosk — `LoginRosterItemDto` schema

**Files:**
- Create: `kiosk/lib/data/backend_api/schemas/login_roster_item_dto.dart`

- [ ] **Step 1: Create the schema file**

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'login_roster_item_dto.mapper.dart';

@MappableClass()
class LoginRosterItemDto with LoginRosterItemDtoMappable {
  const LoginRosterItemDto({
    required this.id,
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.suffix,
    this.image,
  });

  final int id;
  final String userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? suffix;
  final String? image;

  static const fromJson = LoginRosterItemDtoMapper.fromJson;
}
```

- [ ] **Step 2: Generate the mapper**

Run: `cd kiosk && fvm dart run build_runner build --delete-conflicting-outputs`
Expected: completes successfully and creates `kiosk/lib/data/backend_api/schemas/login_roster_item_dto.mapper.dart`.

- [ ] **Step 3: Verify analysis is clean**

Run: `cd kiosk && fvm dart analyze lib/data/backend_api/schemas/login_roster_item_dto.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add kiosk/lib/data/backend_api/schemas/login_roster_item_dto.dart kiosk/lib/data/backend_api/schemas/login_roster_item_dto.mapper.dart
git commit -m "feat: add LoginRosterItemDto schema"
```

---

## Task 5: Kiosk — `UserApi.getLoginRoster()`

**Files:**
- Modify: `kiosk/lib/data/backend_api/sources/user_api.dart`

- [ ] **Step 1: Add the unauthenticated client and the new method**

`UserApi` currently only holds a `secureClient` (see `kiosk/lib/data/backend_api/sources/user_api.dart:12-24`). The roster call happens before login, so it must use the unauthenticated client — same split `AuthApi` already uses (`kiosk/lib/data/backend_api/sources/auth_api.dart:11-21`).

Replace the top of `kiosk/lib/data/backend_api/sources/user_api.dart` (imports through the class fields) with:

```dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/authorizer_dto.dart';
import '../schemas/create_user_dto.dart';
import '../schemas/login_roster_item_dto.dart';
import '../schemas/user_dto.dart';
import '../schemas/users_response_dto.dart';

final userApiProvider = Provider<UserApi>((ref) {
  final secureClient = ref.watch(secureApiClientProvider);
  final openClient = ref.watch(openApiClientProvider);
  return UserApi(secureClient, openClient);
});

final authorizersProvider = FutureProvider.autoDispose<List<AuthorizerDto>>((ref) {
  return ref.watch(userApiProvider).getAuthorizers();
});

class UserApi {
  UserApi(this._secureClient, this._openClient);

  final Dio _secureClient;
  final Dio _openClient;

  Future<List<LoginRosterItemDto>> getLoginRoster() async {
    final response = await _openClient.get<dynamic>('/api/v1/users/roster');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => LoginRosterItemDto.fromJson(jsonEncode(item as Map<String, dynamic>)))
        .toList();
  }

  Future<List<AuthorizerDto>> getAuthorizers() async {
```

(Leave `getAuthorizers()`'s body and every method below it exactly as-is — only the header block above and this one new method are added.)

- [ ] **Step 2: Verify analysis is clean**

Run: `cd kiosk && fvm dart analyze lib/data/backend_api/sources/user_api.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/data/backend_api/sources/user_api.dart
git commit -m "feat: add UserApi.getLoginRoster using the unauthenticated client"
```

---

## Task 6: Kiosk — `LoginRosterItem` entity

**Files:**
- Create: `kiosk/lib/features/auth/entities/login_roster_item.dart`

- [ ] **Step 1: Create the entity**

Mirrors the existing `Auth` entity's `fullName` convention (`kiosk/lib/features/auth/entities/auth.dart:29-34`), plus an `initials` getter the tile widget needs.

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'login_roster_item.mapper.dart';

@MappableClass()
class LoginRosterItem with LoginRosterItemMappable {
  const LoginRosterItem({
    required this.id,
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.suffix,
    this.image,
  });

  final int id;
  final String userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? suffix;
  final String? image;

  String get fullName => [
    firstName.trim(),
    middleName?.trim(),
    lastName.trim(),
    suffix?.trim(),
  ].where((e) => e?.isNotEmpty ?? false).join(' ');

  String get initials {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    return '$first$last'.toUpperCase();
  }
}
```

- [ ] **Step 2: Generate the mapper**

Run: `cd kiosk && fvm dart run build_runner build --delete-conflicting-outputs`
Expected: completes successfully and creates `kiosk/lib/features/auth/entities/login_roster_item.mapper.dart`.

- [ ] **Step 3: Verify analysis is clean**

Run: `cd kiosk && fvm dart analyze lib/features/auth/entities/login_roster_item.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add kiosk/lib/features/auth/entities/login_roster_item.dart kiosk/lib/features/auth/entities/login_roster_item.mapper.dart
git commit -m "feat: add LoginRosterItem entity"
```

---

## Task 7: Kiosk — `AuthRepository.getLoginRoster()`

**Files:**
- Modify: `kiosk/lib/features/auth/repositories/auth_repository.dart`

- [ ] **Step 1: Add the method to the interface and implementation**

In `kiosk/lib/features/auth/repositories/auth_repository.dart`, add to the imports:

```dart
import '../entities/login_roster_item.dart';
```

Add to the `AuthRepository` abstract class (after `getCurrent()`):

```dart
  Future<List<LoginRosterItem>> getLoginRoster();
```

Add to `AuthRepositoryImpl` (after `getCurrent()`'s implementation, i.e. right before `login()`):

```dart
  @override
  Future<List<LoginRosterItem>> getLoginRoster() async {
    final dtos = await _userApi.getLoginRoster();
    return dtos.map(_rosterItemFromDto).toList();
  }
```

Add this private mapper method after the existing `_authFromUserDto()` method:

```dart
  LoginRosterItem _rosterItemFromDto(LoginRosterItemDto dto) {
    return LoginRosterItem(
      id: dto.id,
      userId: dto.userId,
      firstName: dto.firstName,
      middleName: dto.middleName,
      lastName: dto.lastName,
      suffix: dto.suffix == 'None' ? null : dto.suffix,
      image: dto.image,
    );
  }
```

Add to the imports the schema type used above:

```dart
import '../../../data/backend_api/schemas/login_roster_item_dto.dart';
```

- [ ] **Step 2: Verify analysis is clean**

Run: `cd kiosk && fvm dart analyze lib/features/auth/repositories/auth_repository.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/auth/repositories/auth_repository.dart
git commit -m "feat: add AuthRepository.getLoginRoster"
```

---

## Task 8: Kiosk — `LoginRosterNotifier`

**Files:**
- Create: `kiosk/lib/features/auth/state/login_roster_notifier.dart`
- Test: `kiosk/test/features/auth/state/login_roster_notifier_test.dart`

This follows the `AsyncNotifier` + fake-repository pattern already used by `z_reading_notifier_test.dart` and `login_state_notifier.dart` in this codebase, rather than a widget test (see the note at the top of this plan).

- [ ] **Step 1: Write the failing test**

Create `kiosk/test/features/auth/state/login_roster_notifier_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_app/features/auth/entities/auth.dart';
import 'package:pos_app/features/auth/entities/login_roster_item.dart';
import 'package:pos_app/features/auth/repositories/auth_repository.dart';
import 'package:pos_app/features/auth/state/login_roster_notifier.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.roster);

  List<LoginRosterItem> roster;
  bool shouldThrow = false;
  int getLoginRosterCallCount = 0;

  @override
  Future<List<LoginRosterItem>> getLoginRoster() async {
    getLoginRosterCallCount++;
    if (shouldThrow) throw Exception('network error');
    return roster;
  }

  @override
  Future<Auth> getCurrent() async => throw UnimplementedError();

  @override
  Future<Auth> login(String username, String pin) async => throw UnimplementedError();

  @override
  Future<bool> logout() async => throw UnimplementedError();

  @override
  Future<Auth> changePin(int id, String newPin) async => throw UnimplementedError();
}

const _jane = LoginRosterItem(id: 1, userId: 'USR-001', firstName: 'Jane', lastName: 'Doe');

void main() {
  test('build() fetches the roster from the repository', () async {
    final repo = _FakeAuthRepository([_jane]);
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final result = await container.read(loginRosterProvider.future);

    expect(result, [_jane]);
    expect(repo.getLoginRosterCallCount, 1);
  });

  test('build() surfaces repository errors as AsyncError', () async {
    final repo = _FakeAuthRepository([])..shouldThrow = true;
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    try {
      await container.read(loginRosterProvider.future);
    } catch (_) {
      // Expected: build() rethrows the repository's error.
    }

    expect(container.read(loginRosterProvider).hasError, isTrue);
    expect(repo.getLoginRosterCallCount, 1);
  });
}
```

**Deviation found during implementation:** `expectLater(..., throwsException)` hung for 30s and timed out. Root cause: Riverpod 3's `AsyncNotifierProvider` retries a failing `build()` automatically (10 retries, exponential backoff up to 6.4s — 40+s total) unless `retry:` is overridden. This is also a real product bug, not just a test artifact — it would leave the grid spinning for up to 40s before the spec's error/retry UI ever appeared. Fixed by adding `retry: (retryCount, error) => null` to the `loginRosterProvider` definition in Step 3 below, and rewriting the test to use try/catch (matching the pattern already used in `z_reading_notifier_test.dart`) instead of `expectLater`/`throwsException`.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd kiosk && fvm flutter test test/features/auth/state/login_roster_notifier_test.dart`
Expected: FAIL — `login_roster_notifier.dart` does not exist yet (compile error).

- [ ] **Step 3: Implement the notifier**

Create `kiosk/lib/features/auth/state/login_roster_notifier.dart`:

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/login_roster_item.dart';
import '../repositories/auth_repository.dart';

final loginRosterProvider = AsyncNotifierProvider<LoginRosterNotifier, List<LoginRosterItem>>(
  LoginRosterNotifier.new,
  name: 'loginRosterProvider',
  // The login screen shows its own error/retry UI immediately on failure;
  // Riverpod's default automatic retry (10 attempts, up to ~40s of backoff)
  // would leave the grid spinning long before that UI ever appears.
  retry: (retryCount, error) => null,
);

class LoginRosterNotifier extends AsyncNotifier<List<LoginRosterItem>> {
  @override
  Future<List<LoginRosterItem>> build() async {
    final authRepository = ref.read<AuthRepository>(authRepositoryProvider);
    return authRepository.getLoginRoster();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd kiosk && fvm flutter test test/features/auth/state/login_roster_notifier_test.dart`
Expected: PASS, both tests green.

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/features/auth/state/login_roster_notifier.dart kiosk/test/features/auth/state/login_roster_notifier_test.dart
git commit -m "feat: add LoginRosterNotifier"
```

---

## Task 9: Kiosk — `UserTile` widget

**Files:**
- Create: `kiosk/lib/features/auth/view/user_tile.dart`

- [ ] **Step 1: Create the tile widget**

Follows the existing image-with-fallback pattern from `catalog_grid_screen.dart:718-722` and the design tokens from `kiosk/lib/theme/pos_design.dart`.

```dart
import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../entities/login_roster_item.dart';

class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user, required this.onTap});

  final LoginRosterItem user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final avatarSize = responsive.value<double>(phone: 56, tablet: 64, kiosk: 72);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(POSRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(POSRadius.lg),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: responsive.value<double>(phone: 16, tablet: 20, kiosk: 24),
            horizontal: responsive.value<double>(phone: 8, tablet: 10, kiosk: 12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(POSRadius.lg),
            border: Border.all(color: POSColors.borderDefault),
            boxShadow: POSShadow.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(user: user, size: avatarSize),
              SizedBox(height: responsive.value<double>(phone: 10, tablet: 12, kiosk: 14)),
              Text(
                '${user.firstName} ${user.lastName.isNotEmpty ? '${user.lastName[0]}.' : ''}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: POSColors.textPrimary,
                  fontSize: responsive.value<double>(phone: 14, tablet: 15, kiosk: 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size});

  final LoginRosterItem user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = user.image;

    Widget initialsCircle() => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: ColorSet.primary, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            user.initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.36,
            ),
          ),
        );

    if (image == null || image.isEmpty) {
      return initialsCircle();
    }

    return ClipOval(
      child: Image.network(
        image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => initialsCircle(),
      ),
    );
  }
}
```

**Deviation found during implementation:** the plan's original `(_, _, ___)` triggered `unnecessary_underscores` lint (this project's analyzer wants either a single `_` per unused positional param, or all-matching `_` wildcards — not a mix of `_`/`__`/`___`). Fixed to `(_, _, _)`.

- [ ] **Step 2: Verify analysis is clean**

Run: `cd kiosk && fvm dart analyze lib/features/auth/view/user_tile.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/auth/view/user_tile.dart
git commit -m "feat: add UserTile widget for the login grid"
```

---

## Task 10: Kiosk — `UserGrid` widget (loading/error/empty/populated)

**Files:**
- Create: `kiosk/lib/features/auth/view/user_grid.dart`

- [ ] **Step 1: Create the grid widget**

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../entities/login_roster_item.dart';
import '../state/login_roster_notifier.dart';
import 'user_tile.dart';

class UserGrid extends ConsumerWidget {
  const UserGrid({super.key, required this.onUserSelected});

  final void Function(LoginRosterItem user) onUserSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterState = ref.watch(loginRosterProvider);

    return rosterState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: ColorSet.primary)),
      ),
      error: (error, stackTrace) => _RosterError(
        onRetry: () => ref.invalidate(loginRosterProvider),
      ),
      data: (roster) {
        if (roster.isEmpty) {
          return const _RosterEmpty();
        }

        final columns = context.responsive.value<int>(phone: 2, tablet: 3, kiosk: 4);
        final spacing = context.responsive.value<double>(phone: 12, tablet: 16, kiosk: 20);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 0.85,
          ),
          itemCount: roster.length,
          itemBuilder: (context, index) {
            final user = roster[index];
            return UserTile(user: user, onTap: () => onUserSelected(user));
          },
        );
      },
    );
  }
}

class _RosterError extends StatelessWidget {
  const _RosterError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: ColorSet.danger, size: 40),
          const SizedBox(height: 12),
          Text(
            'Could not load staff list. Check your connection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: POSColors.textSecondary, fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 15)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: ColorSet.primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _RosterEmpty extends StatelessWidget {
  const _RosterEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.people_outline_rounded, color: POSColors.textTertiary, size: 40),
          const SizedBox(height: 12),
          Text(
            'No staff accounts are available. Please contact an administrator.',
            textAlign: TextAlign.center,
            style: TextStyle(color: POSColors.textSecondary, fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 15)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analysis is clean**

Run: `cd kiosk && fvm dart analyze lib/features/auth/view/user_grid.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/auth/view/user_grid.dart
git commit -m "feat: add UserGrid widget with loading/error/empty states"
```

---

## Task 11: Kiosk — rewire `LoginView` into a two-step flow

**Files:**
- Modify: `kiosk/lib/features/auth/view/login_view.dart`
- Delete: `kiosk/lib/features/auth/view/username_input.dart`

`UsernameInput` is only referenced from `login_view.dart` (verified — no other usages in the codebase), so it's safe to delete once this task removes that usage.

- [ ] **Step 1: Replace `login_view.dart`**

Replace the full contents of `kiosk/lib/features/auth/view/login_view.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../exceptions/exception_extension.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/pin_indicator.dart';
import '../../../widgets/pin_pad.dart';
import '../entities/login_roster_item.dart';
import '../state/login_state_notifier.dart';
import 'user_grid.dart';

enum _LoginStep { selectUser, enterPin }

class LoginView extends HookConsumerWidget {
  const LoginView({super.key, required this.isSmallHeight});

  final bool isSmallHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState(_LoginStep.selectUser);
    final selectedUser = useState<LoginRosterItem?>(null);
    final pin = useState('');
    final selectedButton = useState<int?>(null);
    final loginError = useState<String?>(null);
    final isDialogShowing = useRef(false);

    ref.listen(loginStateProvider, (previous, next) {
      if (next.isLoading) {
        isDialogShowing.value = true;
        showDialog<void>(
          barrierDismissible: false,
          context: context,
          builder: (_) => _LoginLoadingDialog(),
        );
        return;
      }

      if (isDialogShowing.value) {
        isDialogShowing.value = false;
        Navigator.of(context, rootNavigator: true).pop();
      }

      next.whenOrNull(
        data: (auth) {
          if (auth != null) {
            loginError.value = null;
            if (auth.isPinChanged) {
              const MenuRoute().go(context);
              return;
            }
            pin.value = '';
            showMessageDialog(
              context,
              message: 'You need to change your PIN to continue.',
              type: DialogType.warning,
              primaryButtonText: 'Change PIN',
              onPrimaryPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                SetupPinRoute(auth).push<void>(context);
              },
            );
          }
        },
        error: (error, stackTrace) {
          loginError.value = error.message;
          pin.value = '';
        },
      );
    });

    void attemptLogin() {
      final user = selectedUser.value;
      if (user != null && pin.value.length == 6) {
        ref.read(loginStateProvider.notifier).login(user.userId, pin.value);
      }
    }

    void onNumberPressed(String number) {
      loginError.value = null;

      if (pin.value.length < 6) {
        pin.value += number;

        if (pin.value.length == 6) {
          Future.delayed(const Duration(milliseconds: 300), attemptLogin);
        }
      }
    }

    void onBackspace() {
      if (pin.value.isNotEmpty) {
        loginError.value = null;
        pin.value = pin.value.substring(0, pin.value.length - 1);
      }
    }

    void selectUser(LoginRosterItem user) {
      selectedUser.value = user;
      pin.value = '';
      loginError.value = null;
      step.value = _LoginStep.enterPin;
    }

    void backToUserSelection() {
      step.value = _LoginStep.selectUser;
      selectedUser.value = null;
      pin.value = '';
      loginError.value = null;
    }

    final hPad = context.responsive.value<double>(phone: 28, tablet: 36, kiosk: 48);
    final vPad = context.responsive.value<double>(phone: 24, tablet: 28, kiosk: 36);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: step.value == _LoginStep.selectUser
          ? _SelectUserStep(onUserSelected: selectUser)
          : _EnterPinStep(
              user: selectedUser.value!,
              pin: pin.value,
              loginError: loginError.value,
              selectedButton: selectedButton,
              onNumberPressed: onNumberPressed,
              onBackspace: onBackspace,
              onConfirm: attemptLogin,
              onBack: backToUserSelection,
            ),
    );
  }
}

class _SelectUserStep extends StatelessWidget {
  const _SelectUserStep({required this.onUserSelected});

  final void Function(LoginRosterItem user) onUserSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Who\'s working?',
          style: TextStyle(
            color: POSColors.textPrimary,
            fontSize: context.responsive.value<double>(phone: 26, tablet: 30, kiosk: 34),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Tap your name to continue',
          style: TextStyle(
            color: POSColors.textTertiary,
            fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 15),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        Gap(context.responsive.value<double>(phone: 28, tablet: 32, kiosk: 36)),
        UserGrid(onUserSelected: onUserSelected),
      ],
    );
  }
}

class _EnterPinStep extends StatelessWidget {
  const _EnterPinStep({
    required this.user,
    required this.pin,
    required this.loginError,
    required this.selectedButton,
    required this.onNumberPressed,
    required this.onBackspace,
    required this.onConfirm,
    required this.onBack,
  });

  final LoginRosterItem user;
  final String pin;
  final String? loginError;
  final ValueNotifier<int?> selectedButton;
  final void Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: POSColors.textPrimary),
            ),
            Expanded(
              child: Text(
                'Hi, ${user.firstName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: POSColors.textPrimary,
                  fontSize: context.responsive.value<double>(phone: 22, tablet: 26, kiosk: 30),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your 6-digit PIN',
          style: TextStyle(
            color: POSColors.textTertiary,
            fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 15),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        Gap(context.responsive.value<double>(phone: 28, tablet: 32, kiosk: 36)),
        _PinSection(pin: pin),
        Gap(context.responsive.value<double>(phone: 24, tablet: 28, kiosk: 32)),
        PinPad(
          onNumberPressed: onNumberPressed,
          onBackspace: onBackspace,
          onConfirm: onConfirm,
          selectedButton: selectedButton,
        ),
        if (loginError != null) ...[
          Gap(context.responsive.value<double>(phone: 16, tablet: 18, kiosk: 20)),
          _ErrorBanner(message: loginError!),
        ],
        Gap(context.responsive.value<double>(phone: 16, tablet: 20, kiosk: 24)),
      ],
    );
  }
}

class _PinSection extends StatelessWidget {
  const _PinSection({required this.pin});

  final String pin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'PIN',
          style: TextStyle(
            fontSize: context.responsive.value<double>(phone: 11, tablet: 12, kiosk: 13),
            fontWeight: FontWeight.w600,
            color: POSColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        PinIndicator(pin: pin, color: ColorSet.primary),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: POSAnimation.normal,
      opacity: 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ColorSet.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(POSRadius.md),
          border: Border.all(color: ColorSet.danger.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ColorSet.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, color: ColorSet.danger, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: ColorSet.danger,
                  fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 15),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginLoadingDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(POSRadius.xl),
          boxShadow: POSShadow.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ColorSet.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: ColorSet.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Signing in...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: POSColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Notes on what changed from the previous version:
- `usernameController` and `usernameError` are gone; `onNumberPressed` no longer validates a username, only appends to the PIN.
- `attemptLogin()` now calls `ref.read(loginStateProvider.notifier).login(user.userId, pin.value)` using the selected tile's `userId` instead of typed text — `LoginStateNotifier.login()` itself (`kiosk/lib/features/auth/state/login_state_notifier.dart:17-24`) is unchanged.
- The `useEffect` that cleared `usernameError` on typing is removed along with the field it watched.

- [ ] **Step 2: Delete the now-unused username input widget**

```bash
git rm kiosk/lib/features/auth/view/username_input.dart
```

- [ ] **Step 3: Run analysis on the whole auth feature**

Run: `cd kiosk && fvm dart analyze lib/features/auth`
Expected: `No issues found!` (confirms no leftover reference to the deleted `UsernameInput` or the removed `isRequired` import usage).

- [ ] **Step 4: Manually verify the flow**

Run: `cd kiosk && fvm flutter run -d windows`

Confirm:
- Login screen shows a grid of active staff tiles (name + avatar/initials) instead of a username field.
- Tapping a tile moves to the PIN screen, showing "Hi, `<firstName>`".
- Entering a correct 6-digit PIN logs in as that user (same downstream behavior as before — PIN-changed dialog or navigation to the menu).
- Entering a wrong PIN shows the existing error banner and resets the PIN, staying on the same user's PIN screen.
- The back arrow on the PIN screen returns to the tile grid and clears the PIN.

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/features/auth/view/login_view.dart
git commit -m "feat: replace typed-username login with tile grid + PIN flow"
```

---

## Task 12: Full verification pass

- [ ] **Step 1: Backend full test suite**

Run: `cd be && npm run test`
Expected: no new failures beyond any pre-existing unrelated ones.

- [ ] **Step 2: Backend lint**

Run: `cd be && npm run lint`
Expected: completes; then run `git status` and confirm `lint --fix` did not reformat unrelated files (it reformats the whole repo, not just changed files — check before committing anything it touched).

- [ ] **Step 3: Kiosk full analysis**

Run: `cd kiosk && fvm dart analyze`
Expected: `No issues found!`

- [ ] **Step 4: Kiosk full test suite**

Run: `cd kiosk && fvm flutter test`
Expected: all tests pass, including the new `login_roster_notifier_test.dart`.

- [ ] **Step 5: Report status**

Summarize to the user: which tasks are complete, results of each verification command, and the manual verification outcome from Task 11 Step 4. Do not commit anything beyond what each task's own commit step already covers.
