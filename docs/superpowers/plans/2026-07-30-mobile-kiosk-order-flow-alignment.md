# Mobile ↔ Kiosk Order Flow Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure mobile's offline order-creation flow (`mobile/lib/features/ordering/`) and refund flow (`mobile/lib/features/transactions/`) to mirror kiosk's `kiosk/lib/features/sales/` entity/repository/use_case/state architecture — Sale/Receipt/ReceiptItem/Refund/RefundItem naming, two-phase draft→confirm, formatted local SO/refund numbers, auto-print, void support, refund method+reason — while staying 100% offline against the local Drift DB.

**Architecture:** New `entities/`, `repositories/`, `use_cases/` layers under `mobile/lib/features/ordering/` wrap the existing `SalesDao`/Drift tables (no backend calls). `SalesDao` gains business methods (`insertPendingSale`, `completeSale`, `getReceiptById`, `insertRefundRecord`, `voidSale` with reason) that repositories call directly — mirroring mobile's existing convention of putting DB transaction logic in the DAO rather than the repository (a deliberate deviation from kiosk, where the repository builds backend DTOs). Entities are plain hand-written immutable classes with `copyWith` (mobile has `dart_mappable` in `pubspec.yaml` but it is currently unused anywhere in `mobile/lib`, so no new codegen dependency is introduced). Money stays `double` (mobile has no `Decimal` usage anywhere), ids stay `int`/local `String` (no UUID package in mobile).

**Tech Stack:** Flutter, Drift/SQLite (offline), Riverpod (`hooks_riverpod` v3 `AsyncNotifier`), go_router, `flutter_test` + `drift`'s `NativeDatabase.memory()` for DAO/notifier tests.

---

## Design gaps resolved by judgment call (call these out to the user before/while executing)

1. **Payment entity**: kept as a single concrete `SalePayment` class (`method`, `amountPaid`, `cashReceived`, `reference`) instead of kiosk's sealed `CashPayment`/`CardPayment`/`QRPayment` hierarchy — mobile's schema already stores payment as one row with a `method` string column, so a sealed hierarchy would add mapping code with no offline benefit.
2. **Add-on/modifier `ReceiptItem`s**: mobile stores modifiers as child rows in `SaleItemModifiersTable`, not as sibling `SaleItemsTable` rows like kiosk's add-on line items. `SalesDao.getReceiptById` synthesizes an `isMain: false` `ReceiptItem` per modifier row, using `id = -modifierRow.id` (negative) so it can never collide with a main item's `id` (`SaleItemsTable.id`, always positive) — this keeps `Receipt.mainItemsWithAddOns`/`refundedQuantities` lookups by id unambiguous without a schema change.
3. **`Sale.id`**: nullable `int` (`null` until `SaleRepository.save()` assigns the autoincrement id), unlike kiosk's client-generated UUID — mobile has no UUID package and the DB assigns the id.
4. **Store name on `Receipt`**: mobile's `HistoryReceiptData` never carried a store name; `ReceiptRepositoryImpl.getById` now fetches it via the existing `StoreInfoDao` (already used by `receipt_screen.dart` for printing) instead of adding a new `Store` entity.
5. **`void_reason`/`voided_at` columns**: not present on `SalesTable` today even though `SalesDao.voidSale` exists. Added in the same migration as `so_number` since the design's void banner requires them.

---

### Task 1: Drift migration — so_number, void_reason, voided_at, refund_number, method

**Files:**
- Modify: `mobile/lib/core/database/tables/sales_table.dart`
- Modify: `mobile/lib/core/database/tables/refunds_table.dart`
- Modify: `mobile/lib/core/database/app_database.dart:57-157`
- Test: `mobile/test/core/database/app_database_migration_test.dart`

- [ ] **Step 1: Add new columns to `SalesTable`**

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
  TextColumn get status => text()();
  TextColumn get type => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get soNumber => text().nullable()();
  TextColumn get voidReason => text().nullable()();
  DateTimeColumn get voidedAt => dateTime().nullable()();
}
```

- [ ] **Step 2: Add new columns to `RefundsTable`**

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
  TextColumn get refundNumber => text().nullable()();
  TextColumn get method => text().withDefault(const Constant('Cash Refund'))();
}
```

- [ ] **Step 3: Bump `schemaVersion` and add the `from < 7` migration branch**

In `mobile/lib/core/database/app_database.dart`, change:

```dart
  @override
  int get schemaVersion => 7;
```

and append this branch at the end of the `onUpgrade` body (after the existing `if (from < 6) { ... }` block, still inside `MigrationStrategy(...)`):

```dart
          if (from < 7) {
            await m.addColumn(salesTable, salesTable.soNumber);
            await m.addColumn(salesTable, salesTable.voidReason);
            await m.addColumn(salesTable, salesTable.voidedAt);
            await m.addColumn(refundsTable, refundsTable.refundNumber);
            await m.addColumn(refundsTable, refundsTable.method);

            final existingSales = await customSelect('SELECT id FROM sales').get();
            for (final row in existingSales) {
              final id = row.read<int>('id');
              await customStatement(
                'UPDATE sales SET so_number = ? WHERE id = ?',
                [Variable.withString('SO-${id.toString().padLeft(6, '0')}'), Variable.withInt(id)],
              );
            }

            final existingRefunds = await customSelect('SELECT id FROM refunds').get();
            for (final row in existingRefunds) {
              final id = row.read<int>('id');
              await customStatement(
                'UPDATE refunds SET refund_number = ?, method = ? WHERE id = ?',
                [
                  Variable.withString('RF-${id.toString().padLeft(6, '0')}'),
                  Variable.withString('Cash Refund'),
                  Variable.withInt(id),
                ],
              );
            }
          }
```

- [ ] **Step 4: Write the failing migration test**

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';

void main() {
  test('migrating from schema v6 backfills so_number and refund_number', () async {
    // Build a v6 database on disk-equivalent memory, then reopen at the
    // current schema to trigger onUpgrade.
    final connection = DatabaseConnection(NativeDatabase.memory());
    final v6db = _AppDatabaseAtV6(connection);
    await v6db.customStatement('''
      CREATE TABLE users (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL, role TEXT NOT NULL, pin_hash TEXT NOT NULL,
        employee_id TEXT, phone TEXT, avatar_url TEXT,
        is_pin_changed INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await v6db.customStatement(
      "INSERT INTO users (id, name, role, pin_hash) VALUES (1, 'Cashier', 'cashier', 'x')",
    );
    await v6db.customStatement('''
      CREATE TABLE sales (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        cashier_id INTEGER NOT NULL REFERENCES users (id),
        total REAL NOT NULL, discount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL, type TEXT NOT NULL, created_at INTEGER NOT NULL
      )
    ''');
    await v6db.customStatement(
      "INSERT INTO sales (id, cashier_id, total, status, type, created_at) "
      "VALUES (1, 1, 50, 'completed', 'dine_in', 0)",
    );
    await v6db.customStatement('''
      CREATE TABLE refunds (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL REFERENCES sales (id),
        reason TEXT NOT NULL, total REAL NOT NULL, created_at INTEGER NOT NULL
      )
    ''');
    await v6db.customStatement(
      "INSERT INTO refunds (id, sale_id, reason, total, created_at) "
      "VALUES (1, 1, 'Wrong item', 10, 0)",
    );
    await v6db.customStatement('PRAGMA user_version = 6');
    await v6db.close();

    final db = AppDatabase(connection);
    await db.customSelect('SELECT 1').getSingle(); // forces migration to run
    addTearDown(db.close);

    final sale = await db.customSelect('SELECT so_number FROM sales WHERE id = 1').getSingle();
    expect(sale.read<String>('so_number'), 'SO-000001');

    final refund = await db
        .customSelect('SELECT refund_number, method FROM refunds WHERE id = 1')
        .getSingle();
    expect(refund.read<String>('refund_number'), 'RF-000001');
    expect(refund.read<String>('method'), 'Cash Refund');
  });
}

class _AppDatabaseAtV6 extends AppDatabase {
  _AppDatabaseAtV6(DatabaseConnection connection) : super.forMigrationTest(connection);
}
```

Since `AppDatabase` has no constructor that skips `onCreate`/migration, add a minimal test-only constructor to make Step 4's helper class compile — modify `mobile/lib/core/database/app_database.dart`'s class body to add:

```dart
  AppDatabase.forMigrationTest(DatabaseConnection connection) : super.connect(connection);
```

(placed directly below the existing `AppDatabase([QueryExecutor? executor])` constructor). This constructor is unused by production code (the `databaseProvider` still goes through the default constructor) and only exists so the migration test can write raw v6 DDL before handing the connection to the real `_$AppDatabase` machinery.

- [ ] **Step 5: Run the migration test and confirm it fails before the schema change is complete**

Run: `flutter test test/core/database/app_database_migration_test.dart`
Expected (before Steps 1–3 are applied): compile error / column `so_number` not found. After Steps 1–3 are applied: PASS.

- [ ] **Step 6: Run `build_runner` to regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: completes with no errors; `app_database.g.dart`, `sales_dao.g.dart` regenerated with the new columns/companions.

- [ ] **Step 7: Run the migration test again to confirm it passes**

Run: `flutter test test/core/database/app_database_migration_test.dart`
Expected: `00:0X +1: All tests passed!`

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/core/database/tables/sales_table.dart mobile/lib/core/database/tables/refunds_table.dart mobile/lib/core/database/app_database.dart mobile/lib/core/database/app_database.g.dart mobile/lib/core/database/daos/sales_dao.g.dart mobile/test/core/database/app_database_migration_test.dart
git commit -m "Add so_number, void reason, and refund_number columns to sales schema"
```

---

### Task 2: New ordering entities (Sale, LineItem, SalePayment, Receipt, ReceiptItem, Refund, RefundItem)

**Files:**
- Create: `mobile/lib/features/ordering/entities/line_item.dart`
- Create: `mobile/lib/features/ordering/entities/sale_payment.dart`
- Create: `mobile/lib/features/ordering/entities/sale.dart`
- Create: `mobile/lib/features/ordering/entities/receipt_item.dart`
- Create: `mobile/lib/features/ordering/entities/receipt.dart`
- Create: `mobile/lib/features/ordering/entities/refund_item.dart`
- Create: `mobile/lib/features/ordering/entities/refund.dart`
- Delete: `mobile/lib/features/ordering/entities/cart_item.dart` (superseded by `line_item.dart`; deleted in Task 5 once all references are migrated)
- Test: `mobile/test/features/ordering/entities/receipt_test.dart`
- Test: `mobile/test/features/ordering/entities/sale_test.dart`

- [ ] **Step 1: Write `line_item.dart`**

```dart
class SelectedModifierOption {
  final int optionId;
  final String name;
  final double additionalPrice;

  const SelectedModifierOption({
    required this.optionId,
    required this.name,
    required this.additionalPrice,
  });
}

class SelectedModifierGroup {
  final int groupId;
  final String groupName;
  final List<SelectedModifierOption> selected;

  const SelectedModifierGroup({
    required this.groupId,
    required this.groupName,
    required this.selected,
  });
}

class LineItem {
  final String id;
  final int productId;
  final String productName;
  final String groupName;
  final String? imageUrl;
  final double basePrice;
  final int quantity;
  final List<SelectedModifierGroup> modifiers;
  final String? notes;
  final double? discountAmount;

  const LineItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.groupName,
    required this.imageUrl,
    required this.basePrice,
    required this.quantity,
    required this.modifiers,
    this.notes,
    this.discountAmount,
  });

  double get modifierTotal =>
      modifiers.expand((g) => g.selected).fold(0.0, (s, o) => s + o.additionalPrice);

  double get unitPrice => basePrice + modifierTotal;
  double get lineSubtotal => unitPrice * quantity;
  double get lineTotal => lineSubtotal - (discountAmount ?? 0);

  LineItem copyWith({
    int? quantity,
    String? notes,
    double? Function()? discountAmount,
  }) =>
      LineItem(
        id: id,
        productId: productId,
        productName: productName,
        groupName: groupName,
        imageUrl: imageUrl,
        basePrice: basePrice,
        quantity: quantity ?? this.quantity,
        modifiers: modifiers,
        notes: notes ?? this.notes,
        discountAmount: discountAmount != null ? discountAmount() : this.discountAmount,
      );
}
```

- [ ] **Step 2: Write `sale_payment.dart`**

```dart
class SalePayment {
  final String method; // 'cash' | 'card' | 'ewallet'
  final double amountPaid;
  final double cashReceived;
  final String? reference;

  const SalePayment({
    required this.method,
    required this.amountPaid,
    required this.cashReceived,
    this.reference,
  });

  double get change => (cashReceived - amountPaid).clamp(0.0, double.infinity);
}
```

- [ ] **Step 3: Write `sale.dart`**

```dart
import 'line_item.dart';
import 'sale_payment.dart';

class Sale {
  final int? id;
  final String type;
  final List<LineItem> items;
  final DateTime createdAt;
  final SalePayment? payment;
  final String soNumber;
  final double orderDiscount;

  const Sale({
    this.id,
    required this.type,
    required this.items,
    required this.createdAt,
    this.payment,
    this.soNumber = '',
    this.orderDiscount = 0,
  });

  factory Sale.autoGenerated({String type = 'dine_in'}) =>
      Sale(type: type, items: const [], createdAt: DateTime.now());

  double get subtotal => items.fold(0.0, (s, i) => s + i.lineSubtotal);
  double get itemDiscounts => items.fold(0.0, (s, i) => s + (i.discountAmount ?? 0));
  double get totalDiscount => itemDiscounts + orderDiscount;
  double get total => subtotal - totalDiscount;
  int get totalQuantity => items.fold(0, (s, i) => s + i.quantity);

  Sale copyWith({
    int? id,
    String? type,
    List<LineItem>? items,
    SalePayment? Function()? payment,
    String? soNumber,
    double? orderDiscount,
  }) =>
      Sale(
        id: id ?? this.id,
        type: type ?? this.type,
        items: items ?? this.items,
        createdAt: createdAt,
        payment: payment != null ? payment() : this.payment,
        soNumber: soNumber ?? this.soNumber,
        orderDiscount: orderDiscount ?? this.orderDiscount,
      );
}
```

- [ ] **Step 4: Write `receipt_item.dart`**

```dart
class ReceiptItem {
  final int id;
  final int sequence;
  final String description;
  final int quantity;
  final double unitPrice;
  final double grossAmount;
  final double discountAmount;
  final double totalAmount;
  final bool isMain;

  const ReceiptItem({
    required this.id,
    required this.sequence,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.grossAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.isMain,
  });
}
```

- [ ] **Step 5: Write `refund_item.dart` and `refund.dart`**

```dart
// refund_item.dart
class RefundItem {
  final int id;
  final int receiptItemId;
  final int sequence;
  final String description;
  final int quantity;
  final double refundAmount;
  final bool isMain;

  const RefundItem({
    required this.id,
    required this.receiptItemId,
    required this.sequence,
    required this.description,
    required this.quantity,
    required this.refundAmount,
    required this.isMain,
  });
}
```

```dart
// refund.dart
import 'refund_item.dart';

class Refund {
  final int id;
  final String docNumber;
  final DateTime docDate;
  final int receiptId;
  final String reason;
  final String method;
  final List<RefundItem> items;

  const Refund({
    required this.id,
    required this.docNumber,
    required this.docDate,
    required this.receiptId,
    required this.reason,
    required this.method,
    required this.items,
  });

  Refund copyWith({int? id, String? docNumber}) => Refund(
        id: id ?? this.id,
        docNumber: docNumber ?? this.docNumber,
        docDate: docDate,
        receiptId: receiptId,
        reason: reason,
        method: method,
        items: items,
      );
}
```

- [ ] **Step 6: Write `receipt.dart`**

```dart
import 'receipt_item.dart';
import 'refund.dart';
import 'sale_payment.dart';

class Receipt {
  final int id;
  final String storeName;
  final String cashierName;
  final String docNumber;
  final DateTime docDate;
  final String type;
  final SalePayment payment;
  final List<ReceiptItem> items;
  final List<Refund> refunds;
  final bool isVoided;
  final String? voidReason;

  const Receipt({
    required this.id,
    required this.storeName,
    required this.cashierName,
    required this.docNumber,
    required this.docDate,
    required this.type,
    required this.payment,
    required this.items,
    this.refunds = const [],
    this.isVoided = false,
    this.voidReason,
  });

  double get grossAmount => items.fold(0.0, (s, i) => s + i.grossAmount);
  double get discountAmount => items.fold(0.0, (s, i) => s + i.discountAmount);
  double get totalAmount => items.fold(0.0, (s, i) => s + i.totalAmount);

  bool get hasRefunds => refunds.isNotEmpty;

  double get refundedAmount => refunds.fold(
        0.0,
        (sum, r) => sum + r.items.where((ri) => ri.isMain).fold(0.0, (s, ri) => s + ri.refundAmount),
      );

  double get netTotalAmount => totalAmount - refundedAmount;

  Map<int, int> get refundedQuantities {
    final result = <int, int>{};
    for (final refund in refunds) {
      for (final ri in refund.items) {
        result[ri.receiptItemId] = (result[ri.receiptItemId] ?? 0) + ri.quantity;
      }
    }
    return result;
  }

  bool get isFullyRefunded {
    final mainItems = items.where((i) => i.isMain).toList();
    if (mainItems.isEmpty || refunds.isEmpty) return false;
    final refunded = refundedQuantities;
    for (final item in mainItems) {
      if ((refunded[item.id] ?? 0) < item.quantity) return false;
    }
    return true;
  }

  List<({ReceiptItem mainItem, List<ReceiptItem> addOns})> get mainItemsWithAddOns {
    final grouped = <int, ({ReceiptItem mainItem, List<ReceiptItem> addOns})>{};
    for (final item in items) {
      final current = grouped[item.sequence];
      if (item.isMain) {
        grouped[item.sequence] = (mainItem: item, addOns: current?.addOns ?? const []);
      } else {
        grouped[item.sequence] = (
          mainItem: current?.mainItem ?? item,
          addOns: [...current?.addOns ?? const [], item],
        );
      }
    }
    final entries = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => e.value).toList();
  }
}
```

- [ ] **Step 7: Write the failing entity tests**

```dart
// mobile/test/features/ordering/entities/receipt_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ordering/entities/receipt.dart';
import 'package:mobile/features/ordering/entities/receipt_item.dart';
import 'package:mobile/features/ordering/entities/refund.dart';
import 'package:mobile/features/ordering/entities/refund_item.dart';
import 'package:mobile/features/ordering/entities/sale_payment.dart';

Receipt _receipt({List<ReceiptItem>? items, List<Refund>? refunds}) => Receipt(
      id: 1,
      storeName: 'Store',
      cashierName: 'Cashier',
      docNumber: 'SO-000001',
      docDate: DateTime(2026, 7, 30),
      type: 'dine_in',
      payment: const SalePayment(method: 'cash', amountPaid: 100, cashReceived: 100),
      items: items ??
          const [
            ReceiptItem(
              id: 1,
              sequence: 1,
              description: 'Burger',
              quantity: 2,
              unitPrice: 50,
              grossAmount: 100,
              discountAmount: 0,
              totalAmount: 100,
              isMain: true,
            ),
          ],
      refunds: refunds ?? const [],
    );

void main() {
  test('totalAmount sums item totals', () {
    expect(_receipt().totalAmount, 100);
  });

  test('netTotalAmount subtracts refunded main-item amounts', () {
    final refund = Refund(
      id: 1,
      docNumber: 'RF-000001',
      docDate: DateTime(2026, 7, 30),
      receiptId: 1,
      reason: 'Wrong item',
      method: 'Cash Refund',
      items: const [
        RefundItem(
          id: 1,
          receiptItemId: 1,
          sequence: 1,
          description: 'Burger',
          quantity: 1,
          refundAmount: 50,
          isMain: true,
        ),
      ],
    );
    final receipt = _receipt(refunds: [refund]);
    expect(receipt.hasRefunds, isTrue);
    expect(receipt.refundedAmount, 50);
    expect(receipt.netTotalAmount, 50);
    expect(receipt.refundedQuantities, {1: 1});
    expect(receipt.isFullyRefunded, isFalse);
  });

  test('isFullyRefunded is true when refunded quantity meets item quantity', () {
    final refund = Refund(
      id: 1,
      docNumber: 'RF-000001',
      docDate: DateTime(2026, 7, 30),
      receiptId: 1,
      reason: 'Wrong item',
      method: 'Cash Refund',
      items: const [
        RefundItem(
          id: 1,
          receiptItemId: 1,
          sequence: 1,
          description: 'Burger',
          quantity: 2,
          refundAmount: 100,
          isMain: true,
        ),
      ],
    );
    expect(_receipt(refunds: [refund]).isFullyRefunded, isTrue);
  });

  test('mainItemsWithAddOns groups add-on rows under their preceding main item', () {
    final items = [
      const ReceiptItem(
        id: 1, sequence: 1, description: 'Burger', quantity: 1, unitPrice: 50,
        grossAmount: 50, discountAmount: 0, totalAmount: 50, isMain: true,
      ),
      const ReceiptItem(
        id: -1, sequence: 1, description: 'Extra Cheese', quantity: 1, unitPrice: 10,
        grossAmount: 10, discountAmount: 0, totalAmount: 10, isMain: false,
      ),
    ];
    final grouped = _receipt(items: items).mainItemsWithAddOns;
    expect(grouped, hasLength(1));
    expect(grouped.first.mainItem.id, 1);
    expect(grouped.first.addOns.map((a) => a.id), [-1]);
  });
}
```

```dart
// mobile/test/features/ordering/entities/sale_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/entities/sale.dart';

void main() {
  test('Sale.total subtracts item and order discounts from subtotal', () {
    final sale = Sale(
      type: 'dine_in',
      createdAt: DateTime(2026, 7, 30),
      orderDiscount: 5,
      items: [
        const LineItem(
          id: 'a',
          productId: 1,
          productName: 'Burger',
          groupName: 'Mains',
          imageUrl: null,
          basePrice: 50,
          quantity: 2,
          modifiers: [],
          discountAmount: 10,
        ),
      ],
    );

    expect(sale.subtotal, 100);
    expect(sale.itemDiscounts, 10);
    expect(sale.totalDiscount, 15);
    expect(sale.total, 85);
  });
}
```

- [ ] **Step 8: Run the tests to confirm they fail before entities exist**

Run: `flutter test test/features/ordering/entities/receipt_test.dart test/features/ordering/entities/sale_test.dart`
Expected: FAIL with "Target of URI doesn't exist" until Steps 1–6 are complete.

- [ ] **Step 9: Run the tests to confirm they pass**

Run: `flutter test test/features/ordering/entities/receipt_test.dart test/features/ordering/entities/sale_test.dart`
Expected: `00:0X +5: All tests passed!`

- [ ] **Step 10: Commit**

```bash
git add mobile/lib/features/ordering/entities/line_item.dart mobile/lib/features/ordering/entities/sale_payment.dart mobile/lib/features/ordering/entities/sale.dart mobile/lib/features/ordering/entities/receipt_item.dart mobile/lib/features/ordering/entities/receipt.dart mobile/lib/features/ordering/entities/refund_item.dart mobile/lib/features/ordering/entities/refund.dart mobile/test/features/ordering/entities/receipt_test.dart mobile/test/features/ordering/entities/sale_test.dart
git commit -m "Add Sale/Receipt/Refund entities mirroring kiosk's sales domain"
```

(`cart_item.dart` and `cart_state.dart` are deleted in Task 5 once `OrderingNotifier` and the views no longer reference them, to avoid a period where the app doesn't compile.)

---

### Task 3: SalesDao new methods (insertPendingSale, completeSale, voidSale w/ reason, getReceiptById, insertRefundRecord)

**Files:**
- Modify: `mobile/lib/core/database/daos/sales_dao.dart`
- Test: `mobile/test/core/database/sales_dao_receipt_test.dart`

- [ ] **Step 1: Write the failing DAO test**

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/users_table.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/entities/sale.dart';
import 'package:mobile/features/ordering/entities/sale_payment.dart';

void main() {
  late AppDatabase db;
  late int cashierId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
  });

  tearDown(() => db.close());

  test('insertPendingSale persists items, modifiers and payment as status pending', () async {
    final sale = Sale(
      type: 'dine_in',
      createdAt: DateTime(2026, 7, 30),
      payment: const SalePayment(method: 'cash', amountPaid: 60, cashReceived: 100),
      items: [
        LineItem(
          id: 'a',
          productId: 1,
          productName: 'Burger',
          groupName: 'Mains',
          imageUrl: null,
          basePrice: 50,
          quantity: 1,
          modifiers: [
            SelectedModifierGroup(
              groupId: 1,
              groupName: 'Extras',
              selected: [
                const SelectedModifierOption(optionId: 1, name: 'Cheese', additionalPrice: 10),
              ],
            ),
          ],
        ),
      ],
    );

    final saleId = await db.salesDao.insertPendingSale(cashierId: cashierId, sale: sale);
    final row = await db.salesDao.getSaleById(saleId);

    expect(row!.status, 'pending');
    expect(row.soNumber, 'SO-${saleId.toString().padLeft(6, '0')}');
    final items = await db.salesDao.getItemsForSale(saleId);
    expect(items, hasLength(1));
    final payments = await db.salesDao.getPaymentsForSale(saleId);
    expect(payments.single.amount, 60);
  });

  test('completeSale flips status to completed and getReceiptById builds a full Receipt', () async {
    final sale = Sale(
      type: 'dine_in',
      createdAt: DateTime(2026, 7, 30),
      payment: const SalePayment(method: 'cash', amountPaid: 60, cashReceived: 60),
      items: [
        LineItem(
          id: 'a',
          productId: 1,
          productName: 'Burger',
          groupName: 'Mains',
          imageUrl: null,
          basePrice: 50,
          quantity: 1,
          modifiers: [
            SelectedModifierGroup(
              groupId: 1,
              groupName: 'Extras',
              selected: [
                const SelectedModifierOption(optionId: 1, name: 'Cheese', additionalPrice: 10),
              ],
            ),
          ],
        ),
      ],
    );
    final saleId = await db.salesDao.insertPendingSale(cashierId: cashierId, sale: sale);

    await db.salesDao.completeSale(saleId);
    final receipt = await db.salesDao.getReceiptById(saleId);

    expect(receipt, isNotNull);
    expect(receipt!.isVoided, isFalse);
    expect(receipt.items, hasLength(2)); // main item + 1 modifier add-on
    expect(receipt.items.where((i) => i.isMain).single.description, 'Burger');
    expect(receipt.items.where((i) => !i.isMain).single.id, isNegative);
    expect(receipt.docNumber, 'SO-${saleId.toString().padLeft(6, '0')}');
  });

  test('voidSale records reason and voidedAt', () async {
    final saleId = await db.salesDao.insertSale(SalesTableCompanion.insert(
      cashierId: cashierId,
      total: 50,
      status: 'completed',
      type: 'dine_in',
      createdAt: DateTime.now(),
    ));
    await db.salesDao.voidSale(saleId, reason: 'Customer changed mind');
    final receipt = await db.salesDao.getReceiptById(saleId);
    expect(receipt!.isVoided, isTrue);
    expect(receipt.voidReason, 'Customer changed mind');
  });

  test('insertRefundRecord assigns a refund_number and records items', () async {
    final saleId = await db.salesDao.insertSale(SalesTableCompanion.insert(
      cashierId: cashierId,
      total: 50,
      status: 'completed',
      type: 'dine_in',
      createdAt: DateTime.now(),
    ));
    final itemId = await db.salesDao.insertSaleItem(SaleItemsTableCompanion.insert(
      saleId: saleId, productId: 1, variantName: '', qty: 1, unitPrice: 50,
    ));

    final refundId = await db.salesDao.insertRefundRecord(
      saleId: saleId,
      reason: 'Wrong item',
      method: 'Cash Refund',
      total: 50,
      items: [(saleItemId: itemId, qty: 1, amount: 50.0)],
    );

    final refunds = await (db.select(db.refundsTable)
          ..where((t) => t.id.equals(refundId)))
        .get();
    expect(refunds.single.refundNumber, 'RF-${refundId.toString().padLeft(6, '0')}');
    expect(refunds.single.method, 'Cash Refund');
  });
}
```

Note: `getSaleById`'s import of `SalesTableCompanion` requires importing `package:drift/drift.dart` and `package:mobile/core/database/tables/sales_table.dart` and `package:mobile/core/database/tables/sale_items_table.dart` in the test file — add these imports at the top alongside the others.

- [ ] **Step 2: Run the test to confirm it fails**

Run: `flutter test test/core/database/sales_dao_receipt_test.dart`
Expected: FAIL — `insertPendingSale`/`completeSale`/`getReceiptById`/`insertRefundRecord` undefined, `voidSale` has wrong signature.

- [ ] **Step 3: Implement the new DAO methods**

In `mobile/lib/core/database/daos/sales_dao.dart`, add these imports at the top:

```dart
import '../../../features/ordering/entities/line_item.dart';
import '../../../features/ordering/entities/receipt.dart';
import '../../../features/ordering/entities/receipt_item.dart';
import '../../../features/ordering/entities/refund.dart';
import '../../../features/ordering/entities/refund_item.dart';
import '../../../features/ordering/entities/sale.dart';
import '../../../features/ordering/entities/sale_payment.dart';
```

Replace the existing `voidSale` method with:

```dart
  Future<int> voidSale(int saleId, {String reason = 'Voided by cashier'}) =>
      (update(salesTable)..where((t) => t.id.equals(saleId))).write(
        SalesTableCompanion(
          status: const Value('voided'),
          voidReason: Value(reason),
          voidedAt: Value(DateTime.now()),
        ),
      );
```

Add these new methods anywhere inside the `SalesDao` class body (e.g. directly below `insertRefundItem`):

```dart
  Future<int> insertPendingSale({required int cashierId, required Sale sale}) {
    return transaction(() async {
      final saleId = await insertSale(SalesTableCompanion.insert(
        cashierId: cashierId,
        total: sale.total,
        discount: Value(sale.totalDiscount),
        status: 'pending',
        type: sale.type,
        createdAt: sale.createdAt,
      ));

      for (final item in sale.items) {
        final itemId = await insertSaleItem(SaleItemsTableCompanion.insert(
          saleId: saleId,
          productId: item.productId,
          variantName: '',
          qty: item.quantity,
          unitPrice: item.unitPrice,
        ));
        for (final group in item.modifiers) {
          for (final opt in group.selected) {
            await insertSaleItemModifier(SaleItemModifiersTableCompanion.insert(
              itemId: itemId,
              modifierName: '${group.groupName}: ${opt.name}',
              additionalPrice: Value(opt.additionalPrice),
            ));
          }
        }
      }

      if (sale.payment != null) {
        await insertPayment(PaymentsTableCompanion.insert(
          saleId: saleId,
          method: sale.payment!.method,
          amount: sale.payment!.amountPaid,
          reference: Value(sale.payment!.reference),
          createdAt: sale.createdAt,
        ));
      }

      final soNumber = 'SO-${saleId.toString().padLeft(6, '0')}';
      await (update(salesTable)..where((t) => t.id.equals(saleId)))
          .write(SalesTableCompanion(soNumber: Value(soNumber)));

      return saleId;
    });
  }

  Future<void> completeSale(int saleId) =>
      (update(salesTable)..where((t) => t.id.equals(saleId)))
          .write(const SalesTableCompanion(status: Value('completed')));

  Future<int> insertRefundRecord({
    required int saleId,
    required String reason,
    required String method,
    required double total,
    required List<({int saleItemId, int qty, double amount})> items,
  }) {
    return transaction(() async {
      final refundId = await insertRefund(RefundsTableCompanion.insert(
        saleId: saleId,
        reason: reason,
        total: total,
        createdAt: DateTime.now(),
        method: Value(method),
      ));
      for (final item in items) {
        await insertRefundItem(RefundItemsTableCompanion.insert(
          refundId: refundId,
          saleItemId: item.saleItemId,
          qty: item.qty,
          amount: item.amount,
        ));
      }

      final refundNumber = 'RF-${refundId.toString().padLeft(6, '0')}';
      await (update(refundsTable)..where((t) => t.id.equals(refundId)))
          .write(RefundsTableCompanion(refundNumber: Value(refundNumber)));

      final remaining = await getRefundableItems(saleId);
      if (remaining.isEmpty) {
        await (update(salesTable)..where((t) => t.id.equals(saleId)))
            .write(const SalesTableCompanion(status: Value('refunded')));
      }

      return refundId;
    });
  }

  Future<Receipt?> getReceiptById(int saleId) async {
    final saleQ = select(salesTable).join([
      leftOuterJoin(usersTable, usersTable.id.equalsExp(salesTable.cashierId)),
    ]);
    saleQ.where(salesTable.id.equals(saleId));
    final saleRow = await saleQ.getSingleOrNull();
    if (saleRow == null) return null;

    final sale = saleRow.readTable(salesTable);
    final user = saleRow.readTableOrNull(usersTable);

    final itemQ = select(saleItemsTable).join([
      leftOuterJoin(productsTable, productsTable.id.equalsExp(saleItemsTable.productId)),
    ]);
    itemQ.where(saleItemsTable.saleId.equals(saleId));
    final itemRows = await itemQ.get();

    final receiptItems = <ReceiptItem>[];
    var sequence = 1;
    for (final ir in itemRows) {
      final item = ir.readTable(saleItemsTable);
      final product = ir.readTableOrNull(productsTable);
      final grossAmount = item.qty * item.unitPrice;
      receiptItems.add(ReceiptItem(
        id: item.id,
        sequence: sequence,
        description: product?.name ?? 'Unknown Product',
        quantity: item.qty,
        unitPrice: item.unitPrice,
        grossAmount: grossAmount,
        discountAmount: 0,
        totalAmount: grossAmount,
        isMain: true,
      ));

      final mods = await (select(saleItemModifiersTable)
            ..where((t) => t.itemId.equals(item.id)))
          .get();
      for (final mod in mods) {
        final modGross = mod.additionalPrice * item.qty;
        receiptItems.add(ReceiptItem(
          id: -mod.id,
          sequence: sequence,
          description: mod.modifierName,
          quantity: item.qty,
          unitPrice: mod.additionalPrice,
          grossAmount: modGross,
          discountAmount: 0,
          totalAmount: modGross,
          isMain: false,
        ));
      }
      sequence++;
    }

    final payments = await (select(paymentsTable)..where((t) => t.saleId.equals(saleId))).get();
    final paymentRow = payments.isEmpty ? null : payments.first;
    final payment = SalePayment(
      method: paymentRow?.method ?? 'cash',
      amountPaid: paymentRow?.amount ?? sale.total,
      cashReceived: paymentRow?.amount ?? sale.total,
      reference: paymentRow?.reference,
    );

    final refundRows = await (select(refundsTable)..where((t) => t.saleId.equals(saleId))).get();
    final refunds = <Refund>[];
    for (final r in refundRows) {
      final riRows =
          await (select(refundItemsTable)..where((t) => t.refundId.equals(r.id))).get();
      final refundItems = <RefundItem>[];
      for (final ri in riRows) {
        final match = receiptItems.firstWhere(
          (rItem) => rItem.isMain && rItem.id == ri.saleItemId,
          orElse: () => ReceiptItem(
            id: ri.saleItemId,
            sequence: 0,
            description: 'Unknown Item',
            quantity: ri.qty,
            unitPrice: 0,
            grossAmount: 0,
            discountAmount: 0,
            totalAmount: 0,
            isMain: true,
          ),
        );
        refundItems.add(RefundItem(
          id: ri.id,
          receiptItemId: ri.saleItemId,
          sequence: match.sequence,
          description: match.description,
          quantity: ri.qty,
          refundAmount: ri.amount,
          isMain: true,
        ));
      }
      refunds.add(Refund(
        id: r.id,
        docNumber: r.refundNumber ?? 'RF-${r.id.toString().padLeft(6, '0')}',
        docDate: r.createdAt,
        receiptId: saleId,
        reason: r.reason,
        method: r.method,
        items: refundItems,
      ));
    }

    return Receipt(
      id: sale.id,
      storeName: '',
      cashierName: user?.name ?? 'Unknown',
      docNumber: sale.soNumber ?? 'SO-${sale.id.toString().padLeft(6, '0')}',
      docDate: sale.createdAt,
      type: sale.type,
      payment: payment,
      items: receiptItems,
      refunds: refunds,
      isVoided: sale.status == 'voided',
      voidReason: sale.voidReason,
    );
  }
```

- [ ] **Step 4: Regenerate Drift code and run the test**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/core/database/sales_dao_receipt_test.dart`
Expected: `00:0X +4: All tests passed!`

- [ ] **Step 5: Run the full existing DAO/notifier test suite to confirm `voidSale`'s new default-parameter signature didn't break `transactions_notifier_test.dart`**

Run: `flutter test test/features/transactions/state/transactions_notifier_test.dart`
Expected: `00:0X +4: All tests passed!` (the existing `voidTransaction(saleId)` call site keeps compiling because `reason` has a default value).

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/core/database/daos/sales_dao.dart mobile/lib/core/database/daos/sales_dao.g.dart mobile/test/core/database/sales_dao_receipt_test.dart
git commit -m "Add SalesDao methods for pending sales, receipts, and refund records"
```

---

### Task 4: Repositories and use cases (SaleRepository, ReceiptRepository, RefundRepository, FinalizeSale, VoidSale, ProcessRefund)

**Files:**
- Create: `mobile/lib/features/ordering/repositories/sale_repository.dart`
- Create: `mobile/lib/features/ordering/repositories/receipt_repository.dart`
- Create: `mobile/lib/features/ordering/repositories/refund_repository.dart`
- Create: `mobile/lib/features/ordering/use_cases/finalize_sale.dart`
- Create: `mobile/lib/features/ordering/use_cases/void_sale.dart`
- Create: `mobile/lib/features/ordering/use_cases/process_refund.dart`
- Test: `mobile/test/features/ordering/use_cases/finalize_sale_test.dart`
- Test: `mobile/test/features/ordering/use_cases/process_refund_test.dart`

- [ ] **Step 1: Write the repositories**

```dart
// mobile/lib/features/ordering/repositories/sale_repository.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../entities/sale.dart';

abstract class SaleRepository {
  Future<Sale> save(Sale sale, {required int cashierId});
}

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepositoryImpl(ref.watch(databaseProvider));
});

class SaleRepositoryImpl implements SaleRepository {
  const SaleRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Sale> save(Sale sale, {required int cashierId}) async {
    final saleId = await _db.salesDao.insertPendingSale(cashierId: cashierId, sale: sale);
    return sale.copyWith(id: saleId, soNumber: 'SO-${saleId.toString().padLeft(6, '0')}');
  }
}
```

```dart
// mobile/lib/features/ordering/repositories/receipt_repository.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../entities/receipt.dart';

abstract class ReceiptRepository {
  Future<Receipt> save(int saleId);
  Future<Receipt?> getById(int saleId);
}

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepositoryImpl(ref.watch(databaseProvider));
});

class ReceiptRepositoryImpl implements ReceiptRepository {
  const ReceiptRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Receipt> save(int saleId) async {
    await _db.salesDao.completeSale(saleId);
    final receipt = await _db.salesDao.getReceiptById(saleId);
    if (receipt == null) {
      throw StateError('Sale $saleId not found after completing it.');
    }
    return receipt;
  }

  @override
  Future<Receipt?> getById(int saleId) => _db.salesDao.getReceiptById(saleId);
}
```

```dart
// mobile/lib/features/ordering/repositories/refund_repository.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../entities/refund.dart';

abstract class RefundRepository {
  Future<Refund> save(Refund refund);
}

final refundRepositoryProvider = Provider<RefundRepository>((ref) {
  return RefundRepositoryImpl(ref.watch(databaseProvider));
});

class RefundRepositoryImpl implements RefundRepository {
  const RefundRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Refund> save(Refund refund) async {
    final refundId = await _db.salesDao.insertRefundRecord(
      saleId: refund.receiptId,
      reason: refund.reason,
      method: refund.method,
      total: refund.items.fold(0.0, (s, i) => s + i.refundAmount),
      items: refund.items
          .map((i) => (saleItemId: i.receiptItemId, qty: i.quantity, amount: i.refundAmount))
          .toList(),
    );
    return refund.copyWith(id: refundId, docNumber: 'RF-${refundId.toString().padLeft(6, '0')}');
  }
}
```

- [ ] **Step 2: Write the use cases**

```dart
// mobile/lib/features/ordering/use_cases/finalize_sale.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/receipt.dart';
import '../entities/sale.dart';
import '../repositories/receipt_repository.dart';
import '../repositories/sale_repository.dart';

final finalizeSaleProvider = Provider<FinalizeSale>((ref) {
  return FinalizeSale(ref.watch(saleRepositoryProvider), ref.watch(receiptRepositoryProvider));
});

class FinalizeSale {
  const FinalizeSale(this._saleRepository, this._receiptRepository);

  final SaleRepository _saleRepository;
  final ReceiptRepository _receiptRepository;

  Future<Receipt> call(Sale sale, {required int cashierId}) async {
    if (sale.payment == null) throw StateError('Payment is required to finalize sale.');
    final savedSale = await _saleRepository.save(sale, cashierId: cashierId);
    return _receiptRepository.save(savedSale.id!);
  }
}
```

```dart
// mobile/lib/features/ordering/use_cases/void_sale.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

final voidSaleProvider = Provider<VoidSale>((ref) => VoidSale(ref.watch(databaseProvider)));

class VoidSale {
  const VoidSale(this._db);

  final AppDatabase _db;

  Future<void> call({required int saleId, required String reason}) {
    return _db.salesDao.voidSale(saleId, reason: reason);
  }
}
```

```dart
// mobile/lib/features/ordering/use_cases/process_refund.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/receipt.dart';
import '../entities/refund.dart';
import '../entities/refund_item.dart';
import '../repositories/refund_repository.dart';

final processRefundProvider = Provider<ProcessRefund>((ref) {
  return ProcessRefund(ref.watch(refundRepositoryProvider));
});

class ProcessRefund {
  const ProcessRefund(this._refundRepository);

  final RefundRepository _refundRepository;

  Future<Refund> call({
    required Receipt receipt,
    required Map<int, int> selectedQuantities,
    required String reason,
    required String refundMethod,
  }) async {
    final refundItems = <RefundItem>[];
    for (final entry in selectedQuantities.entries) {
      if (entry.value <= 0) continue;
      final receiptItem = receipt.items.firstWhere((i) => i.id == entry.key);
      final refundAmount = receiptItem.unitPrice * entry.value;
      refundItems.add(RefundItem(
        id: 0,
        receiptItemId: receiptItem.id,
        sequence: receiptItem.sequence,
        description: receiptItem.description,
        quantity: entry.value,
        refundAmount: refundAmount,
        isMain: receiptItem.isMain,
      ));
    }

    final refund = Refund(
      id: 0,
      docNumber: '',
      docDate: DateTime.now(),
      receiptId: receipt.id,
      reason: reason,
      method: refundMethod,
      items: refundItems,
    );

    return _refundRepository.save(refund);
  }
}
```

- [ ] **Step 3: Write the failing use-case tests**

```dart
// mobile/test/features/ordering/use_cases/finalize_sale_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/users_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/entities/sale.dart';
import 'package:mobile/features/ordering/entities/sale_payment.dart';
import 'package:mobile/features/ordering/use_cases/finalize_sale.dart';

void main() {
  test('FinalizeSale saves the sale as pending then flips it to completed via the receipt', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final sale = Sale(
      type: 'dine_in',
      createdAt: DateTime(2026, 7, 30),
      payment: const SalePayment(method: 'cash', amountPaid: 50, cashReceived: 50),
      items: [
        LineItem(
          id: 'a',
          productId: 1,
          productName: 'Burger',
          groupName: 'Mains',
          imageUrl: null,
          basePrice: 50,
          quantity: 1,
          modifiers: const [],
        ),
      ],
    );

    final receipt = await container.read(finalizeSaleProvider)(sale, cashierId: cashierId);

    expect(receipt.isVoided, isFalse);
    expect(receipt.docNumber, startsWith('SO-'));
    expect(receipt.items.single.description, 'Burger');

    final row = await db.salesDao.getSaleById(receipt.id);
    expect(row!.status, 'completed');
  });

  test('FinalizeSale throws when the sale has no payment', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final sale = Sale(type: 'dine_in', createdAt: DateTime.now(), items: const []);

    expect(
      () => container.read(finalizeSaleProvider)(sale, cashierId: cashierId),
      throwsStateError,
    );
  });
}
```

```dart
// mobile/test/features/ordering/use_cases/process_refund_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/users_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/entities/sale.dart';
import 'package:mobile/features/ordering/entities/sale_payment.dart';
import 'package:mobile/features/ordering/use_cases/finalize_sale.dart';
import 'package:mobile/features/ordering/use_cases/process_refund.dart';

void main() {
  test('ProcessRefund computes refund amount from unit price and saves via RefundRepository', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final sale = Sale(
      type: 'dine_in',
      createdAt: DateTime(2026, 7, 30),
      payment: const SalePayment(method: 'cash', amountPaid: 100, cashReceived: 100),
      items: [
        LineItem(
          id: 'a',
          productId: 1,
          productName: 'Burger',
          groupName: 'Mains',
          imageUrl: null,
          basePrice: 50,
          quantity: 2,
          modifiers: const [],
        ),
      ],
    );
    final receipt = await container.read(finalizeSaleProvider)(sale, cashierId: cashierId);
    final mainItem = receipt.items.single;

    final refund = await container.read(processRefundProvider)(
      receipt: receipt,
      selectedQuantities: {mainItem.id: 1},
      reason: 'Wrong item',
      refundMethod: 'Cash Refund',
    );

    expect(refund.docNumber, startsWith('RF-'));
    expect(refund.items.single.refundAmount, 50);

    final updatedReceipt = await db.salesDao.getReceiptById(receipt.id);
    expect(updatedReceipt!.refundedAmount, 50);
  });
}
```

- [ ] **Step 4: Run the tests to confirm they fail**

Run: `flutter test test/features/ordering/use_cases/finalize_sale_test.dart test/features/ordering/use_cases/process_refund_test.dart`
Expected: FAIL — providers/use cases undefined until Steps 1–2 exist.

- [ ] **Step 5: Run the tests to confirm they pass**

Run: `flutter test test/features/ordering/use_cases/finalize_sale_test.dart test/features/ordering/use_cases/process_refund_test.dart`
Expected: `00:0X +3: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/ordering/repositories mobile/lib/features/ordering/use_cases mobile/test/features/ordering/use_cases
git commit -m "Add SaleRepository, ReceiptRepository, RefundRepository and their use cases"
```

---

### Task 5: Rewire OrderingNotifier and PaymentScreen onto Sale/LineItem/FinalizeSale

**Files:**
- Modify: `mobile/lib/features/ordering/state/ordering_notifier.dart`
- Modify: `mobile/lib/features/ordering/view/ordering_screen.dart`
- Modify: `mobile/lib/features/ordering/view/modifier_dialog.dart`
- Modify: `mobile/lib/features/ordering/view/payment_screen.dart`
- Delete: `mobile/lib/features/ordering/entities/cart_item.dart`
- Delete: `mobile/lib/features/ordering/entities/cart_state.dart`
- Test: `mobile/test/features/ordering/state/ordering_notifier_test.dart`

- [ ] **Step 1: Write the failing notifier test**

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/product_groups_table.dart';
import 'package:mobile/core/database/tables/product_variants_table.dart';
import 'package:mobile/core/database/tables/products_table.dart';
import 'package:mobile/core/database/tables/users_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/state/ordering_notifier.dart';

void main() {
  test('confirmSale saves the cart as a completed Sale and clears the cart', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final groupId = await db.into(db.productGroupsTable).insert(
          ProductGroupsTableCompanion.insert(name: 'Mains'),
        );
    final productId = await db.into(db.productsTable).insert(
          ProductsTableCompanion.insert(groupId: groupId, name: 'Burger'),
        );
    await db.into(db.productVariantsTable).insert(
          ProductVariantsTableCompanion.insert(productId: productId, name: 'Regular', price: 50),
        );

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(orderingProvider.future);
    container.read(orderingProvider.notifier).addItem(
          LineItem(
            id: 'a',
            productId: productId,
            productName: 'Burger',
            groupName: 'Mains',
            imageUrl: null,
            basePrice: 50,
            quantity: 1,
            modifiers: const [],
          ),
        );

    final receipt = await container.read(orderingProvider.notifier).confirmSale(
          cashierId: cashierId,
          method: 'cash',
          amountPaid: 50,
        );

    expect(receipt.docNumber, startsWith('SO-'));
    final row = await db.salesDao.getSaleById(receipt.id);
    expect(row!.status, 'completed');

    final cart = container.read(orderingProvider).value!;
    expect(cart.sale.items, isEmpty);
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `flutter test test/features/ordering/state/ordering_notifier_test.dart`
Expected: FAIL — `orderingProvider`'s `.sale`/`LineItem` don't exist yet on the old `CartState` shape.

- [ ] **Step 3: Rewrite `ordering_notifier.dart`**

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../entities/line_item.dart';
import '../entities/receipt.dart';
import '../entities/sale.dart';
import '../entities/sale_payment.dart';
import '../use_cases/finalize_sale.dart';

class OrderGroup {
  final int id;
  final String name;
  const OrderGroup({required this.id, required this.name});
}

class OrderProduct {
  final int id;
  final int groupId;
  final String name;
  final double price;
  final bool isAvailable;
  final String? imageUrl;

  const OrderProduct({
    required this.id,
    required this.groupId,
    required this.name,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
  });
}

class OrderingData {
  final List<OrderGroup> groups;
  final List<OrderProduct> allProducts;
  final int? selectedGroupId;
  final Sale sale;

  const OrderingData({
    required this.groups,
    required this.allProducts,
    this.selectedGroupId,
    required this.sale,
  });

  List<OrderProduct> get filteredProducts {
    var list = allProducts.where((p) => p.isAvailable).toList();
    if (selectedGroupId != null) {
      list = list.where((p) => p.groupId == selectedGroupId).toList();
    }
    return list;
  }

  OrderingData copyWith({
    List<OrderGroup>? groups,
    List<OrderProduct>? allProducts,
    int? Function()? selectedGroupId,
    Sale? sale,
  }) =>
      OrderingData(
        groups: groups ?? this.groups,
        allProducts: allProducts ?? this.allProducts,
        selectedGroupId: selectedGroupId != null ? selectedGroupId() : this.selectedGroupId,
        sale: sale ?? this.sale,
      );
}

class OrderingNotifier extends AsyncNotifier<OrderingData> {
  @override
  Future<OrderingData> build() => _load();

  Future<OrderingData> _load() async {
    final db = ref.watch(databaseProvider);
    final groupRows = await db.productsDao.getAllActiveGroups();
    final productRows = await db.productsDao.getAllProductsWithPrice();

    final groups = groupRows.map((g) => OrderGroup(id: g.id, name: g.name)).toList();
    final products = productRows
        .map((p) => OrderProduct(
              id: p.product.id,
              groupId: p.product.groupId,
              name: p.product.name,
              price: p.price,
              isAvailable: p.product.isAvailable,
              imageUrl: p.product.imageUrl,
            ))
        .toList();

    final current = state.value;
    return OrderingData(
      groups: groups,
      allProducts: products,
      selectedGroupId: current?.selectedGroupId,
      sale: current?.sale ?? Sale.autoGenerated(),
    );
  }

  void selectGroup(int? groupId) {
    state = state.whenData((s) => s.copyWith(selectedGroupId: () => groupId));
  }

  void addItem(LineItem item) {
    state = state.whenData(
      (s) => s.copyWith(sale: s.sale.copyWith(items: [...s.sale.items, item])),
    );
  }

  void removeItem(String lineItemId) {
    state = state.whenData((s) => s.copyWith(
          sale: s.sale.copyWith(
            items: s.sale.items.where((i) => i.id != lineItemId).toList(),
          ),
        ));
  }

  void updateQuantity(String lineItemId, int qty) {
    if (qty <= 0) {
      removeItem(lineItemId);
      return;
    }
    state = state.whenData((s) => s.copyWith(
          sale: s.sale.copyWith(
            items: s.sale.items
                .map((i) => i.id == lineItemId ? i.copyWith(quantity: qty) : i)
                .toList(),
          ),
        ));
  }

  void updateNotes(String lineItemId, String? notes) {
    state = state.whenData((s) => s.copyWith(
          sale: s.sale.copyWith(
            items: s.sale.items
                .map((i) => i.id == lineItemId
                    ? i.copyWith(notes: (notes?.isEmpty == true) ? null : notes)
                    : i)
                .toList(),
          ),
        ));
  }

  void applyItemDiscount(String lineItemId, double amount) {
    state = state.whenData((s) => s.copyWith(
          sale: s.sale.copyWith(
            items: s.sale.items
                .map((i) => i.id == lineItemId ? i.copyWith(discountAmount: () => amount) : i)
                .toList(),
          ),
        ));
  }

  void clearItemDiscount(String lineItemId) {
    state = state.whenData((s) => s.copyWith(
          sale: s.sale.copyWith(
            items: s.sale.items
                .map((i) => i.id == lineItemId ? i.copyWith(discountAmount: () => null) : i)
                .toList(),
          ),
        ));
  }

  void applyOrderDiscount(double amount) {
    state = state.whenData((s) => s.copyWith(sale: s.sale.copyWith(orderDiscount: amount)));
  }

  void clearOrderDiscount() {
    state = state.whenData((s) => s.copyWith(sale: s.sale.copyWith(orderDiscount: 0)));
  }

  void setSaleType(String type) {
    state = state.whenData((s) => s.copyWith(sale: s.sale.copyWith(type: type)));
  }

  void clearCart() {
    state = state.whenData(
      (s) => s.copyWith(sale: Sale.autoGenerated(type: s.sale.type)),
    );
  }

  Future<Receipt> confirmSale({
    required int cashierId,
    required String method,
    required double amountPaid,
    String? reference,
  }) async {
    final data = state.value!;
    final total = data.sale.total;
    final cashReceived = method == 'cash' ? amountPaid : total;

    final saleWithPayment = data.sale.copyWith(
      payment: () => SalePayment(
        method: method,
        amountPaid: method == 'cash' ? total : amountPaid,
        cashReceived: cashReceived,
        reference: reference,
      ),
    );

    final finalizeSale = ref.read(finalizeSaleProvider);
    final receipt = await finalizeSale(saleWithPayment, cashierId: cashierId);

    clearCart();
    return receipt;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final orderingProvider =
    AsyncNotifierProvider<OrderingNotifier, OrderingData>(OrderingNotifier.new);
```

- [ ] **Step 4: Run the notifier test to confirm it passes**

Run: `flutter test test/features/ordering/state/ordering_notifier_test.dart`
Expected: `00:0X +1: All tests passed!`

- [ ] **Step 5: Update `ordering_screen.dart` and `modifier_dialog.dart` to reference `LineItem`/`OrderingData` instead of `CartItem`/`CartState`**

In `ordering_screen.dart`, replace the import line and every reference:

```dart
// was: import '../entities/cart_item.dart'; import '../entities/cart_state.dart';
import '../entities/line_item.dart';
import '../state/ordering_notifier.dart';
```

then do a mechanical rename throughout the file: `CartItem` → `LineItem`, `CartState state` → `OrderingData state`, `state.value?.items` → `state.value?.sale.items`, `cartState.items` → `cartState.sale.items`, `item.cartId` → `item.id`, `state!.totalQuantity` → `state!.sale.totalQuantity`, `cartState.subtotal/.total/.totalDiscount/.orderDiscount/.saleType` → `cartState.sale.subtotal/.total/.totalDiscount/.orderDiscount/.type`. `CartState`'s `filteredProducts`/`groups` accessors stay the same shape since `OrderingData` (Step 3) keeps those fields and getter.

In `modifier_dialog.dart`, replace:

```dart
import '../entities/cart_item.dart';
import '../entities/cart_state.dart';
```

with:

```dart
import '../entities/line_item.dart';
import '../state/ordering_notifier.dart';
```

and change `Future<CartItem?> showModifierDialog` → `Future<LineItem?> showModifierDialog`, the `showModalBottomSheet<CartItem>` → `showModalBottomSheet<LineItem>`, and the `final cartItem = CartItem(cartId: ...)` construction to `final lineItem = LineItem(id: '${product.id}_${DateTime.now().microsecondsSinceEpoch}', ...)` (same fields, `cartId:` renamed to `id:`), and `Navigator.of(context).pop(cartItem)` → `Navigator.of(context).pop(lineItem)`.

- [ ] **Step 6: Update `payment_screen.dart` to use `Sale`/`orderingProvider.notifier.confirmSale` and navigate to the id-based receipt route**

Replace the import block's `import '../entities/cart_state.dart';` with `import '../entities/sale.dart';`, and change every `cartState.total/.items/.saleType/.totalDiscount` reference the same way (`.sale.total`, `.sale.items`, `.sale.type`, `.sale.totalDiscount`); the `cartState` variable itself becomes `orderingData.sale` — rename the local `final cartState = ref.watch(orderingProvider.select((s) => s.value));` to `final orderingData = ref.watch(orderingProvider.select((s) => s.value));` and use `orderingData.sale` everywhere it previously used `cartState`. Change `processPayment()`'s success path:

```dart
        final receipt = await ref.read(orderingProvider.notifier).confirmSale(
              cashierId: authState.user.id,
              method: selectedMethod.value,
              amountPaid: tender,
              reference: selectedMethod.value != 'cash' &&
                      referenceController.text.trim().isNotEmpty
                  ? referenceController.text.trim()
                  : null,
            );

        if (context.mounted) {
          context.go('/order/receipt/${receipt.id}?autoPrint=true');
        }
```

(drop the `cashierName:` argument — `confirmSale`'s new signature no longer needs it since `Receipt.cashierName` is now looked up from the DB via `getReceiptById`).

- [ ] **Step 7: Delete the retired entities**

```bash
git rm mobile/lib/features/ordering/entities/cart_item.dart mobile/lib/features/ordering/entities/cart_state.dart
```

- [ ] **Step 8: Run `flutter analyze` to catch any remaining `CartItem`/`CartState` references**

Run: `flutter analyze lib/features/ordering`
Expected: `No issues found!` (fix any remaining references the mechanical rename in Step 5 missed before moving on).

- [ ] **Step 9: Run the full ordering test suite**

Run: `flutter test test/features/ordering`
Expected: `00:0X +N: All tests passed!`

- [ ] **Step 10: Commit**

```bash
git add mobile/lib/features/ordering mobile/test/features/ordering/state/ordering_notifier_test.dart
git commit -m "Rewire OrderingNotifier and payment flow onto Sale/LineItem/FinalizeSale"
```

---

### Task 6: ReceiptNotifier, router change, and ReceiptScreen rewrite (auto-print + void)

**Files:**
- Create: `mobile/lib/features/ordering/state/receipt_notifier.dart`
- Modify: `mobile/lib/features/ordering/view/receipt_screen.dart`
- Modify: `mobile/lib/core/navigation/router.dart:61-74`
- Modify: `mobile/lib/core/services/print_service.dart` (retarget `printReceipt` onto `Receipt`)
- Create: `mobile/lib/features/ordering/view/void_sale_dialog.dart`
- Test: `mobile/test/features/ordering/state/receipt_notifier_test.dart`

- [ ] **Step 1: Write the failing `ReceiptNotifier` test**

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/users_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/ordering/state/receipt_notifier.dart';

void main() {
  test('void_ marks the receipt voided with the given reason', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final saleId = await db.salesDao.insertSale(SalesTableCompanion.insert(
      cashierId: cashierId,
      total: 50,
      status: 'completed',
      type: 'dine_in',
      createdAt: DateTime.now(),
    ));

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(receiptProvider(saleId).future);
    await container.read(receiptProvider(saleId).notifier).void_('Customer changed mind');

    final receipt = container.read(receiptProvider(saleId)).value!;
    expect(receipt.isVoided, isTrue);
    expect(receipt.voidReason, 'Customer changed mind');
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `flutter test test/features/ordering/state/receipt_notifier_test.dart`
Expected: FAIL — `receiptProvider` doesn't exist yet.

- [ ] **Step 3: Write `receipt_notifier.dart`**

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/print_service.dart';
import '../entities/receipt.dart';
import '../repositories/receipt_repository.dart';
import '../use_cases/void_sale.dart';

final receiptProvider =
    AsyncNotifierProvider.autoDispose.family<ReceiptNotifier, Receipt, int>(
  ReceiptNotifier.new,
  name: 'receiptProvider',
);

class ReceiptNotifier extends AsyncNotifier<Receipt> {
  ReceiptNotifier(this.saleId);

  final int saleId;

  @override
  Future<Receipt> build() async {
    final repository = ref.watch(receiptRepositoryProvider);
    final receipt = await repository.getById(saleId);
    if (receipt == null) throw StateError('Receipt $saleId not found.');
    return receipt;
  }

  Future<bool> print() async {
    if (!state.hasValue) return false;
    final db = ref.read(databaseProvider);
    final storeInfo = await db.storeInfoDao.getStoreInfo();
    return PrintService.printReceipt(
      state.requireValue,
      currency: (storeInfo?.currency.isNotEmpty ?? false) ? storeInfo!.currency : 'PHP',
      storeFooter:
          (storeInfo?.receiptFooter.isNotEmpty ?? false) ? storeInfo!.receiptFooter : 'Thank you!',
      storeName: storeInfo?.storeName,
      storeAddress: storeInfo?.address,
      storeTin: storeInfo?.tin,
      terminalName: storeInfo?.terminalName,
    );
  }

  Future<void> void_(String reason) async {
    final voidSale = ref.read(voidSaleProvider);
    await voidSale(saleId: saleId, reason: reason);
    ref.invalidateSelf();
    await future;
  }
}
```

- [ ] **Step 4: Retarget `PrintService.printReceipt` onto `Receipt`**

In `mobile/lib/core/services/print_service.dart`, change the import from `../../features/ordering/entities/sale_receipt_data.dart` to `../../features/ordering/entities/receipt.dart`, change the signature to `static Future<bool> printReceipt(Receipt receipt, {...})` (same named params), and update the body's field references: `receipt.saleId` → `receipt.id`, `receipt.cashierName` stays, `receipt.createdAt` → `receipt.docDate`, `receipt.saleType` → `receipt.type`, `receipt.items` (now `List<ReceiptItem>`) iteration drops `item.quantity`/`item.productName`/`item.lineTotal`/`item.modifiers`/`item.notes`/`item.discountAmount` in favor of `item.quantity`, `item.description`, `item.totalAmount`, and skips the modifier/notes sub-lines entirely (add-ons are now separate `ReceiptItem` rows with `isMain: false`, printed as their own indented row — add an `if (!item.isMain) '  '` prefix in the existing `generator.row` call's first `PosColumn` text), `receipt.subtotal` → `receipt.grossAmount`, `receipt.totalDiscount` → `receipt.discountAmount`, `receipt.total` → `receipt.totalAmount`, `receipt.paymentMethod` → `receipt.payment.method`, `receipt.amountPaid` → `receipt.payment.amountPaid`, `receipt.change` → `receipt.payment.change`, `receipt.reference` → `receipt.payment.reference`.

- [ ] **Step 5: Run the `ReceiptNotifier` test to confirm it passes**

Run: `flutter test test/features/ordering/state/receipt_notifier_test.dart`
Expected: `00:0X +1: All tests passed!`

- [ ] **Step 6: Update the router to pass `id`/`autoPrint` to `ReceiptScreen`**

In `mobile/lib/core/navigation/router.dart`, replace the `receipt` sub-route:

```dart
          GoRoute(
            path: 'receipt/:id',
            builder: (context, state) => ReceiptScreen(
              saleId: int.parse(state.pathParameters['id']!),
              autoPrint: state.uri.queryParameters['autoPrint'] == 'true',
            ),
          ),
```

- [ ] **Step 7: Rewrite `receipt_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../transactions/view/refund_auth_dialog.dart';
import '../state/ordering_notifier.dart';
import '../state/receipt_notifier.dart';
import 'void_sale_dialog.dart';

class ReceiptScreen extends HookConsumerWidget {
  const ReceiptScreen({super.key, required this.saleId, this.autoPrint = false});

  final int saleId;
  final bool autoPrint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printing = useState(false);
    final autoPrinted = useRef(false);

    useEffect(() {
      if (!autoPrint) return null;
      final sub = ref.listenManual(receiptProvider(saleId), (previous, next) {
        if (autoPrinted.value) return;
        if (next case AsyncData(:final value) when !value.isVoided) {
          autoPrinted.value = true;
          ref.read(receiptProvider(saleId).notifier).print();
        }
      });
      return sub.close;
    }, const []);

    final receiptAsync = ref.watch(receiptProvider(saleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Receipt'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/order'),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('New Order'),
          ),
        ],
      ),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (receipt) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: receipt.isVoided ? AppColors.errorLight : AppColors.successLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: receipt.isVoided ? AppColors.error : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      receipt.isVoided ? Icons.block_rounded : Icons.check_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Text(
                    receipt.isVoided ? 'Transaction Voided' : 'Payment Successful',
                    style: AppTextStyles.headingMd.copyWith(
                      color: receipt.isVoided ? AppColors.error : AppColors.success,
                    ),
                  ),
                  const Gap(4),
                  Text(receipt.docNumber,
                      style: AppTextStyles.bodySm.copyWith(
                        color: receipt.isVoided ? AppColors.error : AppColors.success,
                      )),
                  if (receipt.isVoided && receipt.voidReason != null) ...[
                    const Gap(4),
                    Text('Reason: ${receipt.voidReason}',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                  ],
                ],
              ),
            ),
            const Gap(AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in receipt.items)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm, left: item.isMain ? 0 : 16),
                      child: Row(
                        children: [
                          Expanded(child: Text('x${item.quantity} ${item.description}')),
                          Text('PHP ${item.totalAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('PHP ${receipt.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (receipt.hasRefunds) ...[
                    const Gap(AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Refunded', style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                        Text('-PHP ${receipt.refundedAmount.toStringAsFixed(2)}',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Net Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('PHP ${receipt.netTotalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Gap(AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.go('/order'),
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('New Order'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, AppSpacing.touchPreferred),
              ),
            ),
            const Gap(AppSpacing.md),
            OutlinedButton.icon(
              onPressed: printing.value
                  ? null
                  : () async {
                      printing.value = true;
                      final ok = await ref.read(receiptProvider(saleId).notifier).print();
                      printing.value = false;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? 'Receipt printed'
                              : 'No printer configured — go to Settings → Printer Setup'),
                        ));
                      }
                    },
              icon: printing.value
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.print_outlined),
              label: const Text('Print Receipt'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, AppSpacing.touchMin),
              ),
            ),
            if (!receipt.isVoided) ...[
              const Gap(AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _voidReceipt(context, ref),
                icon: const Icon(Icons.block_rounded),
                label: const Text('Void Transaction'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  minimumSize: const Size(double.infinity, AppSpacing.touchMin),
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _voidReceipt(BuildContext context, WidgetRef ref) async {
    final reason = await VoidSaleDialog.show(context);
    if (reason == null || !context.mounted) return;

    final authorized = await showDialog<bool>(
      context: context,
      builder: (_) => const RefundAuthDialog(),
    );
    if (authorized != true) return;

    await ref.read(receiptProvider(saleId).notifier).void_(reason);
    ref.invalidate(orderingProvider);
  }
}
```

- [ ] **Step 8: Write `void_sale_dialog.dart`**

```dart
import 'package:flutter/material.dart';

class VoidSaleDialog extends StatefulWidget {
  const VoidSaleDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(context: context, builder: (_) => const VoidSaleDialog());
  }

  @override
  State<VoidSaleDialog> createState() => _VoidSaleDialogState();
}

class _VoidSaleDialogState extends State<VoidSaleDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Void this transaction?'),
      content: TextField(
        controller: _reasonController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Reason'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _reasonController.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _reasonController.text.trim()),
          child: const Text('Void'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 9: Delete `sale_receipt_data.dart`, now unused**

```bash
git rm mobile/lib/features/ordering/entities/sale_receipt_data.dart
```

- [ ] **Step 10: Run `flutter analyze` and the ordering test suite**

Run: `flutter analyze lib/features/ordering lib/core/services/print_service.dart lib/core/navigation/router.dart`
Expected: `No issues found!`
Run: `flutter test test/features/ordering`
Expected: `00:0X +N: All tests passed!`

- [ ] **Step 11: Commit**

```bash
git add mobile/lib/features/ordering mobile/lib/core/navigation/router.dart mobile/lib/core/services/print_service.dart mobile/test/features/ordering/state/receipt_notifier_test.dart
git commit -m "Add ReceiptNotifier with auto-print and void, rewire ReceiptScreen and router"
```

---

### Task 7: RefundNotifier

**Files:**
- Create: `mobile/lib/features/transactions/state/refund_notifier.dart`
- Test: `mobile/test/features/transactions/state/refund_notifier_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/users_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/entities/sale.dart';
import 'package:mobile/features/ordering/entities/sale_payment.dart';
import 'package:mobile/features/ordering/use_cases/finalize_sale.dart';
import 'package:mobile/features/transactions/state/refund_notifier.dart';

void main() {
  test('confirmRefund saves the selected quantities with reason and method', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final sale = Sale(
      type: 'dine_in',
      createdAt: DateTime(2026, 7, 30),
      payment: const SalePayment(method: 'cash', amountPaid: 100, cashReceived: 100),
      items: [
        LineItem(
          id: 'a', productId: 1, productName: 'Burger', groupName: 'Mains',
          imageUrl: null, basePrice: 50, quantity: 2, modifiers: const [],
        ),
      ],
    );
    final receipt = await container.read(finalizeSaleProvider)(sale, cashierId: cashierId);

    final notifier = container.read(refundProvider(receipt.id).notifier);
    await container.read(refundProvider(receipt.id).future);

    final mainItem = receipt.items.single;
    notifier.toggleItemSelection(itemId: mainItem.id, maxQuantity: mainItem.quantity);
    notifier.changeReason('Wrong item');
    notifier.changeRefundMethod('Card Refund');
    await notifier.confirmRefund();

    final updated = await db.salesDao.getReceiptById(receipt.id);
    expect(updated!.refunds.single.reason, 'Wrong item');
    expect(updated.refunds.single.method, 'Card Refund');
    expect(updated.refundedAmount, 100);
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `flutter test test/features/transactions/state/refund_notifier_test.dart`
Expected: FAIL — `refundProvider` doesn't exist yet.

- [ ] **Step 3: Write `refund_notifier.dart`**

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ordering/entities/receipt.dart';
import '../../ordering/repositories/receipt_repository.dart';
import '../../ordering/use_cases/process_refund.dart';

final refundProvider =
    AsyncNotifierProvider.autoDispose.family<RefundNotifier, RefundData, int>(
  RefundNotifier.new,
  name: 'refundProvider',
);

class RefundForm {
  final Map<int, int> selectedQuantities;
  final String reason;
  final String refundMethod;

  const RefundForm({
    this.selectedQuantities = const {},
    this.reason = '',
    this.refundMethod = 'Cash Refund',
  });

  RefundForm copyWith({Map<int, int>? selectedQuantities, String? reason, String? refundMethod}) =>
      RefundForm(
        selectedQuantities: selectedQuantities ?? this.selectedQuantities,
        reason: reason ?? this.reason,
        refundMethod: refundMethod ?? this.refundMethod,
      );
}

class RefundData {
  final Receipt receipt;
  final RefundForm form;

  const RefundData({required this.receipt, this.form = const RefundForm()});

  RefundData copyWith({Receipt? receipt, RefundForm? form}) =>
      RefundData(receipt: receipt ?? this.receipt, form: form ?? this.form);
}

class RefundNotifier extends AsyncNotifier<RefundData> {
  RefundNotifier(this.saleId);

  final int saleId;

  @override
  Future<RefundData> build() async {
    final repository = ref.watch(receiptRepositoryProvider);
    final receipt = await repository.getById(saleId);
    if (receipt == null) throw StateError('Receipt $saleId not found.');
    return RefundData(receipt: receipt);
  }

  void toggleItemSelection({required int itemId, required int maxQuantity}) {
    if (!state.hasValue) return;
    final current = Map<int, int>.from(state.requireValue.form.selectedQuantities);
    if (current.containsKey(itemId)) {
      current.remove(itemId);
    } else {
      current[itemId] = maxQuantity;
    }
    state = AsyncData(state.requireValue.copyWith(
      form: state.requireValue.form.copyWith(selectedQuantities: current),
    ));
  }

  void changeQuantity({required int itemId, required int quantity}) {
    if (!state.hasValue) return;
    final item = state.requireValue.receipt.items.firstWhere((i) => i.id == itemId);
    if (quantity <= 0 || quantity > item.quantity) return;
    final current = Map<int, int>.from(state.requireValue.form.selectedQuantities);
    current[itemId] = quantity;
    state = AsyncData(state.requireValue.copyWith(
      form: state.requireValue.form.copyWith(selectedQuantities: current),
    ));
  }

  void changeReason(String reason) {
    if (!state.hasValue) return;
    state = AsyncData(
      state.requireValue.copyWith(form: state.requireValue.form.copyWith(reason: reason)),
    );
  }

  void changeRefundMethod(String method) {
    if (!state.hasValue) return;
    state = AsyncData(
      state.requireValue.copyWith(form: state.requireValue.form.copyWith(refundMethod: method)),
    );
  }

  Future<void> confirmRefund() async {
    if (!state.hasValue) return;
    final data = state.requireValue;
    final processRefund = ref.read(processRefundProvider);
    await processRefund(
      receipt: data.receipt,
      selectedQuantities: data.form.selectedQuantities,
      reason: data.form.reason,
      refundMethod: data.form.refundMethod,
    );
    ref.invalidateSelf();
    await future;
  }
}
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `flutter test test/features/transactions/state/refund_notifier_test.dart`
Expected: `00:0X +1: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/transactions/state/refund_notifier.dart mobile/test/features/transactions/state/refund_notifier_test.dart
git commit -m "Add RefundNotifier driving refund selection, reason and method"
```

---

### Task 8: RefundScreen rewrite (reason field + method selector) and transaction_detail_screen refund history

**Files:**
- Modify: `mobile/lib/features/transactions/view/refund_screen.dart`
- Modify: `mobile/lib/features/transactions/view/transaction_detail_screen.dart`
- Delete: `mobile/lib/features/transactions/entities/history_receipt_data.dart` (superseded by `Receipt`)

- [ ] **Step 1: Rewrite `refund_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../ordering/entities/receipt_item.dart';
import '../state/refund_notifier.dart';
import 'refund_auth_dialog.dart';

class RefundScreen extends ConsumerWidget {
  final int saleId;
  const RefundScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(refundProvider(saleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Refund Items')),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final refundedQty = data.receipt.refundedQuantities;
          final selectableItems = data.receipt.items.where((i) {
            if (!i.isMain) return false;
            return i.quantity - (refundedQty[i.id] ?? 0) > 0;
          }).toList();

          if (selectableItems.isEmpty) {
            return const Center(child: Text('Nothing left to refund on this sale'));
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final item in selectableItems)
                _RefundItemRow(
                  item: item,
                  maxQuantity: item.quantity - (refundedQty[item.id] ?? 0),
                  selectedQty: data.form.selectedQuantities[item.id] ?? 0,
                  onToggle: () => ref
                      .read(refundProvider(saleId).notifier)
                      .toggleItemSelection(itemId: item.id, maxQuantity: item.quantity - (refundedQty[item.id] ?? 0)),
                  onQuantityChanged: (qty) => ref
                      .read(refundProvider(saleId).notifier)
                      .changeQuantity(itemId: item.id, quantity: qty),
                ),
              const Gap(AppSpacing.lg),
              Text('REASON', style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
              const Gap(AppSpacing.sm),
              TextField(
                onChanged: (v) => ref.read(refundProvider(saleId).notifier).changeReason(v),
                decoration: const InputDecoration(hintText: 'e.g. Wrong item, customer request…'),
              ),
              const Gap(AppSpacing.lg),
              Text('REFUND METHOD',
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
              const Gap(AppSpacing.sm),
              _RefundMethodSelector(
                selected: data.form.refundMethod,
                onChanged: (m) => ref.read(refundProvider(saleId).notifier).changeRefundMethod(m),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton(
            onPressed: () => _submitRefund(context, ref, dataAsync.value),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(double.infinity, AppSpacing.touchPreferred),
            ),
            child: Text(_selectedTotalLabel(dataAsync.value)),
          ),
        ),
      ),
    );
  }

  String _selectedTotalLabel(RefundData? data) {
    if (data == null) return 'Refund Selected Items';
    final total = data.form.selectedQuantities.entries.fold(0.0, (sum, entry) {
      final item = data.receipt.items.firstWhere((i) => i.id == entry.key);
      return sum + item.unitPrice * entry.value;
    });
    return total > 0 ? 'Refund ₱${total.toStringAsFixed(2)}' : 'Refund Selected Items';
  }

  Future<void> _submitRefund(BuildContext context, WidgetRef ref, RefundData? data) async {
    if (data == null || data.form.selectedQuantities.isEmpty || data.form.reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select items and enter a reason before refunding.')),
      );
      return;
    }

    final authorized = await showDialog<bool>(
      context: context,
      builder: (_) => const RefundAuthDialog(),
    );
    if (authorized != true || !context.mounted) return;

    try {
      await ref.read(refundProvider(saleId).notifier).confirmRefund();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refund failed: $e')));
      return;
    }

    if (context.mounted) Navigator.of(context).pop();
  }
}

class _RefundItemRow extends StatelessWidget {
  final ReceiptItem item;
  final int maxQuantity;
  final int selectedQty;
  final VoidCallback onToggle;
  final ValueChanged<int> onQuantityChanged;

  const _RefundItemRow({
    required this.item,
    required this.maxQuantity,
    required this.selectedQty,
    required this.onToggle,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Checkbox(value: selectedQty > 0, onChanged: (_) => onToggle()),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, style: AppTextStyles.headingSm),
                Text('Available: $maxQuantity × ₱${item.unitPrice.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (selectedQty > 0) ...[
            IconButton(
              onPressed: selectedQty > 1 ? () => onQuantityChanged(selectedQty - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$selectedQty', style: AppTextStyles.headingSm),
            IconButton(
              onPressed: selectedQty < maxQuantity ? () => onQuantityChanged(selectedQty + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _RefundMethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _RefundMethodSelector({required this.selected, required this.onChanged});

  static const _methods = ['Cash Refund', 'Card Refund', 'E-wallet Refund'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: _methods.map((m) {
        final isSel = selected == m;
        return ChoiceChip(
          label: Text(m),
          selected: isSel,
          onSelected: (_) => onChanged(m),
        );
      }).toList(),
    );
  }
}
```

(add `import 'package:gap/gap.dart';` at the top for the `Gap` widgets used above.)

- [ ] **Step 2: Update `transaction_detail_screen.dart` to use `Receipt` and its refund-history getters**

Replace the `_historyReceiptProvider` and imports:

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../../ordering/repositories/receipt_repository.dart';
import '../../ordering/entities/receipt.dart';
import 'refund_screen.dart';
import 'void_sale_dialog_bridge.dart';
```

Replace `_historyReceiptProvider`:

```dart
final _receiptProvider = FutureProvider.family<Receipt?, int>((ref, saleId) {
  return ref.watch(receiptRepositoryProvider).getById(saleId);
});
```

and in `build`, replace `_historyReceiptProvider(saleId)` with `_receiptProvider(saleId)`, then update the body that renders `receipt.items`/summary rows to use the `Receipt`/`ReceiptItem` shape:

```dart
        data: (receipt) {
          if (receipt == null) return const Center(child: Text('Transaction not found'));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(DateFormat('MMM d, yyyy • h:mm a').format(receipt.docDate),
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              for (final item in receipt.items)
                ListTile(
                  contentPadding: EdgeInsets.only(left: item.isMain ? 0 : 16),
                  title: Text(item.description),
                  trailing: Text('${item.quantity} × ₱${item.unitPrice.toStringAsFixed(2)}'),
                ),
              const Divider(),
              _SummaryRow('Gross', receipt.grossAmount),
              _SummaryRow('Discount', -receipt.discountAmount),
              _SummaryRow('Total', receipt.totalAmount, bold: true),
              if (receipt.hasRefunds) ...[
                const Divider(),
                Text('REFUND HISTORY',
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.error)),
                for (final refund in receipt.refunds) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('${refund.docNumber} • ${refund.method} • ${refund.reason}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                  for (final ri in refund.items.where((i) => i.isMain))
                    _SummaryRow('  ${ri.quantity}× ${ri.description}', -ri.refundAmount),
                ],
                _SummaryRow('Net Total', receipt.netTotalAmount, bold: true),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (isAdmin && !receipt.isVoided) ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RefundScreen(saleId: saleId)),
                  ),
                  icon: const Icon(Icons.replay_outlined),
                  label: const Text('Refund Items'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => _confirmVoid(context, ref),
                  icon: const Icon(Icons.block),
                  label: const Text('Void Transaction'),
                ),
              ],
            ],
          );
        },
```

and update `_confirmVoid` to collect a reason (reusing the void dialog added in Task 6) instead of a fixed confirm dialog:

```dart
  Future<void> _confirmVoid(BuildContext context, WidgetRef ref) async {
    final reason = await voidSaleDialogShow(context);
    if (reason == null || !context.mounted) return;
    await ref.read(databaseProviderVoidHelperProvider).call(saleId: saleId, reason: reason);
    ref.invalidate(_receiptProvider(saleId));
    if (context.mounted) Navigator.of(context).pop();
  }
```

To keep this self-contained without a second copy of `VoidSaleDialog`'s UI, create a tiny bridge file so `transaction_detail_screen.dart` doesn't need to import a view file living under `ordering/`:

```dart
// mobile/lib/features/transactions/view/void_sale_dialog_bridge.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ordering/use_cases/void_sale.dart';
import '../../ordering/view/void_sale_dialog.dart';

Future<String?> voidSaleDialogShow(BuildContext context) => VoidSaleDialog.show(context);

final databaseProviderVoidHelperProvider = Provider<VoidSale>((ref) => ref.watch(voidSaleProvider));
```

- [ ] **Step 3: Delete the now-unused `history_receipt_data.dart` and its DAO methods that only it consumed**

```bash
git rm mobile/lib/features/transactions/entities/history_receipt_data.dart
```

In `mobile/lib/core/database/daos/sales_dao.dart`, remove the `getHistoryReceipt` and `getRefundableItems` methods and the now-unused `HistoryReceiptData`/`HistoryReceiptItem` import, since `Receipt`/`getReceiptById` (Task 3) fully replace them and no other call site references them after this task.

- [ ] **Step 4: Run `flutter analyze` across the transactions and ordering features**

Run: `flutter analyze lib/features/transactions lib/features/ordering lib/core/database/daos/sales_dao.dart`
Expected: `No issues found!`

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: `00:0X +N: All tests passed!` (all suites across `test/`, including the pre-existing ones untouched by this plan)

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/transactions mobile/lib/features/ordering/view/void_sale_dialog.dart mobile/lib/core/database/daos/sales_dao.dart mobile/lib/core/database/daos/sales_dao.g.dart
git commit -m "Rewrite RefundScreen with reason/method fields and show refund history on transaction detail"
```

---

## Self-review

**1. Spec coverage** — walked every section of the design doc against the tasks above:
- Entity layer (`Sale`, `LineItem`, `Receipt`, `ReceiptItem`, `Refund`, `RefundItem`) → Task 2.
- Repository layer (`SaleRepository`, `ReceiptRepository`, `RefundRepository`) → Task 4.
- Use cases (`FinalizeSale`, `VoidSale`, `ProcessRefund`) → Task 4.
- Order numbering (`SO-000123`, `RF-000045`) → Task 1 (columns/migration/backfill), Task 3 (`insertPendingSale`/`insertRefundRecord` assign them).
- Two-phase confirm (`SaleRepository.save` pending → `ReceiptRepository.save` completed) → Task 3 (`insertPendingSale`/`completeSale`), Task 4 (`FinalizeSale`).
- Auto-print via route param → Task 6 (router `autoPrint` query param + `ReceiptScreen` `useEffect`).
- Void with reason + supervisor auth → Task 6 (`ReceiptScreen._voidReceipt`, `VoidSaleDialog`, reuse of `RefundAuthDialog`), Task 8 (`transaction_detail_screen.dart`'s void action updated the same way).
- Refund reason + method selector + `RefundNotifier` → Task 7, Task 8.
- `Receipt` getters (`grossAmount`/`vatAmount`.../`hasRefunds`/`isFullyRefunded`/`refundedQuantities`/`mainItemsWithAddOns`) → Task 2 (`vatAmount`/`vatableAmount` intentionally omitted: mobile has no VAT computation anywhere in its existing domain — `SalesTable`/`TransactionSummary` never compute VAT — so introducing it would be inventing business logic outside this plan's scope; flagged here rather than silently dropped).
- Migrations (`so_number`, `refund_number`, `method`, plus the necessarily-added `void_reason`/`voided_at`) with backfill → Task 1.
- Transaction detail refund history display → Task 8.
- Out-of-scope items (no backend calls, no kiosk changes, no printing-transport changes) → respected throughout; `PrintService` retargeting in Task 6 only changes its input type, not its Bluetooth transport.

**2. Placeholder scan** — no "TBD"/"similar to Task N"/unshown code found in the above; every step has complete, file-scoped code including imports for new methods.

**3. Type consistency** — verified across tasks: `Sale.id` is `int?` everywhere it's referenced (Task 2, 4, 5); `LineItem.id` is `String` everywhere (Task 2 entity, Task 5's screen/dialog renames, Task 3/4 test fixtures); `ReceiptItem.id`/`RefundItem.receiptItemId` are `int` everywhere, including the negative-id add-on convention used consistently in Task 3's DAO, Task 6's screen, and Task 7/8's refund selection maps (`Map<int, int>`); `Refund.method`/`RefundForm.refundMethod` use the same three string literals (`'Cash Refund'`/`'Card Refund'`/`'E-wallet Refund'`) in Task 7 and Task 8; `SalesDao.voidSale(int, {String reason})` signature is used identically by `VoidSale` (Task 4), `ReceiptNotifier.void_` (Task 6), and the transaction-detail bridge (Task 8) — no call site still uses the old positional-only signature except the pre-existing `transactions_notifier.dart` call, which still compiles because of the added default.

---
