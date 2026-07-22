# Mobile POS — Phase 1: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bootstrap the offline mobile POS app with a working database, theme, auth state, GoRouter, and AdaptiveShell — resulting in a launchable app that seeds a default admin, shows a PIN login screen, and navigates to a blank ordering screen after login.

**Architecture:** Independent Flutter app in `mobile/`. Drift/SQLite for all local data. Riverpod (manual providers, no code-gen) manages state. GoRouter 17 handles navigation with auth redirect. `AdaptiveShell` switches between tablet sidebar (≥720px) and phone bottom nav (<720px) using `LayoutBuilder`.

**Tech Stack:** Flutter 3.x, Drift 2.24, drift_flutter 0.2, hooks_riverpod 3.x, go_router 17.x, dart_mappable 4.x, bcrypt 1.x, shared_preferences 2.x

**Spec:** `docs/superpowers/specs/2026-07-22-mobile-pos-design.md`

---

## File Map

```
mobile/
├── pubspec.yaml                                         MODIFY
├── analysis_options.yaml                                MODIFY
├── lib/
│   ├── main.dart                                        REWRITE
│   ├── core/
│   │   ├── result/result.dart                           CREATE
│   │   ├── errors/app_error.dart                        CREATE
│   │   ├── theme/
│   │   │   ├── app_colors.dart                          CREATE
│   │   │   ├── app_spacing.dart                         CREATE
│   │   │   ├── app_text_styles.dart                     CREATE
│   │   │   └── app_theme.dart                           CREATE
│   │   ├── database/
│   │   │   ├── tables/users_table.dart                  CREATE
│   │   │   ├── tables/product_groups_table.dart         CREATE
│   │   │   ├── tables/products_table.dart               CREATE
│   │   │   ├── tables/modifier_groups_table.dart        CREATE
│   │   │   ├── tables/modifier_options_table.dart       CREATE
│   │   │   ├── tables/sales_table.dart                  CREATE
│   │   │   ├── tables/sale_items_table.dart             CREATE
│   │   │   ├── tables/sale_item_modifiers_table.dart    CREATE
│   │   │   ├── tables/payments_table.dart               CREATE
│   │   │   ├── tables/refunds_table.dart                CREATE
│   │   │   ├── tables/refund_items_table.dart           CREATE
│   │   │   ├── tables/store_info_table.dart             CREATE
│   │   │   ├── daos/users_dao.dart                      CREATE
│   │   │   ├── daos/products_dao.dart                   CREATE
│   │   │   ├── daos/sales_dao.dart                      CREATE
│   │   │   ├── daos/store_info_dao.dart                 CREATE
│   │   │   └── app_database.dart                        CREATE
│   │   └── seeder/admin_seeder.dart                     CREATE
│   ├── features/
│   │   └── auth/
│   │       ├── domain/
│   │       │   ├── entities/user.dart                   CREATE
│   │       │   └── repositories/auth_repository.dart    CREATE
│   │       ├── data/
│   │       │   ├── datasources/auth_local_datasource.dart CREATE
│   │       │   └── repositories/auth_repository_impl.dart CREATE
│   │       └── presentation/
│   │           ├── state/auth_notifier.dart              CREATE
│   │           └── view/login_screen.dart               CREATE
│   ├── navigation/router.dart                           CREATE
│   └── shared/
│       ├── shell/
│       │   ├── adaptive_shell.dart                      CREATE
│       │   ├── tablet_shell.dart                        CREATE
│       │   └── phone_shell.dart                         CREATE
│       ├── responsive/breakpoints.dart                  CREATE
│       └── widgets/
│           ├── error_state_widget.dart                  CREATE
│           └── empty_state_widget.dart                  CREATE
└── test/
    ├── core/
    │   ├── result/result_test.dart                      CREATE
    │   ├── database/users_dao_test.dart                 CREATE
    │   └── seeder/admin_seeder_test.dart                CREATE
    └── features/
        └── auth/auth_notifier_test.dart                 CREATE
```

---

## Task 1: pubspec.yaml — Add All Dependencies

**Files:** Modify `mobile/pubspec.yaml`

- [ ] **Step 1: Replace pubspec.yaml content**

```yaml
name: mobile
description: Offline mobile POS application
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.7.2

dependencies:
  flutter:
    sdk: flutter

  # Database
  drift: ^2.24.0
  drift_flutter: ^0.2.4

  # State management
  hooks_riverpod: ^3.1.0
  flutter_hooks: ^0.21.3

  # Navigation
  go_router: ^17.0.1

  # Models
  dart_mappable: ^4.6.1

  # Auth / Security
  bcrypt: ^1.1.3
  shared_preferences: ^2.5.4

  # CSV
  csv: ^6.0.0
  file_picker: ^8.1.2

  # Printing
  esc_pos_utils_plus: ^2.0.4
  print_bluetooth_thermal: ^1.0.0
  pdf: ^3.11.0
  printing: ^5.13.2
  share_plus: ^10.0.0

  # Charts
  fl_chart: ^0.69.2

  # UI
  cached_network_image: ^3.4.1
  flutter_svg: ^2.2.3
  gap: ^3.0.1
  cupertino_icons: ^1.0.8

  # Utils
  intl: any
  collection: ^1.19.1
  decimal: ^3.2.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  drift_dev: ^2.24.0
  build_runner: ^2.4.12
  dart_mappable_builder: ^4.6.3

flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/images/
    - assets/fonts/
```

- [ ] **Step 2: Create asset directories**

```bash
mkdir -p mobile/assets/images mobile/assets/fonts
touch mobile/assets/images/.gitkeep mobile/assets/fonts/.gitkeep
```

- [ ] **Step 3: Install dependencies**

```bash
cd mobile && flutter pub get
```

Expected: resolves without errors. If version conflicts occur, run `flutter pub upgrade` and update pinned versions.

---

## Task 2: Core — Result Type

**Files:** Create `mobile/lib/core/result/result.dart`, `mobile/test/core/result/result_test.dart`

- [ ] **Step 1: Write the failing test**

Create `mobile/test/core/result/result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/result/result.dart';

void main() {
  group('Result', () {
    test('Success holds value', () {
      const result = Success<int, String>(42);
      expect(result.isSuccess, isTrue);
      expect(result.value, 42);
    });

    test('Failure holds error', () {
      const result = Failure<int, String>('oops');
      expect(result.isFailure, isTrue);
      expect(result.error, 'oops');
    });

    test('fold calls onSuccess for Success', () {
      const result = Success<int, String>(10);
      final out = result.fold(onSuccess: (v) => 'yes $v', onFailure: (e) => 'no');
      expect(out, 'yes 10');
    });

    test('fold calls onFailure for Failure', () {
      const result = Failure<int, String>('bad');
      final out = result.fold(onSuccess: (v) => 'yes', onFailure: (e) => 'no $e');
      expect(out, 'no bad');
    });
  });
}
```

- [ ] **Step 2: Run test to see it fail**

```bash
cd mobile && flutter test test/core/result/result_test.dart
```

Expected: compilation error (file not found).

- [ ] **Step 3: Create `mobile/lib/core/result/result.dart`**

```dart
sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T get value => (this as Success<T, E>).value;
  E get error => (this as Failure<T, E>).error;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onFailure,
  }) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Failure(:final error) => onFailure(error),
      };
}

final class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

final class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}
```

- [ ] **Step 4: Run test to see it pass**

```bash
cd mobile && flutter test test/core/result/result_test.dart
```

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/core/result/result.dart test/core/result/result_test.dart
git commit -m "feat(mobile): add Result sealed type"
```

---

## Task 3: Core — AppError

**Files:** Create `mobile/lib/core/errors/app_error.dart`

- [ ] **Step 1: Create `mobile/lib/core/errors/app_error.dart`**

```dart
sealed class AppError {
  final String message;
  const AppError(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

final class DatabaseError extends AppError {
  const DatabaseError(super.message);
}

final class ValidationError extends AppError {
  final Map<String, String> fieldErrors;
  const ValidationError(super.message, {this.fieldErrors = const {}});
}

final class NotFoundError extends AppError {
  const NotFoundError(super.message);
}

final class CsvParseError extends AppError {
  final int? rowIndex;
  const CsvParseError(super.message, {this.rowIndex});
}

final class PrintError extends AppError {
  const PrintError(super.message);
}
```

- [ ] **Step 2: Commit**

```bash
cd mobile && git add lib/core/errors/app_error.dart
git commit -m "feat(mobile): add AppError sealed types"
```

---

## Task 4: Core — Theme & Design System

**Files:** Create `mobile/lib/core/theme/app_colors.dart`, `app_spacing.dart`, `app_text_styles.dart`, `app_theme.dart`

- [ ] **Step 1: Create `mobile/lib/core/theme/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF1B7A8C);
  static const primaryLight = Color(0xFF2A9BB0);
  static const primaryDark = Color(0xFF135E6B);

  static const secondary = Color(0xFFBCBE68);
  static const secondaryLight = Color(0xFFD0D27E);
  static const secondaryDark = Color(0xFF9A9C50);

  // Backgrounds
  static const background = Color(0xFFF3F1ED);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEFEDE9);

  // Text
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textDisabled = Color(0xFFB0B0B0);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const error = Color(0xFFC62828);
  static const errorLight = Color(0xFFFFEBEE);
  static const warning = Color(0xFFE65100);
  static const warningLight = Color(0xFFFFF3E0);

  // UI
  static const divider = Color(0xFFE0DDD8);
  static const border = Color(0xFFD4D1CC);
  static const shadow = Color(0x1A000000);
  static const overlay = Color(0x80000000);
}
```

- [ ] **Step 2: Create `mobile/lib/core/theme/app_spacing.dart`**

```dart
abstract final class AppSpacing {
  // 8px base grid
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Touch targets
  static const double touchMin = 48;
  static const double touchPreferred = 64;

  // Border radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // Card
  static const double cardPadding = 16;
  static const double cardRadius = 16;

  // Page padding
  static const double pagePaddingH = 24;
  static const double pagePaddingV = 24;
}
```

- [ ] **Step 3: Create `mobile/lib/core/theme/app_text_styles.dart`**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const _base = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static final displayLg = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);
  static final displayMd = _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2);
  static final headingLg = _base.copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3);
  static final headingMd = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);
  static final headingSm = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);
  static final bodyLg = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static final bodyMd = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static final bodySm = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);
  static final labelLg = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.1);
  static final labelMd = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.5);
  static final priceLg = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2);
  static final priceMd = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2);
}
```

- [ ] **Step 4: Create `mobile/lib/core/theme/app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shadowColor: AppColors.shadow,
        titleTextStyle: AppTextStyles.headingMd,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(0, AppSpacing.touchPreferred),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: AppTextStyles.labelLg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, AppSpacing.touchPreferred),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: AppTextStyles.labelLg,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        space: 0,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLg,
        displayMedium: AppTextStyles.displayMd,
        headlineLarge: AppTextStyles.headingLg,
        headlineMedium: AppTextStyles.headingMd,
        headlineSmall: AppTextStyles.headingSm,
        bodyLarge: AppTextStyles.bodyLg,
        bodyMedium: AppTextStyles.bodyMd,
        bodySmall: AppTextStyles.bodySm,
        labelLarge: AppTextStyles.labelLg,
        labelMedium: AppTextStyles.labelMd,
      ),
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/core/theme/
git commit -m "feat(mobile): add design system — colors, spacing, text styles, theme"
```

---

## Task 5: Database — Drift Tables

**Files:** Create all 12 table files under `mobile/lib/core/database/tables/`

- [ ] **Step 1: Create `mobile/lib/core/database/tables/users_table.dart`**

```dart
import 'package:drift/drift.dart';

class UsersTable extends Table {
  @override
  String get tableName => 'users';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get role => text()(); // 'admin' | 'cashier'
  TextColumn get pinHash => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
```

- [ ] **Step 2: Create `mobile/lib/core/database/tables/product_groups_table.dart`**

```dart
import 'package:drift/drift.dart';

class ProductGroupsTable extends Table {
  @override
  String get tableName => 'product_groups';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
```

- [ ] **Step 3: Create `mobile/lib/core/database/tables/products_table.dart`**

```dart
import 'package:drift/drift.dart';
import 'product_groups_table.dart';

class ProductsTable extends Table {
  @override
  String get tableName => 'products';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(ProductGroupsTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  RealColumn get price => real()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
```

- [ ] **Step 4: Create `mobile/lib/core/database/tables/modifier_groups_table.dart`**

```dart
import 'package:drift/drift.dart';
import 'products_table.dart';

class ModifierGroupsTable extends Table {
  @override
  String get tableName => 'modifier_groups';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(ProductsTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  IntColumn get maxSelections => integer().withDefault(const Constant(1))();
}
```

- [ ] **Step 5: Create `mobile/lib/core/database/tables/modifier_options_table.dart`**

```dart
import 'package:drift/drift.dart';
import 'modifier_groups_table.dart';

class ModifierOptionsTable extends Table {
  @override
  String get tableName => 'modifier_options';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(ModifierGroupsTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get additionalPrice => real().withDefault(const Constant(0.0))();
}
```

- [ ] **Step 6: Create `mobile/lib/core/database/tables/sales_table.dart`**

```dart
import 'package:drift/drift.dart';
import 'users_table.dart';

class SalesTable extends Table {
  @override
  String get tableName => 'sales';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get cashierId => integer().references(UsersTable, #id)();
  RealColumn get total => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  TextColumn get status => text()(); // 'completed' | 'voided' | 'refunded'
  TextColumn get type => text()(); // 'dine_in' | 'take_out' | 'delivery'
  DateTimeColumn get createdAt => dateTime()();
}
```

- [ ] **Step 7: Create `mobile/lib/core/database/tables/sale_items_table.dart`**

```dart
import 'package:drift/drift.dart';
import 'sales_table.dart';
import 'products_table.dart';

class SaleItemsTable extends Table {
  @override
  String get tableName => 'sale_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(SalesTable, #id)();
  IntColumn get productId => integer().references(ProductsTable, #id)();
  TextColumn get variantName => text()();
  IntColumn get qty => integer()();
  RealColumn get unitPrice => real()();
}
```

- [ ] **Step 8: Create `mobile/lib/core/database/tables/sale_item_modifiers_table.dart`**

```dart
import 'package:drift/drift.dart';
import 'sale_items_table.dart';

class SaleItemModifiersTable extends Table {
  @override
  String get tableName => 'sale_item_modifiers';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(SaleItemsTable, #id)();
  TextColumn get modifierName => text()();
  RealColumn get additionalPrice => real().withDefault(const Constant(0.0))();
}
```

- [ ] **Step 9: Create `mobile/lib/core/database/tables/payments_table.dart`**

```dart
import 'package:drift/drift.dart';
import 'sales_table.dart';

class PaymentsTable extends Table {
  @override
  String get tableName => 'payments';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(SalesTable, #id)();
  TextColumn get method => text()(); // 'cash' | 'card' | 'reference'
  RealColumn get amount => real()();
  TextColumn get reference => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
```

- [ ] **Step 10: Create `mobile/lib/core/database/tables/refunds_table.dart`**

```dart
import 'package:drift/drift.dart';
import 'sales_table.dart';

class RefundsTable extends Table {
  @override
  String get tableName => 'refunds';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(SalesTable, #id)();
  TextColumn get reason => text()();
  RealColumn get total => real()();
  DateTimeColumn get createdAt => dateTime()();
}
```

- [ ] **Step 11: Create `mobile/lib/core/database/tables/refund_items_table.dart`**

```dart
import 'package:drift/drift.dart';
import 'refunds_table.dart';
import 'sale_items_table.dart';

class RefundItemsTable extends Table {
  @override
  String get tableName => 'refund_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get refundId => integer().references(RefundsTable, #id)();
  IntColumn get saleItemId => integer().references(SaleItemsTable, #id)();
  IntColumn get qty => integer()();
  RealColumn get amount => real()();
}
```

- [ ] **Step 12: Create `mobile/lib/core/database/tables/store_info_table.dart`**

```dart
import 'package:drift/drift.dart';

class StoreInfoTable extends Table {
  @override
  String get tableName => 'store_info';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get storeName => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('PHP'))();
  TextColumn get receiptFooter => text().withDefault(const Constant(''))();
}
```

- [ ] **Step 13: Commit**

```bash
cd mobile && git add lib/core/database/tables/
git commit -m "feat(mobile): add all Drift table definitions"
```

---

## Task 6: Database — DAOs

**Files:** Create 4 DAO files under `mobile/lib/core/database/daos/`

- [ ] **Step 1: Create `mobile/lib/core/database/daos/users_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/users_table.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [UsersTable])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<List<UsersTableData>> getAllActiveUsers() =>
      (select(usersTable)..where((t) => t.isActive.equals(true))).get();

  Future<UsersTableData?> getUserById(int id) =>
      (select(usersTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<bool> hasAdmin() async {
    final result = await (select(usersTable)
          ..where((t) => t.role.equals('admin'))
          ..where((t) => t.isActive.equals(true)))
        .get();
    return result.isNotEmpty;
  }

  Future<int> insertUser(UsersTableCompanion companion) =>
      into(usersTable).insert(companion);

  Future<bool> updateUser(UsersTableCompanion companion) =>
      update(usersTable).replace(companion);

  Future<int> deactivateUser(int id) => (update(usersTable)
        ..where((t) => t.id.equals(id)))
      .write(const UsersTableCompanion(isActive: Value(false)));

  Future<int> updatePinHash(int userId, String newPinHash) =>
      (update(usersTable)..where((t) => t.id.equals(userId)))
          .write(UsersTableCompanion(pinHash: Value(newPinHash)));
}
```

- [ ] **Step 2: Create `mobile/lib/core/database/daos/products_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/product_groups_table.dart';
import '../tables/products_table.dart';
import '../tables/modifier_groups_table.dart';
import '../tables/modifier_options_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [
  ProductGroupsTable,
  ProductsTable,
  ModifierGroupsTable,
  ModifierOptionsTable,
])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Future<List<ProductGroupsTableData>> getAllActiveGroups() =>
      (select(productGroupsTable)
            ..where((t) => t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<List<ProductsTableData>> getProductsByGroup(int groupId) =>
      (select(productsTable)
            ..where((t) => t.groupId.equals(groupId))
            ..where((t) => t.isAvailable.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<List<ProductsTableData>> getAllProducts() =>
      (select(productsTable)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<ProductsTableData?> getProductById(int id) =>
      (select(productsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ModifierGroupsTableData>> getModifierGroupsForProduct(int productId) =>
      (select(modifierGroupsTable)
            ..where((t) => t.productId.equals(productId)))
          .get();

  Future<List<ModifierOptionsTableData>> getOptionsForGroup(int groupId) =>
      (select(modifierOptionsTable)
            ..where((t) => t.groupId.equals(groupId)))
          .get();

  Future<int> insertProductGroup(ProductGroupsTableCompanion companion) =>
      into(productGroupsTable).insert(companion);

  Future<int> insertProduct(ProductsTableCompanion companion) =>
      into(productsTable).insert(companion);

  Future<int> insertModifierGroup(ModifierGroupsTableCompanion companion) =>
      into(modifierGroupsTable).insert(companion);

  Future<int> insertModifierOption(ModifierOptionsTableCompanion companion) =>
      into(modifierOptionsTable).insert(companion);

  Future<int> upsertProductGroup(ProductGroupsTableCompanion companion) =>
      into(productGroupsTable).insertOnConflictUpdate(companion);

  Future<int> upsertProduct(ProductsTableCompanion companion) =>
      into(productsTable).insertOnConflictUpdate(companion);

  Future<int> toggleProductAvailability(int productId, {required bool isAvailable}) =>
      (update(productsTable)..where((t) => t.id.equals(productId)))
          .write(ProductsTableCompanion(isAvailable: Value(isAvailable)));
}
```

- [ ] **Step 3: Create `mobile/lib/core/database/daos/sales_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sales_table.dart';
import '../tables/sale_items_table.dart';
import '../tables/sale_item_modifiers_table.dart';
import '../tables/payments_table.dart';
import '../tables/refunds_table.dart';
import '../tables/refund_items_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [
  SalesTable,
  SaleItemsTable,
  SaleItemModifiersTable,
  PaymentsTable,
  RefundsTable,
  RefundItemsTable,
])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  Future<int> insertSale(SalesTableCompanion companion) =>
      into(salesTable).insert(companion);

  Future<int> insertSaleItem(SaleItemsTableCompanion companion) =>
      into(saleItemsTable).insert(companion);

  Future<int> insertSaleItemModifier(SaleItemModifiersTableCompanion companion) =>
      into(saleItemModifiersTable).insert(companion);

  Future<int> insertPayment(PaymentsTableCompanion companion) =>
      into(paymentsTable).insert(companion);

  Future<int> insertRefund(RefundsTableCompanion companion) =>
      into(refundsTable).insert(companion);

  Future<int> insertRefundItem(RefundItemsTableCompanion companion) =>
      into(refundItemsTable).insert(companion);

  Future<int> voidSale(int saleId) =>
      (update(salesTable)..where((t) => t.id.equals(saleId)))
          .write(const SalesTableCompanion(status: Value('voided')));

  Future<List<SalesTableData>> getSalesByDateRange(
    DateTime from,
    DateTime to,
  ) =>
      (select(salesTable)
            ..where((t) => t.createdAt.isBetweenValues(from, to))
            ..where((t) => t.status.equals('completed'))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<SalesTableData?> getSaleById(int id) =>
      (select(salesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<SaleItemsTableData>> getItemsForSale(int saleId) =>
      (select(saleItemsTable)..where((t) => t.saleId.equals(saleId))).get();

  Future<List<PaymentsTableData>> getPaymentsForSale(int saleId) =>
      (select(paymentsTable)..where((t) => t.saleId.equals(saleId))).get();

  Future<List<SalesTableData>> getRecentSales({int limit = 50}) =>
      (select(salesTable)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  Future<double> getTotalSalesForDateRange(DateTime from, DateTime to) async {
    final query = customSelect(
      'SELECT COALESCE(SUM(total), 0) as sum FROM sales '
      'WHERE created_at BETWEEN ? AND ? AND status = ?',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable},
    );
    final result = await query.getSingle();
    return result.read<double>('sum');
  }
}
```

- [ ] **Step 4: Create `mobile/lib/core/database/daos/store_info_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/store_info_table.dart';

part 'store_info_dao.g.dart';

@DriftAccessor(tables: [StoreInfoTable])
class StoreInfoDao extends DatabaseAccessor<AppDatabase> with _$StoreInfoDaoMixin {
  StoreInfoDao(super.db);

  Future<StoreInfoTableData?> getStoreInfo() =>
      (select(storeInfoTable)..limit(1)).getSingleOrNull();

  Future<int> upsertStoreInfo(StoreInfoTableCompanion companion) =>
      into(storeInfoTable).insertOnConflictUpdate(companion);

  Future<void> ensureStoreInfoExists() async {
    final existing = await getStoreInfo();
    if (existing == null) {
      await into(storeInfoTable).insert(const StoreInfoTableCompanion());
    }
  }
}
```

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/core/database/daos/
git commit -m "feat(mobile): add Drift DAOs for users, products, sales, store_info"
```

---

## Task 7: Database — AppDatabase + Code Generation

**Files:** Create `mobile/lib/core/database/app_database.dart`, then run build_runner.

- [ ] **Step 1: Create `mobile/lib/core/database/app_database.dart`**

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/users_table.dart';
import 'tables/product_groups_table.dart';
import 'tables/products_table.dart';
import 'tables/modifier_groups_table.dart';
import 'tables/modifier_options_table.dart';
import 'tables/sales_table.dart';
import 'tables/sale_items_table.dart';
import 'tables/sale_item_modifiers_table.dart';
import 'tables/payments_table.dart';
import 'tables/refunds_table.dart';
import 'tables/refund_items_table.dart';
import 'tables/store_info_table.dart';
import 'daos/users_dao.dart';
import 'daos/products_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/store_info_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    UsersTable,
    ProductGroupsTable,
    ProductsTable,
    ModifierGroupsTable,
    ModifierOptionsTable,
    SalesTable,
    SaleItemsTable,
    SaleItemModifiersTable,
    PaymentsTable,
    RefundsTable,
    RefundItemsTable,
    StoreInfoTable,
  ],
  daos: [UsersDao, ProductsDao, SalesDao, StoreInfoDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'mobile_pos'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await storeInfoDao.ensureStoreInfoExists();
        },
      );
}
```

- [ ] **Step 2: Run code generation**

```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `app_database.g.dart`, `users_dao.g.dart`, `products_dao.g.dart`, `sales_dao.g.dart`, `store_info_dao.g.dart`. No errors.

- [ ] **Step 3: Write DAO test**

Create `mobile/test/core/database/users_dao_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  group('UsersDao', () {
    test('hasAdmin returns false when no admin exists', () async {
      final result = await db.usersDao.hasAdmin();
      expect(result, isFalse);
    });

    test('insertUser and getAllActiveUsers', () async {
      await db.usersDao.insertUser(const UsersTableCompanion(
        name: Value('Alice'),
        role: Value('cashier'),
        pinHash: Value('hash'),
      ));
      final users = await db.usersDao.getAllActiveUsers();
      expect(users.length, 1);
      expect(users.first.name, 'Alice');
    });

    test('hasAdmin returns true after admin inserted', () async {
      await db.usersDao.insertUser(const UsersTableCompanion(
        name: Value('Admin'),
        role: Value('admin'),
        pinHash: Value('hash'),
      ));
      final result = await db.usersDao.hasAdmin();
      expect(result, isTrue);
    });

    test('deactivateUser removes from active list', () async {
      final id = await db.usersDao.insertUser(const UsersTableCompanion(
        name: Value('Bob'),
        role: Value('cashier'),
        pinHash: Value('hash'),
      ));
      await db.usersDao.deactivateUser(id);
      final users = await db.usersDao.getAllActiveUsers();
      expect(users.where((u) => u.id == id), isEmpty);
    });
  });
}
```

- [ ] **Step 4: Run the DAO test**

```bash
cd mobile && flutter test test/core/database/users_dao_test.dart
```

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/core/database/ test/core/database/
git commit -m "feat(mobile): add AppDatabase, DAOs, and generated Drift files"
```

---

## Task 8: Admin Seeder

**Files:** Create `mobile/lib/core/seeder/admin_seeder.dart`, `mobile/test/core/seeder/admin_seeder_test.dart`

- [ ] **Step 1: Write failing test**

Create `mobile/test/core/seeder/admin_seeder_test.dart`:

```dart
import 'package:bcrypt/bcrypt.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/seeder/admin_seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase db;
  late AdminSeeder seeder;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    seeder = AdminSeeder(usersDao: db.usersDao, prefs: prefs);
  });

  tearDown(() async => db.close());

  test('seed creates default admin when no admin exists', () async {
    await seeder.seed();
    final hasAdmin = await db.usersDao.hasAdmin();
    expect(hasAdmin, isTrue);
  });

  test('default admin has name Admin and role admin', () async {
    await seeder.seed();
    final users = await db.usersDao.getAllActiveUsers();
    final admin = users.firstWhere((u) => u.role == 'admin');
    expect(admin.name, 'Admin');
  });

  test('default admin PIN hash matches 000000', () async {
    await seeder.seed();
    final users = await db.usersDao.getAllActiveUsers();
    final admin = users.firstWhere((u) => u.role == 'admin');
    expect(BCrypt.checkpw('000000', admin.pinHash), isTrue);
  });

  test('seed does not create duplicate admin on second call', () async {
    await seeder.seed();
    await seeder.seed();
    final users = await db.usersDao.getAllActiveUsers();
    final admins = users.where((u) => u.role == 'admin');
    expect(admins.length, 1);
  });
}
```

- [ ] **Step 2: Run test to see it fail**

```bash
cd mobile && flutter test test/core/seeder/admin_seeder_test.dart
```

Expected: compilation error (AdminSeeder not found).

- [ ] **Step 3: Create `mobile/lib/core/seeder/admin_seeder.dart`**

```dart
import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/daos/users_dao.dart';
import '../database/tables/users_table.dart';

const _seedKey = 'admin_seeded';
const _defaultPin = '000000';

class AdminSeeder {
  final UsersDao _usersDao;
  final SharedPreferences _prefs;

  const AdminSeeder({required UsersDao usersDao, required SharedPreferences prefs})
      : _usersDao = usersDao,
        _prefs = prefs;

  Future<void> seed() async {
    final alreadySeeded = _prefs.getBool(_seedKey) ?? false;
    if (alreadySeeded) return;

    final hasAdmin = await _usersDao.hasAdmin();
    if (!hasAdmin) {
      final pinHash = BCrypt.hashpw(_defaultPin, BCrypt.gensalt());
      await _usersDao.insertUser(
        UsersTableCompanion.insert(
          name: 'Admin',
          role: 'admin',
          pinHash: pinHash,
        ),
      );
    }

    await _prefs.setBool(_seedKey, true);
  }
}
```

- [ ] **Step 4: Run test to see it pass**

```bash
cd mobile && flutter test test/core/seeder/admin_seeder_test.dart
```

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/core/seeder/ test/core/seeder/
git commit -m "feat(mobile): add AdminSeeder with default PIN 000000"
```

---

## Task 9: Auth Domain + Notifier

**Files:** Create auth entity, repository, use case, and notifier.

- [ ] **Step 1: Create `mobile/lib/features/auth/domain/entities/user.dart`**

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'user.mapper.dart';

enum UserRole { admin, cashier }

@MappableClass()
class User with UserMappable {
  final int id;
  final String name;
  final UserRole role;
  final String pinHash;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.role,
    required this.pinHash,
    required this.isActive,
  });

  bool get isAdmin => role == UserRole.admin;
}
```

- [ ] **Step 2: Run build_runner to generate user.mapper.dart**

```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs
```

Expected: `user.mapper.dart` generated.

- [ ] **Step 3: Create `mobile/lib/features/auth/domain/repositories/auth_repository.dart`**

```dart
import '../../../../core/errors/app_error.dart';
import '../../../../core/result/result.dart';
import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<List<User>> getActiveUsers();
  Future<Result<User, AppError>> verifyPin(int userId, String pin);
  Future<Result<void, AppError>> changePin(int userId, String oldPin, String newPin);
  Future<Result<void, AppError>> resetPin(int userId, String newPin);
}
```

- [ ] **Step 4: Create `mobile/lib/features/auth/data/datasources/auth_local_datasource.dart`**

```dart
import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/users_table.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/user.dart';

class AuthLocalDatasource {
  final AppDatabase _db;

  const AuthLocalDatasource(this._db);

  Future<List<User>> getActiveUsers() async {
    final rows = await _db.usersDao.getAllActiveUsers();
    return rows.map(_rowToUser).toList();
  }

  Future<Result<User, AppError>> verifyPin(int userId, String pin) async {
    try {
      final row = await _db.usersDao.getUserById(userId);
      if (row == null) return const Failure(NotFoundError('User not found'));
      if (!row.isActive) return const Failure(ValidationError('User is inactive'));
      if (!BCrypt.checkpw(pin, row.pinHash)) {
        return const Failure(ValidationError('Invalid PIN'));
      }
      return Success(_rowToUser(row));
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  Future<Result<void, AppError>> changePin(
      int userId, String oldPin, String newPin) async {
    try {
      final row = await _db.usersDao.getUserById(userId);
      if (row == null) return const Failure(NotFoundError('User not found'));
      if (!BCrypt.checkpw(oldPin, row.pinHash)) {
        return const Failure(ValidationError('Current PIN is incorrect'));
      }
      final newHash = BCrypt.hashpw(newPin, BCrypt.gensalt());
      await _db.usersDao.updatePinHash(userId, newHash);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  Future<Result<void, AppError>> resetPin(int userId, String newPin) async {
    try {
      final newHash = BCrypt.hashpw(newPin, BCrypt.gensalt());
      await _db.usersDao.updatePinHash(userId, newHash);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  User _rowToUser(UsersTableData row) => User(
        id: row.id,
        name: row.name,
        role: row.role == 'admin' ? UserRole.admin : UserRole.cashier,
        pinHash: row.pinHash,
        isActive: row.isActive,
      );
}
```

- [ ] **Step 5: Create `mobile/lib/features/auth/data/repositories/auth_repository_impl.dart`**

```dart
import '../../../../core/errors/app_error.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDatasource _datasource;

  const AuthRepositoryImpl(this._datasource);

  @override
  Future<List<User>> getActiveUsers() => _datasource.getActiveUsers();

  @override
  Future<Result<User, AppError>> verifyPin(int userId, String pin) =>
      _datasource.verifyPin(userId, pin);

  @override
  Future<Result<void, AppError>> changePin(int userId, String oldPin, String newPin) =>
      _datasource.changePin(userId, oldPin, newPin);

  @override
  Future<Result<void, AppError>> resetPin(int userId, String newPin) =>
      _datasource.resetPin(userId, newPin);
}
```

- [ ] **Step 6: Create `mobile/lib/features/auth/presentation/state/auth_notifier.dart`**

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/result/result.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

// Providers
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AuthRepositoryImpl(AuthLocalDatasource(db));
});

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

// Notifier
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<List<User>> getActiveUsers() => _repo.getActiveUsers();

  Future<Result<User, AppError>> login(int userId, String pin) async {
    state = const AsyncLoading();
    final result = await _repo.verifyPin(userId, pin);
    result.fold(
      onSuccess: (user) => state = AsyncData(user),
      onFailure: (_) => state = const AsyncData(null),
    );
    return result;
  }

  void logout() => state = const AsyncData(null);

  Future<Result<void, AppError>> changePin(
      String oldPin, String newPin) async {
    final user = state.valueOrNull;
    if (user == null) return const Failure(NotFoundError('Not logged in'));
    return _repo.changePin(user.id, oldPin, newPin);
  }
}
```

- [ ] **Step 7: Write AuthNotifier test**

Create `mobile/test/features/auth/auth_notifier_test.dart`:

```dart
import 'package:bcrypt/bcrypt.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/result/result.dart';
import 'package:mobile/features/auth/presentation/state/auth_notifier.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int userId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final pinHash = BCrypt.hashpw('123456', BCrypt.gensalt());
    userId = await db.usersDao.insertUser(UsersTableCompanion.insert(
      name: Value('Alice'),
      role: Value('cashier'),
      pinHash: Value(pinHash),
    ));
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('initial state is null (not logged in)', () {
    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });

  test('login with correct PIN sets user', () async {
    final result = await container
        .read(authNotifierProvider.notifier)
        .login(userId, '123456');
    expect(result.isSuccess, isTrue);
    expect(container.read(authNotifierProvider).valueOrNull?.name, 'Alice');
  });

  test('login with wrong PIN returns failure and clears state', () async {
    final result = await container
        .read(authNotifierProvider.notifier)
        .login(userId, '000000');
    expect(result.isFailure, isTrue);
    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });

  test('logout clears state', () async {
    await container.read(authNotifierProvider.notifier).login(userId, '123456');
    container.read(authNotifierProvider.notifier).logout();
    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });
}
```

- [ ] **Step 8: Run auth tests**

```bash
cd mobile && flutter test test/features/auth/auth_notifier_test.dart
```

Expected: All 4 tests pass.

- [ ] **Step 9: Commit**

```bash
cd mobile && git add lib/features/auth/ test/features/auth/
git commit -m "feat(mobile): add auth domain, datasource, repository, and AuthNotifier"
```

---

## Task 10: Shared Widgets

**Files:** Create `mobile/lib/shared/responsive/breakpoints.dart`, `error_state_widget.dart`, `empty_state_widget.dart`

- [ ] **Step 1: Create `mobile/lib/shared/responsive/breakpoints.dart`**

```dart
abstract final class Breakpoints {
  static const double tablet = 720;
  static const double desktop = 1200;
}

extension BreakpointContext on double {
  bool get isTablet => this >= Breakpoints.tablet;
  bool get isPhone => this < Breakpoints.tablet;
}
```

- [ ] **Step 2: Create `mobile/lib/shared/widgets/error_state_widget.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    required this.message,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.error),
            const Gap(AppSpacing.md),
            Text(
              'Something went wrong',
              style: AppTextStyles.headingMd,
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const Gap(AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `mobile/lib/shared/widgets/empty_state_widget.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.textDisabled),
            const Gap(AppSpacing.md),
            Text(title,
                style: AppTextStyles.headingMd, textAlign: TextAlign.center),
            const Gap(AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const Gap(AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
cd mobile && git add lib/shared/
git commit -m "feat(mobile): add shared widgets, breakpoints, responsive utils"
```

---

## Task 11: Adaptive Shell

**Files:** Create `adaptive_shell.dart`, `tablet_shell.dart`, `phone_shell.dart`

- [ ] **Step 1: Create `mobile/lib/shared/shell/adaptive_shell.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../responsive/breakpoints.dart';
import 'tablet_shell.dart';
import 'phone_shell.dart';

class AdaptiveShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdaptiveShell({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth.isTablet) {
          return TabletShell(navigationShell: navigationShell);
        }
        return PhoneShell(navigationShell: navigationShell);
      },
    );
  }
}
```

- [ ] **Step 2: Create `mobile/lib/shared/shell/tablet_shell.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'shell_nav_items.dart';

class TabletShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TabletShell({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(navigationShell: navigationShell),
          const VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _Sidebar({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('POS', style: AppTextStyles.headingLg.copyWith(color: AppColors.primary)),
            ),
            const Gap(AppSpacing.lg),
            Expanded(
              child: ListView.builder(
                itemCount: shellNavItems.length,
                itemBuilder: (context, index) {
                  final item = shellNavItems[index];
                  final selected = navigationShell.currentIndex == index;
                  return _SidebarItem(
                    item: item,
                    selected: selected,
                    onTap: () => navigationShell.goBranch(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final ShellNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const Gap(AppSpacing.md),
            Text(
              item.label,
              style: AppTextStyles.labelLg.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `mobile/lib/shared/shell/phone_shell.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'shell_nav_items.dart';

class PhoneShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const PhoneShell({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: shellNavItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon, color: AppColors.textSecondary),
                  selectedIcon: Icon(item.activeIcon, color: AppColors.primary),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}
```

- [ ] **Step 4: Create `mobile/lib/shared/shell/shell_nav_items.dart`**

```dart
import 'package:flutter/material.dart';

class ShellNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const ShellNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

const shellNavItems = [
  ShellNavItem(
    label: 'Orders',
    icon: Icons.point_of_sale_outlined,
    activeIcon: Icons.point_of_sale,
  ),
  ShellNavItem(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart,
  ),
  ShellNavItem(
    label: 'Catalog',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
  ),
  ShellNavItem(
    label: 'Users',
    icon: Icons.people_outlined,
    activeIcon: Icons.people,
  ),
  ShellNavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
  ),
];
```

- [ ] **Step 5: Widget test for AdaptiveShell**

Create `mobile/test/shared/shell/adaptive_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/shared/shell/adaptive_shell.dart';
import 'package:mobile/shared/shell/tablet_shell.dart';
import 'package:mobile/shared/shell/phone_shell.dart';

// Minimal stub shell for testing
class _StubShell extends StatefulNavigationShell {
  const _StubShell() : super(key: const ValueKey('stub'));
  @override
  int get currentIndex => 0;
  @override
  void goBranch(int index, {bool initialLocation = false}) {}
  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

> **Note:** `StatefulNavigationShell` cannot be directly stubbed in unit tests. Skip the widget test for AdaptiveShell and rely on manual testing by running the app on phone and tablet screen sizes. Mark this test as a known gap in test coverage.

- [ ] **Step 6: Commit**

```bash
cd mobile && git add lib/shared/shell/
git commit -m "feat(mobile): add AdaptiveShell, TabletShell, PhoneShell"
```

---

## Task 12: GoRouter

**Files:** Create `mobile/lib/navigation/router.dart` and stub screens for all routes.

- [ ] **Step 1: Create stub screens for all routes**

Create `mobile/lib/features/ordering/presentation/view/ordering_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

class OrderingScreen extends StatelessWidget {
  const OrderingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyStateWidget(
        icon: Icons.point_of_sale,
        title: 'No products yet',
        message: 'Import products via Settings → CSV Import',
      ),
    );
  }
}
```

Create `mobile/lib/features/reports/presentation/view/reports_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyStateWidget(
        icon: Icons.bar_chart,
        title: 'No sales data',
        message: 'Complete sales to see reports here',
      ),
    );
  }
}
```

Create `mobile/lib/features/catalog/presentation/view/catalog_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyStateWidget(
        icon: Icons.inventory_2,
        title: 'No products',
        message: 'Import products via Settings → CSV Import',
      ),
    );
  }
}
```

Create `mobile/lib/features/users/presentation/view/users_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyStateWidget(
        icon: Icons.people,
        title: 'No users',
        message: 'Add users or import via CSV',
      ),
    );
  }
}
```

Create `mobile/lib/features/settings/presentation/view/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings — coming soon')),
    );
  }
}
```

- [ ] **Step 2: Create `mobile/lib/navigation/router.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/auth/presentation/state/auth_notifier.dart';
import '../features/auth/presentation/view/login_screen.dart';
import '../features/ordering/presentation/view/ordering_screen.dart';
import '../features/reports/presentation/view/reports_screen.dart';
import '../features/catalog/presentation/view/catalog_screen.dart';
import '../features/users/presentation/view/users_screen.dart';
import '../features/settings/presentation/view/settings_screen.dart';
import '../shared/shell/adaptive_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthListenable(ref);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final user = ref.read(authNotifierProvider).valueOrNull;
      final isLoggedIn = user != null;
      final onLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !onLogin) return '/login';
      if (isLoggedIn && onLogin) return '/ordering';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdaptiveShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ordering',
              builder: (context, state) => const OrderingScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/catalog',
              builder: (context, state) => const CatalogScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/users',
              builder: (context, state) => const UsersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  final Ref _ref;
  _AuthListenable(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd mobile && git add lib/navigation/ lib/features/ordering/ lib/features/reports/ lib/features/catalog/ lib/features/users/ lib/features/settings/
git commit -m "feat(mobile): add GoRouter with auth guard and stub screens"
```

---

## Task 13: Login Screen

**Files:** Create `mobile/lib/features/auth/presentation/view/login_screen.dart`

- [ ] **Step 1: Create `mobile/lib/features/auth/presentation/view/login_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../domain/entities/user.dart';
import '../state/auth_notifier.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = useState<List<User>>([]);
    final selectedUser = useState<User?>(null);
    final pin = useState('');
    final isLoading = useState(false);
    final error = useState<String?>(null);

    // Load users on mount
    useEffect(() {
      ref.read(authNotifierProvider.notifier).getActiveUsers().then((u) {
        users.value = u;
      });
      return null;
    }, []);

    void onPinKey(String key) {
      if (pin.value.length >= 6) return;
      pin.value = pin.value + key;
      error.value = null;
    }

    void onDelete() {
      if (pin.value.isEmpty) return;
      pin.value = pin.value.substring(0, pin.value.length - 1);
      error.value = null;
    }

    Future<void> onSubmit() async {
      final user = selectedUser.value;
      if (user == null) {
        error.value = 'Please select a user';
        return;
      }
      if (pin.value.length != 6) {
        error.value = 'PIN must be 6 digits';
        return;
      }
      isLoading.value = true;
      final result = await ref
          .read(authNotifierProvider.notifier)
          .login(user.id, pin.value);
      isLoading.value = false;
      result.fold(
        onSuccess: (_) {
          pin.value = '';
          error.value = null;
        },
        onFailure: (e) {
          pin.value = '';
          error.value = e.message;
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('POS', style: AppTextStyles.displayLg.copyWith(color: AppColors.primary)),
                  const Gap(AppSpacing.xs),
                  Text('Sign In', style: AppTextStyles.headingMd.copyWith(color: AppColors.textSecondary)),
                  const Gap(AppSpacing.xl),

                  // User selector
                  if (users.value.isEmpty)
                    Text(
                      'No users found. Import users via Settings.',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    )
                  else
                    _UserGrid(
                      users: users.value,
                      selected: selectedUser.value,
                      onSelect: (u) {
                        selectedUser.value = u;
                        pin.value = '';
                        error.value = null;
                      },
                    ),

                  const Gap(AppSpacing.lg),

                  // PIN dots
                  _PinDots(length: pin.value.length),
                  const Gap(AppSpacing.lg),

                  // Error
                  if (error.value != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        error.value!,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // PIN pad
                  _PinPad(
                    onKey: onPinKey,
                    onDelete: onDelete,
                    onSubmit: pin.value.length == 6 ? onSubmit : null,
                    isLoading: isLoading.value,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserGrid extends StatelessWidget {
  final List<User> users;
  final User? selected;
  final ValueChanged<User> onSelect;

  const _UserGrid({required this.users, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: users.map((user) {
        final isSelected = selected?.id == user.id;
        return GestureDetector(
          onTap: () => onSelect(user),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              user.name,
              style: AppTextStyles.labelLg.copyWith(
                color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int length;
  const _PinDots({required this.length});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: filled ? AppColors.primary : AppColors.border,
                width: 2,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PinPad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final VoidCallback? onSubmit;
  final bool isLoading;

  const _PinPad({
    required this.onKey,
    required this.onDelete,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return Column(
      children: [
        ...List.generate(3, (row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (col) {
              final key = keys[row * 3 + col];
              return _PinKey(label: key, onTap: () => onKey(key));
            }),
          );
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80, height: 80), // placeholder
            _PinKey(label: '0', onTap: () => onKey('0')),
            SizedBox(
              width: 80,
              height: 80,
              child: onSubmit != null
                  ? _PinActionKey(
                      icon: Icons.check,
                      color: AppColors.primary,
                      onTap: onSubmit!)
                  : _PinActionKey(
                      icon: Icons.backspace_outlined,
                      color: AppColors.textSecondary,
                      onTap: onDelete),
            ),
          ],
        ),
        if (onSubmit == null)
          const SizedBox.shrink()
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PinActionKey(
                icon: Icons.backspace_outlined,
                color: AppColors.textSecondary,
                onTap: onDelete,
              ),
            ],
          ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PinKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Center(
          child: Text(label, style: AppTextStyles.headingLg),
        ),
      ),
    );
  }
}

class _PinActionKey extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PinActionKey({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Center(child: Icon(icon, color: color, size: 28)),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd mobile && git add lib/features/auth/presentation/view/login_screen.dart
git commit -m "feat(mobile): add PIN login screen with user selector"
```

---

## Task 14: Wire Up main.dart

**Files:** Rewrite `mobile/lib/main.dart`

- [ ] **Step 1: Rewrite `mobile/lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/app_database.dart';
import 'core/seeder/admin_seeder.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/state/auth_notifier.dart';
import 'navigation/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final prefs = await SharedPreferences.getInstance();
  final seeder = AdminSeeder(usersDao: db.usersDao, prefs: prefs);
  await seeder.seed();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const MobileApp(),
    ),
  );
}

class MobileApp extends ConsumerWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'POS Mobile',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd mobile && git add lib/main.dart
git commit -m "feat(mobile): wire main.dart — DB init, admin seed, router, theme"
```

---

## Task 15: Run the App & Verify

- [ ] **Step 1: Run all tests**

```bash
cd mobile && flutter test
```

Expected: All tests pass. No compilation errors.

- [ ] **Step 2: Analyze for warnings**

```bash
cd mobile && dart analyze
```

Expected: No errors. Warnings acceptable if they are about unused stubs.

- [ ] **Step 3: Run on Android device or emulator**

```bash
cd mobile && flutter run -d android
```

Expected:
- App launches
- Login screen appears with "Admin" user chip (seeded by AdminSeeder)
- Tapping "Admin" then entering `000000` navigates to Ordering screen
- Tablet width (≥720px): sidebar nav visible on left
- Phone width (<720px): bottom nav visible

- [ ] **Step 4: Final Phase 1 commit**

```bash
cd mobile && git add -A
git commit -m "feat(mobile): Phase 1 complete — foundation, auth, adaptive shell"
```

---

## Phase 1 Complete ✓

**What works after Phase 1:**
- App launches and seeds default admin with PIN `000000`
- Login screen with user grid + 6-digit PIN pad
- Auth state managed by Riverpod — router redirects on login/logout
- Adaptive shell: sidebar on tablet, bottom nav on phone
- All Drift tables created — ready for catalog/sales data
- Stub screens for all 5 nav destinations

**Next: Plan 2 — Catalog, CSV Import, and Settings screens**
See: `docs/superpowers/plans/2026-07-22-mobile-pos-phase2-catalog-csv.md`
