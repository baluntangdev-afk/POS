# Mobile ↔ Kiosk Feature Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the feature gap between the Windows kiosk app (`kiosk/`) and the mobile app (`mobile/`) so the mobile app supports the same POS operations, staying on its existing local Drift/sqlite architecture (no backend API integration — that was explicitly ruled out for this plan).

**Architecture:** Mobile keeps its current feature-first structure (`features/<name>/{entities,state,view}`) and local `AppDatabase` (Drift). Every phase below either wires up already-existing DAO methods to new screens, or extends a DAO with new query methods and mirrors an existing Riverpod `AsyncNotifier` + `HookConsumerWidget` + `GoRouter` route pattern already established in `features/reports` and `features/catalog`.

**Tech Stack:** Flutter, Riverpod (`hooks_riverpod`), `go_router`, Drift (sqlite), `flutter_hooks`.

---

## Gap Summary (from kiosk vs. mobile audit)

| Phase | Area | Kiosk has | Mobile has | Risk if skipped |
|---|---|---|---|---|
| 1 | Transaction history, void, refunds | Full screens + supervisor auth | DAO/entities exist, **zero UI** | High — financial data invisible/uneditable on mobile |
| 2 | Cashier accounting (X/Z-Reading, Daily Report) | Full generation + print flow | **Nothing** | High — no shift close-out capability |
| 3 | Catalog CRUD (products/categories/modifiers) | Full create/edit/delete | Read-only, CSV-import-only | Medium — mobile can't manage catalog in the field |
| 4 | Sales Reports depth (charts, export) | Donut/bar charts, file export, unexported-day reminder | Summary cards + lists only | Medium — less actionable reporting |
| 5 | POS terminal / franchisee setup | Terminal registration + franchisee info dialogs | Only basic store info form | Low-medium — needed for compliance-grade receipts |
| 6 | Polish (setup-PIN flow, device identifier on receipts, dine-in/table selection) | Present | Absent/partial | Low |

**Phasing rationale:** ordered by financial/operational risk. Phase 1 is fully detailed below because it has the most scaffolding already in place (`SalesDao`, `TransactionSummary`, `HistoryReceiptData` already exist) and is the highest-risk gap (voids/refunds silently unavailable). **Phases 2–6 are scoped but not step-detailed** — each is an independent subsystem per the writing-plans scope rule, and should get its own detailed plan (same template as Phase 1) generated right before it's picked up, so the task list reflects the codebase as it exists at that time.

---

## Phase 1: Transaction History, Void & Refunds

### Task 1: Add missing DAO test coverage and one small DAO gap (refund total + status re-open on partial refund)

**Files:**
- Modify: `mobile/lib/core/database/daos/sales_dao.dart`
- Test: `mobile/test/core/database/daos/sales_dao_test.dart`

Kiosk's refund flow marks a sale `refunded` once fully refunded so it shows correctly in transaction lists; mobile's `TransactionSummary.isFullyRefunded` getter already computes this client-side, but nothing persists a `refunded` status onto `sales_table`, so `voidSale`-style status filtering elsewhere would miss it. Add a DAO method that performs the refund insert transactionally and updates sale status when fully refunded, so status is authoritative in the DB, not just derived client-side.

- [ ] **Step 1: Write the failing test**

```dart
// mobile/test/core/database/daos/sales_dao_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/database/tables/sale_items_table.dart';
import 'package:mobile/core/database/tables/products_table.dart';
import 'package:mobile/core/database/tables/product_groups_table.dart';
import 'package:mobile/core/database/tables/refund_items_table.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<int> _seedSaleWithOneItem({required int qty, required double unitPrice}) async {
    final groupId = await db.into(db.productGroupsTable).insert(
          ProductGroupsTableCompanion.insert(name: 'Drinks'),
        );
    final productId = await db.into(db.productsTable).insert(
          ProductsTableCompanion.insert(groupId: groupId, name: 'Latte', price: unitPrice),
        );
    final saleId = await db.salesDao.insertSale(
      SalesTableCompanion.insert(total: unitPrice * qty, type: 'dine_in'),
    );
    await db.salesDao.insertSaleItem(
      SaleItemsTableCompanion.insert(
        saleId: saleId,
        productId: productId,
        qty: qty,
        unitPrice: unitPrice,
      ),
    );
    return saleId;
  }

  test('recordRefund marks sale as refunded once fully refunded', () async {
    final saleId = await _seedSaleWithOneItem(qty: 2, unitPrice: 100);
    final items = await db.salesDao.getRefundableItems(saleId);
    expect(items, hasLength(1));

    await db.salesDao.recordRefund(
      saleId: saleId,
      total: 200,
      items: [(saleItemId: items.first.saleItemId, qty: 2)],
    );

    final sale = await db.salesDao.getSaleById(saleId);
    expect(sale!.status, 'refunded');

    final remaining = await db.salesDao.getRefundableItems(saleId);
    expect(remaining, isEmpty);
  });

  test('recordRefund leaves sale status completed on partial refund', () async {
    final saleId = await _seedSaleWithOneItem(qty: 2, unitPrice: 100);
    final items = await db.salesDao.getRefundableItems(saleId);

    await db.salesDao.recordRefund(
      saleId: saleId,
      total: 100,
      items: [(saleItemId: items.first.saleItemId, qty: 1)],
    );

    final sale = await db.salesDao.getSaleById(saleId);
    expect(sale!.status, 'completed');

    final remaining = await db.salesDao.getRefundableItems(saleId);
    expect(remaining, hasLength(1));
    expect(remaining.first.qty, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd mobile && flutter test test/core/database/daos/sales_dao_test.dart`
Expected: FAIL — `recordRefund` is not defined on `SalesDao`.

- [ ] **Step 3: Add `recordRefund` to `SalesDao`**

Add this method to `mobile/lib/core/database/daos/sales_dao.dart`, right after `insertRefundItem`:

```dart
  Future<void> recordRefund({
    required int saleId,
    required double total,
    required List<({int saleItemId, int qty})> items,
  }) async {
    await transaction(() async {
      final refundId = await insertRefund(
        RefundsTableCompanion.insert(saleId: saleId, total: total),
      );
      for (final item in items) {
        await insertRefundItem(
          RefundItemsTableCompanion.insert(
            refundId: refundId,
            saleItemId: item.saleItemId,
            qty: item.qty,
          ),
        );
      }

      final remaining = await getRefundableItems(saleId);
      if (remaining.isEmpty) {
        await (update(salesTable)..where((t) => t.id.equals(saleId)))
            .write(const SalesTableCompanion(status: Value('refunded')));
      }
    });
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd mobile && flutter test test/core/database/daos/sales_dao_test.dart`
Expected: PASS (both tests)

- [ ] **Step 5: Regenerate Drift code and commit**

```bash
cd mobile
fvm dart run build_runner build --delete-conflicting-outputs
git add lib/core/database/daos/sales_dao.dart lib/core/database/daos/sales_dao.g.dart test/core/database/daos/sales_dao_test.dart
git commit -m "feat: add transactional refund recording to SalesDao"
```

---

### Task 2: Transactions list screen (history, search, date filter)

**Files:**
- Create: `mobile/lib/features/transactions/state/transactions_notifier.dart`
- Create: `mobile/lib/features/transactions/view/transactions_screen.dart`
- Modify: `mobile/lib/core/navigation/router.dart`
- Modify: `mobile/lib/features/dashboard/view/dashboard_screen.dart`
- Test: `mobile/test/features/transactions/state/transactions_notifier_test.dart`

Mirrors the `ReportsNotifier` pattern (`mobile/lib/features/reports/state/reports_notifier.dart`) — `AsyncNotifier` holding filter state, reloading via `db.salesDao.getTransactions(...)`.

- [ ] **Step 1: Write the failing notifier test**

```dart
// mobile/test/features/transactions/state/transactions_notifier_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/transactions/state/transactions_notifier.dart';

void main() {
  test('loads transactions from the database ordered newest first', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.salesDao.insertSale(SalesTableCompanion.insert(total: 50, type: 'take_out'));
    await db.salesDao.insertSale(SalesTableCompanion.insert(total: 75, type: 'dine_in'));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final result = await container.read(transactionsProvider.future);

    expect(result.items, hasLength(2));
    expect(result.items.first.total, 75); // newest first
  });

  test('search filters by invoice id', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firstId = await db.salesDao.insertSale(SalesTableCompanion.insert(total: 50, type: 'take_out'));
    await db.salesDao.insertSale(SalesTableCompanion.insert(total: 75, type: 'dine_in'));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(transactionsProvider.notifier).setSearch('#${firstId.toString().padLeft(6, '0')}');
    final result = await container.read(transactionsProvider.future);

    expect(result.items, hasLength(1));
    expect(result.items.first.id, firstId);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd mobile && flutter test test/features/transactions/state/transactions_notifier_test.dart`
Expected: FAIL — `transactions_notifier.dart` does not exist.

- [ ] **Step 3: Write `TransactionsNotifier`**

```dart
// mobile/lib/features/transactions/state/transactions_notifier.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../entities/transaction_summary.dart';

class TransactionsPage {
  final List<TransactionSummary> items;
  final int totalCount;
  final int offset;
  final int limit;

  const TransactionsPage({
    required this.items,
    required this.totalCount,
    required this.offset,
    required this.limit,
  });

  bool get hasMore => offset + items.length < totalCount;
}

class TransactionsNotifier extends AsyncNotifier<TransactionsPage> {
  DateTime? _date;
  String? _search;
  static const _pageSize = 20;

  DateTime? get date => _date;
  String? get search => _search;

  @override
  Future<TransactionsPage> build() => _load();

  Future<TransactionsPage> _load({int offset = 0}) async {
    final db = ref.watch(databaseProvider);
    final items = await db.salesDao.getTransactions(
      date: _date,
      search: _search,
      limit: _pageSize,
      offset: offset,
    );
    final totalCount = await db.salesDao.getTransactionCount(date: _date, search: _search);
    return TransactionsPage(items: items, totalCount: totalCount, offset: offset, limit: _pageSize);
  }

  Future<void> setDate(DateTime? date) async {
    _date = date;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load());
  }

  Future<void> setSearch(String? query) async {
    _search = (query?.trim().isEmpty ?? true) ? null : query!.trim();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load());
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    final next = await _load(offset: current.offset + current.items.length);
    state = AsyncValue.data(TransactionsPage(
      items: [...current.items, ...next.items],
      totalCount: next.totalCount,
      offset: next.offset,
      limit: next.limit,
    ));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load());
  }

  Future<void> voidTransaction(int saleId) async {
    final db = ref.read(databaseProvider);
    await db.salesDao.voidSale(saleId);
    await refresh();
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, TransactionsPage>(TransactionsNotifier.new);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd mobile && flutter test test/features/transactions/state/transactions_notifier_test.dart`
Expected: PASS

- [ ] **Step 5: Build the list screen**

```dart
// mobile/lib/features/transactions/view/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../entities/transaction_summary.dart';
import '../state/transactions_notifier.dart';

class TransactionsScreen extends HookConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(transactionsProvider);
    final searchCtrl = useTextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Filter by date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDate: ref.read(transactionsProvider.notifier).date ?? DateTime.now(),
              );
              if (picked != null) {
                await ref.read(transactionsProvider.notifier).setDate(picked);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by invoice # (e.g. #000123)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (v) => ref.read(transactionsProvider.notifier).setSearch(v),
            ),
          ),
          Expanded(
            child: pageAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (page) {
                if (page.items.isEmpty) {
                  return const Center(child: Text('No transactions found'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(transactionsProvider.notifier).refresh(),
                  child: NotificationListener<ScrollEndNotification>(
                    onNotification: (n) {
                      if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                        ref.read(transactionsProvider.notifier).loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: page.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => _TransactionTile(
                        tx: page.items[i],
                        onTap: () => context.push('/transactions/${page.items[i].id}'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionSummary tx;
  final VoidCallback onTap;
  const _TransactionTile({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = tx.isVoided
        ? AppColors.error
        : tx.hasRefunds
            ? Colors.orange
            : AppColors.success;
    final statusLabel = tx.isVoided
        ? 'Voided'
        : tx.isFullyRefunded
            ? 'Refunded'
            : tx.hasRefunds
                ? 'Partially Refunded'
                : 'Completed';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(tx.invoiceNumber, style: AppTextStyles.headingSm),
        subtitle: Text(
          '${tx.displayType} • ${tx.cashierName} • ${DateFormat('MMM d, h:mm a').format(tx.createdAt)}',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₱${tx.netTotal.toStringAsFixed(2)}', style: AppTextStyles.headingSm),
            Text(statusLabel, style: AppTextStyles.bodySm.copyWith(color: statusColor)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Register the route and dashboard tile**

In `mobile/lib/core/navigation/router.dart`, add the import and a top-level route (mirrors the `/reports` route):

```dart
import '../../features/transactions/view/transactions_screen.dart';
import '../../features/transactions/view/transaction_detail_screen.dart';
```

```dart
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => TransactionDetailScreen(
              saleId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
```

(`transaction_detail_screen.dart` is built in Task 3 — this route wiring is added here since the router edit belongs with navigation, but the screen file itself doesn't exist until Task 3. Leave the import in but expect analyzer error until Task 3 completes; do not run `flutter analyze` as a pass/fail gate until Task 3's Step is done.)

In `mobile/lib/features/dashboard/view/dashboard_screen.dart`, add a new tile constant near `_kTileReports` and include it in the `tiles` list built in `build()`:

```dart
const _kTileTransactions = _Tile(label: 'Transactions', icon: Icons.receipt_long_outlined, accent: Color(0xFF16A085), route: '/transactions');
```

```dart
    final tiles = [
      _kTileNew,
      _kTileTransactions,
      _kTileCatalog,
      _kTileReports,
      _kTileSettings,
      if (isAdmin) _kTileUsers,
    ];
```

- [ ] **Step 7: Commit**

```bash
cd mobile
git add lib/features/transactions/state/transactions_notifier.dart lib/features/transactions/view/transactions_screen.dart lib/core/navigation/router.dart lib/features/dashboard/view/dashboard_screen.dart test/features/transactions/state/transactions_notifier_test.dart
git commit -m "feat: add transaction history list screen"
```

---

### Task 3: Transaction detail screen with void action

**Files:**
- Create: `mobile/lib/features/transactions/view/transaction_detail_screen.dart`
- Test: `mobile/test/features/transactions/state/transactions_notifier_test.dart` (extend from Task 2)

- [ ] **Step 1: Extend the failing test** — append to `mobile/test/features/transactions/state/transactions_notifier_test.dart`:

```dart
  test('voidTransaction marks the sale voided and reflects in next load', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final saleId = await db.salesDao.insertSale(SalesTableCompanion.insert(total: 50, type: 'take_out'));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(transactionsProvider.future);
    await container.read(transactionsProvider.notifier).voidTransaction(saleId);
    final result = await container.read(transactionsProvider.future);

    expect(result.items.first.isVoided, isTrue);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd mobile && flutter test test/features/transactions/state/transactions_notifier_test.dart`
Expected: FAIL if `voidTransaction` wasn't already present — it was added in Task 2 Step 3, so this should already PASS. If it fails, verify `voidTransaction` exists on `TransactionsNotifier` before continuing (Task 2 must be complete first).

- [ ] **Step 3: Build the detail screen**

```dart
// mobile/lib/features/transactions/view/transaction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../entities/history_receipt_data.dart';
import '../state/transactions_notifier.dart';
import 'refund_screen.dart';

final _historyReceiptProvider =
    FutureProvider.family<HistoryReceiptData?, int>((ref, saleId) {
  final db = ref.watch(databaseProvider);
  return db.salesDao.getHistoryReceipt(saleId);
});

class TransactionDetailScreen extends ConsumerWidget {
  final int saleId;
  const TransactionDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(_historyReceiptProvider(saleId));
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Transaction #${saleId.toString().padLeft(6, '0')}')),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (receipt) {
          if (receipt == null) return const Center(child: Text('Transaction not found'));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(DateFormat('MMM d, yyyy • h:mm a').format(receipt.createdAt),
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              for (final item in receipt.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.productName),
                  subtitle: item.modifiers.isEmpty ? null : Text(item.modifiers.join(', ')),
                  trailing: Text('${item.qty} × ₱${item.unitPrice.toStringAsFixed(2)}'),
                ),
              const Divider(),
              _SummaryRow('Subtotal', receipt.subtotal),
              _SummaryRow('Discount', -receipt.discount),
              _SummaryRow('Total', receipt.total, bold: true),
              const SizedBox(height: AppSpacing.xl),
              if (isAdmin) ...[
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
      ),
    );
  }

  Future<void> _confirmVoid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void this transaction?'),
        content: const Text('This cannot be undone. The sale will be marked voided.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(transactionsProvider.notifier).voidTransaction(saleId);
    ref.invalidate(_historyReceiptProvider(saleId));
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTextStyles.headingSm : AppTextStyles.bodySm;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₱${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
```

Note: this references `RefundScreen`, built in Task 4. Leave the import — expect an analyzer error until Task 4 is complete.

- [ ] **Step 4: Commit** (after Task 4 makes the file resolvable — see Task 4 Step 4 for the combined commit point, OR commit now with a `// TODO(task-4)` stub `RefundScreen` if executing tasks out of order is not desired). Recommended: do Task 4 immediately next, then commit both together as shown in Task 4.

---

### Task 4: Refund screen with supervisor authorization

**Files:**
- Create: `mobile/lib/features/transactions/view/refund_screen.dart`
- Create: `mobile/lib/features/transactions/view/refund_auth_dialog.dart`
- Test: `mobile/test/core/database/daos/sales_dao_test.dart` (already covers `recordRefund` from Task 1 — no new DAO test needed; this task is UI-only, verified via the notifier test in Task 3 plus manual run)

Kiosk requires supervisor/admin PIN re-entry before a refund posts (`refund_authorization_dialog.dart`). Mobile's `UsersDao` / `AuthNotifier` already validate PINs for login — reuse that.

- [ ] **Step 1: Check the PIN-validation method mobile auth already exposes**

Run: `cd mobile && grep -n "validatePin\|verifyPin\|login" lib/features/auth/repositories/*.dart lib/features/auth/state/*.dart`

Use whatever method name this reveals in Step 3 below (the plan assumes a repository method shaped like `Future<bool> verifyPin(int userId, String pin)` exists per the login flow — if the actual signature differs, adapt the call in `refund_auth_dialog.dart` accordingly; do not invent a new auth pathway).

- [ ] **Step 2: Build the authorization dialog**

```dart
// mobile/lib/features/transactions/view/refund_auth_dialog.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/state/auth_providers.dart';

class RefundAuthDialog extends ConsumerStatefulWidget {
  const RefundAuthDialog({super.key});

  @override
  ConsumerState<RefundAuthDialog> createState() => _RefundAuthDialogState();
}

class _RefundAuthDialogState extends ConsumerState<RefundAuthDialog> {
  final _pinCtrl = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _checking = true; _error = null; });
    final ok = await ref.read(authNotifierProvider.notifier).verifySupervisorPin(_pinCtrl.text.trim());
    if (!mounted) return;
    setState(() => _checking = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Invalid PIN or insufficient permissions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Supervisor Authorization Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Supervisor / Admin PIN',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _checking ? null : _submit,
          child: _checking
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Authorize'),
        ),
      ],
    );
  }
}
```

This calls `ref.read(authNotifierProvider.notifier).verifySupervisorPin(pin)` — add that method to the existing `AuthNotifier` (in `mobile/lib/features/auth/state/auth_providers.dart` or wherever `AuthNotifier` is defined, found via Step 1's grep) with this shape:

```dart
  Future<bool> verifySupervisorPin(String pin) async {
    // Look up the currently-authenticated user's own credential check,
    // OR — if kiosk's model of "any admin/supervisor can authorize" applies —
    // check the PIN against any admin/supervisor user via the same
    // repository method used at login. Match whatever `_authRepository`
    // method the Step 1 grep revealed (e.g. `_authRepository.login(userId, pin)`
    // pattern adapted to search across admin/supervisor users instead of one user).
    return _authRepository.verifyAnyAdminPin(pin);
  }
```

(The exact repository method wiring depends on what Step 1's grep reveals about `AuthRepository`'s shape — this plan intentionally does not invent a signature since it depends on runtime discovery of the existing `login`/PIN-check implementation. Whoever executes this task must read that method and adapt `verifyAnyAdminPin` to reuse its PIN-hashing/comparison logic rather than duplicating it.)

- [ ] **Step 3: Build the refund screen**

```dart
// mobile/lib/features/transactions/view/refund_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../entities/history_receipt_data.dart';
import 'refund_auth_dialog.dart';

final _refundableItemsProvider =
    FutureProvider.family<List<HistoryReceiptItem>, int>((ref, saleId) {
  final db = ref.watch(databaseProvider);
  return db.salesDao.getRefundableItems(saleId);
});

class RefundScreen extends ConsumerStatefulWidget {
  final int saleId;
  const RefundScreen({super.key, required this.saleId});

  @override
  ConsumerState<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends ConsumerState<RefundScreen> {
  final Map<int, int> _selectedQty = {};
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(_refundableItemsProvider(widget.saleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Refund Items')),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Nothing left to refund on this sale'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final item in items) _RefundItemRow(
                item: item,
                selectedQty: _selectedQty[item.saleItemId] ?? 0,
                onChanged: (qty) => setState(() => _selectedQty[item.saleItemId] = qty),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton(
            onPressed: _submitting || _selectedQty.values.every((q) => q == 0)
                ? null
                : () => _submitRefund(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(double.infinity, AppSpacing.touchPreferred),
            ),
            child: Text('Refund ${_selectedTotalLabel(itemsAsync.valueOrNull ?? [])}'),
          ),
        ),
      ),
    );
  }

  String _selectedTotalLabel(List<HistoryReceiptItem> items) {
    final total = items.fold(0.0, (sum, i) {
      final qty = _selectedQty[i.saleItemId] ?? 0;
      return sum + (qty * i.unitPrice);
    });
    return total > 0 ? '₱${total.toStringAsFixed(2)}' : 'Selected Items';
  }

  Future<void> _submitRefund(BuildContext context) async {
    final authorized = await showDialog<bool>(
      context: context,
      builder: (_) => const RefundAuthDialog(),
    );
    if (authorized != true) return;

    setState(() => _submitting = true);
    final items = ref.read(_refundableItemsProvider(widget.saleId)).valueOrNull ?? [];
    final refundItems = <({int saleItemId, int qty})>[];
    var total = 0.0;
    for (final item in items) {
      final qty = _selectedQty[item.saleItemId] ?? 0;
      if (qty <= 0) continue;
      refundItems.add((saleItemId: item.saleItemId, qty: qty));
      total += qty * item.unitPrice;
    }

    final db = ref.read(databaseProvider);
    await db.salesDao.recordRefund(saleId: widget.saleId, total: total, items: refundItems);

    if (!context.mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();
  }
}

class _RefundItemRow extends StatelessWidget {
  final HistoryReceiptItem item;
  final int selectedQty;
  final ValueChanged<int> onChanged;

  const _RefundItemRow({required this.item, required this.selectedQty, required this.onChanged});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTextStyles.headingSm),
                Text('Available: ${item.qty} × ₱${item.unitPrice.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: selectedQty > 0 ? () => onChanged(selectedQty - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$selectedQty', style: AppTextStyles.headingSm),
          IconButton(
            onPressed: selectedQty < item.qty ? () => onChanged(selectedQty + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Regenerate code, analyze, and commit both Task 3 and Task 4 together**

```bash
cd mobile
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart analyze
git add lib/features/transactions/view/transaction_detail_screen.dart lib/features/transactions/view/refund_screen.dart lib/features/transactions/view/refund_auth_dialog.dart lib/features/auth/state/auth_providers.dart
git commit -m "feat: add transaction detail, refund, and void UI"
```

Expected `flutter analyze` output: no errors (warnings about unrelated pre-existing files are fine — do not fix those as part of this task).

---

### Task 5: Manual verification pass for Phase 1

- [ ] **Step 1: Run full mobile test suite**

Run: `cd mobile && fvm flutter test`
Expected: all tests pass, including the new `sales_dao_test.dart` and `transactions_notifier_test.dart`.

- [ ] **Step 2: Run the app and walk the golden path**

Run: `cd mobile && fvm flutter run -d windows` (or `-d android` if that's the target device for this session)

Manually verify:
1. Complete a sale from the Ordering screen.
2. Open Dashboard → Transactions — the sale appears.
3. Tap into the transaction — items, totals, cashier name render correctly.
4. As an admin user, tap "Refund Items" → select partial quantity → authorize with PIN → confirm the refund posts and remaining refundable quantity decreases.
5. Fully refund the remaining quantity — confirm status badge changes to "Refunded" in the list.
6. On a different sale, tap "Void Transaction" → confirm → confirm status badge changes to "Voided" and totals reflect void.

If any step fails, use `superpowers:systematic-debugging` before patching — do not guess-fix.

---

## Phases 2–6 (scoped, not yet task-detailed)

Each phase below is an independent subsystem. Before starting one, run this same `writing-plans` process again for that phase alone, grounded in the codebase as it exists at that time (file names/patterns may have shifted after Phase 1 lands).

### Phase 2 — Cashier Accounting (X-Reading, Z-Reading, Daily Report)
- Reference implementation: `kiosk/lib/features/reports/view/cashier_reports_screen.dart`, `cashier_z_reading_screen.dart`, `cashier_daily_report_screen.dart`, `report_preview_widgets.dart`, and the associated ESC/POS print use-cases in `kiosk/lib/features/reports/`.
- Mobile side needs: new DAO queries on `SalesDao` for per-cashier/per-shift aggregation (kiosk's "Sales by Cashier" query is a useful reference for the SQL shape), a "close shift" concept (kiosk's Z-Reading resets/closes a period — check whether kiosk persists a `z_reading` record; mobile's `sales_table` has no analogous table yet, so this phase likely needs a new Drift table + migration), a report-preview UI, and Bluetooth ESC/POS print wiring reusing mobile's existing printer setup (`features/settings/view/printer_setup_screen.dart`).
- Flag for the follow-up plan: whether "Z-Reading" on mobile should hard-close/lock past sales the way kiosk does, given mobile has no backend to reconcile against.

### Phase 3 — Catalog CRUD (products, categories, modifier groups)
- Reference implementation: `kiosk/lib/features/catalog/` — `product_dialogs.dart`, `category_dialogs.dart`, `modifier_groups_screen.dart`.
- Mobile side needs: `ProductsDao` already has read/toggle methods (`getAllActiveGroups`, `getAllProducts`, `toggleProductAvailability` — confirmed in `catalog_notifier.dart`); this phase adds insert/update/delete methods to `ProductsDao`, then create/edit dialogs mirroring kiosk's, wired into `catalog_screen.dart`. Since mobile's catalog is currently CSV-import-only, decide whether CSV import and manual CRUD should coexist (likely yes — CSV for bulk seed, CRUD for field edits) and whether product images need a picker (kiosk stores `imageUrl` as text per backend migration `1779582000000`; mobile's `products_table` — confirm column shape before reusing that assumption).

### Phase 4 — Sales Reports depth (charts + export)
- Reference implementation: `kiosk/lib/features/reports/view/sales_health_page.dart`, `sales_bar_chart.dart`, `export_notifier.dart`, `unexported_export_dialog.dart`.
- Mobile side needs: a charting package (check `mobile/pubspec.yaml` for one already present, e.g. `fl_chart`, before adding a new dependency), extending `ReportsNotifier`/`ReportData` with by-cashier and by-group breakdowns (the underlying SQL exists in kiosk's report queries as a reference), and a file-export action (mobile would need a share/export mechanism appropriate to its platform — Android share sheet vs. Windows file save — this needs a platform decision before planning).

### Phase 5 — POS Terminal / Franchisee setup
- Reference implementation: `kiosk/lib/features/menu/` (or wherever `RegisterPosTerminalDialog`, `PosTerminalDetailsDialog`, `FranchiseeInfoDialog` live — re-locate via grep at plan time) capturing legal name, address, TIN, payment methods.
- Mobile side needs: extend `store_info_table`/`StoreInfoDao` (currently only name/address/tax rate/currency/footer per `store_info_screen.dart`) with TIN and payment-methods fields, or a new `terminal_info_table`, plus a form screen mirroring `store_info_screen.dart`'s existing pattern.

### Phase 6 — Polish
- PIN setup flow equivalent to kiosk's `SetupPinScreen` (first-run PIN creation, if mobile's current PIN model has an analogous gap).
- Device identifier on printed receipts (kiosk: `kiosk/lib/services/device/device_serial_number.dart`) — decide the mobile equivalent (Android device ID vs. a user-set terminal name) before planning, since serial number retrieval is inherently platform-specific.
- Dine-in table/location selection step (kiosk: `ChooseLocationScreen`) — mobile's `PaymentScreen` currently only has an order-type selector (Dine In/Take Out/Delivery) with no table assignment; low priority unless the business needs table tracking.

---

## Self-Review Notes

- **Spec coverage:** Every row in the Gap Summary table maps to a phase. Phase 1 fully covers the two "High risk" rows (transactions/void/refunds). Phases 2–6 are intentionally scoped, not detailed, per the multi-subsystem rule — this is documented above, not an omission.
- **No blind trust in memory-only claims:** Task 4's PIN-verification step explicitly requires the executor to grep the real `AuthRepository`/`AuthNotifier` shape before wiring `verifySupervisorPin`, since this plan was written without reading that file's exact contents and must not invent a signature that doesn't match reality.
- **Type consistency:** `TransactionsPage`, `TransactionsNotifier`, `recordRefund`'s record-type parameter, and `HistoryReceiptItem` are used consistently across Tasks 2–4 with the same shapes throughout.
