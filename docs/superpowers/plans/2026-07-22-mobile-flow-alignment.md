# Mobile Flow Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Transactions screen (with void/refund/reprint) and align role-based dashboard visibility so the mobile app matches the kiosk app's user flow exactly.

**Architecture:** All new code lives under `mobile/lib/features/transactions/`. The existing `SalesDao` gets new join-based queries. The GoRouter gains three routes (`/transactions`, `/transactions/receipt/:id`, `/transactions/refund/:id`) and the Dashboard gains a Transactions tile with role-based filtering (cashier → New Order + Transactions only; admin → all tiles).

**Tech Stack:** Flutter, Hooks Riverpod (AsyncNotifier), Drift 2.24 (SQLite typed joins), GoRouter 17, intl

---

## File Map

**Create (new files):**
- `mobile/lib/features/transactions/entities/transaction_summary.dart`
- `mobile/lib/features/transactions/entities/history_receipt_data.dart`
- `mobile/lib/features/transactions/state/transactions_notifier.dart`
- `mobile/lib/features/transactions/state/refund_notifier.dart`
- `mobile/lib/features/transactions/view/transactions_screen.dart`
- `mobile/lib/features/transactions/view/transaction_receipt_screen.dart`
- `mobile/lib/features/transactions/view/refund_screen.dart`

**Modify (existing files):**
- `mobile/lib/core/database/daos/sales_dao.dart` — add UsersTable/ProductsTable, add 5 new queries
- `mobile/lib/core/navigation/router.dart` — add 3 routes
- `mobile/lib/features/dashboard/view/dashboard_screen.dart` — add Transactions tile + role-based visibility

---

## Task 1: Transaction entity models

**Files:**
- Create: `mobile/lib/features/transactions/entities/transaction_summary.dart`
- Create: `mobile/lib/features/transactions/entities/history_receipt_data.dart`

- [ ] **Step 1: Create TransactionSummary**

```dart
// mobile/lib/features/transactions/entities/transaction_summary.dart

class TransactionSummary {
  final int id;
  final String cashierName;
  final DateTime createdAt;
  final double total;
  final double discount;
  final String status;
  final String type;
  final double refundedAmount;

  const TransactionSummary({
    required this.id,
    required this.cashierName,
    required this.createdAt,
    required this.total,
    required this.discount,
    required this.status,
    required this.type,
    required this.refundedAmount,
  });

  bool get isVoided => status == 'voided';
  double get netTotal => (total - discount - refundedAmount).clamp(0.0, double.infinity);
  bool get hasRefunds => refundedAmount > 0;
  bool get isFullyRefunded => refundedAmount >= (total - discount) - 0.001;
  String get invoiceNumber => '#${id.toString().padLeft(6, '0')}';

  String get displayType => switch (type) {
        'dine_in' => 'Dine In',
        'take_out' => 'Take Out',
        'delivery' => 'Delivery',
        _ => type,
      };
}
```

- [ ] **Step 2: Create HistoryReceiptData (for reprint from history)**

```dart
// mobile/lib/features/transactions/entities/history_receipt_data.dart

class HistoryReceiptItem {
  final int saleItemId;
  final String productName;
  final int qty;
  final double unitPrice;
  final List<String> modifiers;

  const HistoryReceiptItem({
    required this.saleItemId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.modifiers,
  });

  double get lineTotal => qty * unitPrice;
}

class HistoryReceiptData {
  final int saleId;
  final DateTime createdAt;
  final String saleType;
  final String cashierName;
  final List<HistoryReceiptItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final double amountPaid;
  final double change;
  final String? reference;

  const HistoryReceiptData({
    required this.saleId,
    required this.createdAt,
    required this.saleType,
    required this.cashierName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    required this.reference,
  });

  String get invoiceNumber => '#${saleId.toString().padLeft(6, '0')}';
}
```

---

## Task 2: Extend SalesDao with transaction queries

**Files:**
- Modify: `mobile/lib/core/database/daos/sales_dao.dart`

- [ ] **Step 1: Add UsersTable and ProductsTable imports + update @DriftAccessor**

Replace the top of `sales_dao.dart` (imports + annotation) with:

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sales_table.dart';
import '../tables/sale_items_table.dart';
import '../tables/sale_item_modifiers_table.dart';
import '../tables/payments_table.dart';
import '../tables/refunds_table.dart';
import '../tables/refund_items_table.dart';
import '../tables/users_table.dart';
import '../tables/products_table.dart';
import '../../features/transactions/entities/transaction_summary.dart';
import '../../features/transactions/entities/history_receipt_data.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [
  SalesTable,
  SaleItemsTable,
  SaleItemModifiersTable,
  PaymentsTable,
  RefundsTable,
  RefundItemsTable,
  UsersTable,
  ProductsTable,
])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);
```

- [ ] **Step 2: Run build_runner to regenerate sales_dao.g.dart**

```bash
cd mobile
fvm dart run build_runner build --delete-conflicting-outputs
```

Expected: exits 0, regenerates `mobile/lib/core/database/daos/sales_dao.g.dart`

- [ ] **Step 3: Add getTransactions query (typed join, safe DateTime)**

Append to `SalesDao` class body (inside `class SalesDao`):

```dart
  Future<List<TransactionSummary>> getTransactions({
    DateTime? date,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    final q = select(salesTable).join([
      leftOuterJoin(usersTable, usersTable.id.equalsExp(salesTable.cashierId)),
    ]);

    if (date != null) {
      final from = DateTime(date.year, date.month, date.day);
      final to = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      q.where(salesTable.createdAt.isBetweenValues(from, to));
    }

    final searchId = int.tryParse((search ?? '').replaceAll('#', ''));
    if (searchId != null) q.where(salesTable.id.equals(searchId));

    q.orderBy([OrderingTerm.desc(salesTable.createdAt)]);
    q.limit(limit, offset: offset);

    final rows = await q.get();
    final saleIds = rows.map((r) => r.readTable(salesTable).id).toList();
    final refundedByIds = await _refundedAmountsBySaleIds(saleIds);

    return rows.map((row) {
      final sale = row.readTable(salesTable);
      final user = row.readTableOrNull(usersTable);
      return TransactionSummary(
        id: sale.id,
        cashierName: user?.name ?? 'Unknown',
        createdAt: sale.createdAt,
        total: sale.total,
        discount: sale.discount,
        status: sale.status,
        type: sale.type,
        refundedAmount: refundedByIds[sale.id] ?? 0,
      );
    }).toList();
  }

  Future<Map<int, double>> _refundedAmountsBySaleIds(List<int> ids) async {
    if (ids.isEmpty) return {};
    final refunds = await (select(refundsTable)
          ..where((t) => t.saleId.isIn(ids)))
        .get();
    final map = <int, double>{};
    for (final r in refunds) {
      map[r.saleId] = (map[r.saleId] ?? 0) + r.total;
    }
    return map;
  }

  Future<int> getTransactionCount({DateTime? date, String? search}) async {
    final q = selectOnly(salesTable)..addColumns([salesTable.id.count()]);

    if (date != null) {
      final from = DateTime(date.year, date.month, date.day);
      final to = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      q.where(salesTable.createdAt.isBetweenValues(from, to));
    }

    final searchId = int.tryParse((search ?? '').replaceAll('#', ''));
    if (searchId != null) q.where(salesTable.id.equals(searchId));

    final row = await q.getSingle();
    return row.read(salesTable.id.count()) ?? 0;
  }
```

- [ ] **Step 4: Add getHistoryReceipt query (for reprint)**

Append to `SalesDao` class body:

```dart
  Future<HistoryReceiptData?> getHistoryReceipt(int saleId) async {
    // Sale + cashier name
    final saleQ = select(salesTable).join([
      leftOuterJoin(usersTable, usersTable.id.equalsExp(salesTable.cashierId)),
    ]);
    saleQ.where(salesTable.id.equals(saleId));
    final saleRow = await saleQ.getSingleOrNull();
    if (saleRow == null) return null;

    final sale = saleRow.readTable(salesTable);
    final user = saleRow.readTableOrNull(usersTable);

    // Items + product names
    final itemQ = select(saleItemsTable).join([
      leftOuterJoin(productsTable, productsTable.id.equalsExp(saleItemsTable.productId)),
    ]);
    itemQ.where(saleItemsTable.saleId.equals(saleId));
    final itemRows = await itemQ.get();

    final items = <HistoryReceiptItem>[];
    for (final ir in itemRows) {
      final item = ir.readTable(saleItemsTable);
      final product = ir.readTableOrNull(productsTable);
      final mods = await (select(saleItemModifiersTable)
            ..where((t) => t.itemId.equals(item.id)))
          .get();
      items.add(HistoryReceiptItem(
        saleItemId: item.id,
        productName: product?.name ?? 'Unknown Product',
        qty: item.qty,
        unitPrice: item.unitPrice,
        modifiers: mods.map((m) => m.modifierName).toList(),
      ));
    }

    // Payment
    final payments = await (select(paymentsTable)
          ..where((t) => t.saleId.equals(saleId)))
        .get();
    final payment = payments.isEmpty ? null : payments.first;

    final subtotal = items.fold(0.0, (s, i) => s + i.lineTotal);
    final total = sale.total - sale.discount;
    final amountPaid = payment?.amount ?? 0;
    final change = payment?.method == 'cash'
        ? (amountPaid - total).clamp(0.0, double.infinity)
        : 0.0;

    return HistoryReceiptData(
      saleId: sale.id,
      createdAt: sale.createdAt,
      saleType: sale.type,
      cashierName: user?.name ?? 'Unknown',
      items: items,
      subtotal: subtotal,
      discount: sale.discount,
      total: total,
      paymentMethod: payment?.method ?? 'cash',
      amountPaid: amountPaid,
      change: change,
      reference: payment?.reference,
    );
  }
```

- [ ] **Step 5: Add getRefundableItems query (for refund screen)**

Append to `SalesDao` class body:

```dart
  Future<List<HistoryReceiptItem>> getRefundableItems(int saleId) async {
    final itemQ = select(saleItemsTable).join([
      leftOuterJoin(productsTable, productsTable.id.equalsExp(saleItemsTable.productId)),
    ]);
    itemQ.where(saleItemsTable.saleId.equals(saleId));
    final itemRows = await itemQ.get();

    // Get already-refunded qty per sale item
    final refunds = await (select(refundsTable)
          ..where((t) => t.saleId.equals(saleId)))
        .get();
    final refundedQty = <int, int>{};
    for (final r in refunds) {
      final ris = await (select(refundItemsTable)
            ..where((t) => t.refundId.equals(r.id)))
          .get();
      for (final ri in ris) {
        refundedQty[ri.saleItemId] = (refundedQty[ri.saleItemId] ?? 0) + ri.qty;
      }
    }

    final result = <HistoryReceiptItem>[];
    for (final ir in itemRows) {
      final item = ir.readTable(saleItemsTable);
      final product = ir.readTableOrNull(productsTable);
      final alreadyRefunded = refundedQty[item.id] ?? 0;
      final available = item.qty - alreadyRefunded;
      if (available <= 0) continue;
      result.add(HistoryReceiptItem(
        saleItemId: item.id,
        productName: product?.name ?? 'Unknown Product',
        qty: available,
        unitPrice: item.unitPrice,
        modifiers: const [],
      ));
    }
    return result;
  }
```

---

## Task 3: TransactionsNotifier

**Files:**
- Create: `mobile/lib/features/transactions/state/transactions_notifier.dart`

- [ ] **Step 1: Create TransactionsState + TransactionsNotifier**

```dart
// mobile/lib/features/transactions/state/transactions_notifier.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../entities/transaction_summary.dart';

class TransactionsState {
  final List<TransactionSummary> items;
  final int page;
  final int totalPages;
  final DateTime? date;
  final String? search;
  static const int kLimit = 20;

  const TransactionsState({
    required this.items,
    this.page = 1,
    this.totalPages = 1,
    this.date,
    this.search,
  });

  TransactionsState copyWith({
    List<TransactionSummary>? items,
    int? page,
    int? totalPages,
    DateTime? Function()? date,
    String? Function()? search,
  }) =>
      TransactionsState(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        date: date != null ? date() : this.date,
        search: search != null ? search() : this.search,
      );
}

class TransactionsNotifier extends AsyncNotifier<TransactionsState> {
  @override
  Future<TransactionsState> build() =>
      _load(const TransactionsState(items: []));

  Future<TransactionsState> _load(TransactionsState params) async {
    final db = ref.read(databaseProvider);
    final items = await db.salesDao.getTransactions(
      date: params.date,
      search: params.search,
      limit: TransactionsState.kLimit,
      offset: (params.page - 1) * TransactionsState.kLimit,
    );
    final count = await db.salesDao.getTransactionCount(
      date: params.date,
      search: params.search,
    );
    final totalPages =
        (count / TransactionsState.kLimit).ceil().clamp(1, 99999);
    return params.copyWith(items: items, totalPages: totalPages);
  }

  Future<void> setPage(int page) async {
    final current = state.value!;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(current.copyWith(page: page)));
  }

  Future<void> setDate(DateTime? date) async {
    final current = state.value!;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _load(current.copyWith(date: () => date, page: 1)),
    );
  }

  Future<void> setSearch(String? search) async {
    final current = state.value!;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _load(current.copyWith(search: () => search, page: 1)),
    );
  }

  Future<void> refresh() async {
    final current = state.value ?? const TransactionsState(items: []);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(current));
  }

  Future<void> voidSale(int saleId) async {
    final db = ref.read(databaseProvider);
    await db.salesDao.voidSale(saleId);
    await refresh();
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, TransactionsState>(
  TransactionsNotifier.new,
);
```

---

## Task 4: RefundNotifier

**Files:**
- Create: `mobile/lib/features/transactions/state/refund_notifier.dart`

- [ ] **Step 1: Create RefundItem + RefundNotifier**

```dart
// mobile/lib/features/transactions/state/refund_notifier.dart

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/database/tables/refunds_table.dart';
import '../../../core/database/tables/refund_items_table.dart';
import '../entities/history_receipt_data.dart';

class RefundItem {
  final HistoryReceiptItem source;
  int selectedQty;

  RefundItem({required this.source, this.selectedQty = 0});

  double get refundAmount => selectedQty * source.unitPrice;
}

class RefundState {
  final int saleId;
  final List<RefundItem> items;
  final String reason;
  final bool isSubmitting;

  const RefundState({
    required this.saleId,
    required this.items,
    this.reason = '',
    this.isSubmitting = false,
  });

  double get totalRefund =>
      items.fold(0.0, (s, i) => s + i.refundAmount);

  bool get canSubmit =>
      !isSubmitting && reason.trim().isNotEmpty && totalRefund > 0;

  RefundState copyWith({
    List<RefundItem>? items,
    String? reason,
    bool? isSubmitting,
  }) =>
      RefundState(
        saleId: saleId,
        items: items ?? this.items,
        reason: reason ?? this.reason,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

class RefundNotifier extends FamilyAsyncNotifier<RefundState, int> {
  @override
  Future<RefundState> build(int saleId) async {
    final db = ref.read(databaseProvider);
    final refundableItems = await db.salesDao.getRefundableItems(saleId);
    return RefundState(
      saleId: saleId,
      items: refundableItems.map((i) => RefundItem(source: i)).toList(),
    );
  }

  void setQty(int saleItemId, int qty) {
    state = state.whenData((s) {
      final updated = s.items.map((item) {
        if (item.source.saleItemId != saleItemId) return item;
        return RefundItem(
          source: item.source,
          selectedQty: qty.clamp(0, item.source.qty),
        );
      }).toList();
      return s.copyWith(items: updated);
    });
  }

  void setReason(String reason) {
    state = state.whenData((s) => s.copyWith(reason: reason));
  }

  Future<bool> submit() async {
    final s = state.value;
    if (s == null || !s.canSubmit) return false;

    state = AsyncData(s.copyWith(isSubmitting: true));

    try {
      final db = ref.read(databaseProvider);

      final refundId = await db.salesDao.insertRefund(
        RefundsTableCompanion.insert(
          saleId: s.saleId,
          reason: s.reason.trim(),
          total: s.totalRefund,
          createdAt: DateTime.now(),
        ),
      );

      for (final item in s.items.where((i) => i.selectedQty > 0)) {
        await db.salesDao.insertRefundItem(
          RefundItemsTableCompanion.insert(
            refundId: refundId,
            saleItemId: item.source.saleItemId,
            qty: item.selectedQty,
            amount: item.refundAmount,
          ),
        );
      }

      return true;
    } catch (_) {
      state = AsyncData(s.copyWith(isSubmitting: false));
      return false;
    }
  }
}

final refundProvider =
    AsyncNotifierProviderFamily<RefundNotifier, RefundState, int>(
  RefundNotifier.new,
);
```

---

## Task 5: TransactionsScreen

**Files:**
- Create: `mobile/lib/features/transactions/view/transactions_screen.dart`

- [ ] **Step 1: Create the screen**

```dart
// mobile/lib/features/transactions/view/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
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
    final txState = ref.watch(transactionsProvider);
    final notifier = ref.read(transactionsProvider.notifier);

    final searchCtrl = useTextEditingController();
    final searchDebounce = useRef<Future<void>?>(null);

    useEffect(() {
      Future.microtask(() => notifier.refresh());
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.refresh,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Filter bar ───────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md,
            ),
            child: txState.when(
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox(height: 40),
              data: (s) => Column(
                children: [
                  _FilterRow(
                    notifier: notifier,
                    currentDate: s.date,
                    searchCtrl: searchCtrl,
                    onSearchChanged: (v) {
                      notifier.setSearch(v.isEmpty ? null : v);
                    },
                  ),
                  const Gap(AppSpacing.xs),
                  _PaginationRow(
                    page: s.page,
                    totalPages: s.totalPages,
                    onPrev: s.page > 1 ? () => notifier.setPage(s.page - 1) : null,
                    onNext: s.page < s.totalPages ? () => notifier.setPage(s.page + 1) : null,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ── Transaction list ─────────────────────────────────────────
          Expanded(
            child: txState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const Gap(AppSpacing.md),
                    Text('Failed to load', style: AppTextStyles.headingSm),
                    const Gap(AppSpacing.sm),
                    FilledButton(
                      onPressed: notifier.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (s) {
                if (s.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 56, color: AppColors.textDisabled),
                        const Gap(AppSpacing.md),
                        Text('No transactions found',
                            style: AppTextStyles.headingSm
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: s.items.length,
                  separatorBuilder: (_, __) => const Gap(AppSpacing.sm),
                  itemBuilder: (_, i) => _TransactionCard(
                    tx: s.items[i],
                    notifier: notifier,
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

// ── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final TransactionsNotifier notifier;
  final DateTime? currentDate;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;

  const _FilterRow({
    required this.notifier,
    required this.currentDate,
    required this.searchCtrl,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearchChanged,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                hintText: 'Search by invoice #',
                hintStyle:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.textDisabled),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const Gap(AppSpacing.sm),
        // Date filter
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: currentDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(primary: AppColors.primary),
                ),
                child: child!,
              ),
            );
            if (picked != null) notifier.setDate(picked);
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: currentDate != null
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16,
                    color: currentDate != null ? Colors.white : AppColors.textSecondary),
                if (currentDate != null) ...[
                  const Gap(4),
                  Text(
                    DateFormat('MM/dd/yy').format(currentDate!),
                    style: AppTextStyles.labelMd.copyWith(color: Colors.white),
                  ),
                  const Gap(4),
                  GestureDetector(
                    onTap: () => notifier.setDate(null),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Pagination row ────────────────────────────────────────────────────────────

class _PaginationRow extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationRow({
    required this.page,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: onPrev,
          color: AppColors.primary,
          iconSize: 20,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
        const Gap(AppSpacing.sm),
        Text(
          'Page $page of $totalPages',
          style: AppTextStyles.bodyMd
              .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
        const Gap(AppSpacing.sm),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: onNext,
          color: AppColors.primary,
          iconSize: 20,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

// ── Transaction card ──────────────────────────────────────────────────────────

class _TransactionCard extends HookWidget {
  final TransactionSummary tx;
  final TransactionsNotifier notifier;

  const _TransactionCard({required this.tx, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final expanded = useState(false);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — tap to expand
          InkWell(
            onTap: () => expanded.value = !expanded.value,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: expanded.value ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColors.primary),
                  ),
                  const Gap(AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              tx.invoiceNumber,
                              style: AppTextStyles.labelLg.copyWith(
                                fontWeight: FontWeight.w700,
                                color: tx.isVoided
                                    ? AppColors.textDisabled
                                    : AppColors.textPrimary,
                                decoration: tx.isVoided
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const Gap(AppSpacing.xs),
                            if (tx.isVoided)
                              _StatusBadge('VOIDED', AppColors.error),
                            if (tx.hasRefunds && !tx.isVoided)
                              _StatusBadge('REFUNDED', AppColors.warning),
                          ],
                        ),
                        const Gap(2),
                        Text(
                          '${tx.cashierName}  ·  ${DateFormat('MM/dd/yy hh:mm a').format(tx.createdAt)}',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (tx.hasRefunds && !tx.isVoided) ...[
                        Text(
                          'PHP ${(tx.total - tx.discount).toStringAsFixed(2)}',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textDisabled,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      Text(
                        'PHP ${tx.isVoided ? (tx.total - tx.discount).toStringAsFixed(2) : tx.netTotal.toStringAsFixed(2)}',
                        style: AppTextStyles.headingSm.copyWith(
                          color: tx.isVoided
                              ? AppColors.textDisabled
                              : AppColors.primary,
                          decoration:
                              tx.isVoided ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded actions
          if (expanded.value)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                border:
                    Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Reprint
                  TextButton.icon(
                    onPressed: () =>
                        context.push('/transactions/receipt/${tx.id}'),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Reprint'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  // Refund
                  TextButton.icon(
                    onPressed: (tx.isVoided || tx.isFullyRefunded)
                        ? null
                        : () async {
                            await context
                                .push('/transactions/refund/${tx.id}');
                            notifier.refresh();
                          },
                    icon: const Icon(Icons.assignment_return_outlined, size: 16),
                    label: const Text('Refund'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.warning,
                    ),
                  ),
                  // Void
                  TextButton.icon(
                    onPressed: tx.isVoided
                        ? null
                        : () => _confirmVoid(context, notifier, tx),
                    icon: const Icon(Icons.block_rounded, size: 16),
                    label: const Text('Void'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmVoid(
    BuildContext context,
    TransactionsNotifier notifier,
    TransactionSummary tx,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Transaction'),
        content: Text(
          'Void ${tx.invoiceNumber}?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await notifier.voidSale(tx.id);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
```

---

## Task 6: TransactionReceiptScreen (Reprint)

**Files:**
- Create: `mobile/lib/features/transactions/view/transaction_receipt_screen.dart`

- [ ] **Step 1: Create the screen**

```dart
// mobile/lib/features/transactions/view/transaction_receipt_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/print_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/ordering/entities/sale_receipt_data.dart';
import '../../../features/ordering/entities/cart_item.dart';
import '../entities/history_receipt_data.dart';

class TransactionReceiptScreen extends HookConsumerWidget {
  final int saleId;
  const TransactionReceiptScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = useMemoized(
      () => ref.read(databaseProvider).salesDao.getHistoryReceipt(saleId),
    );
    final snapshot = useFuture(receiptAsync);
    final printing = useState(false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Receipt ${_invoice(saleId)}'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: switch (snapshot.connectionState) {
        ConnectionState.waiting => const Center(child: CircularProgressIndicator()),
        ConnectionState.done when snapshot.data == null =>
          const Center(child: Text('Receipt not found')),
        _ => _ReceiptBody(
            receipt: snapshot.data!,
            printing: printing,
          ),
      },
    );
  }

  String _invoice(int id) => '#${id.toString().padLeft(6, '0')}';
}

class _ReceiptBody extends StatelessWidget {
  final HistoryReceiptData receipt;
  final ValueNotifier<bool> printing;

  const _ReceiptBody({required this.receipt, required this.printing});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Receipt card ──────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow('Invoice', receipt.invoiceNumber),
                    const Gap(4),
                    _InfoRow('Cashier', receipt.cashierName),
                    const Gap(4),
                    _InfoRow('Date', _formatDate(receipt.createdAt)),
                    const Gap(4),
                    _InfoRow('Type', _formatType(receipt.saleType)),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ITEMS',
                        style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.textDisabled, letterSpacing: 0.8)),
                    const Gap(AppSpacing.sm),
                    ...receipt.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('x${item.qty}',
                                style: AppTextStyles.bodyMd.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600)),
                            const Gap(AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName,
                                      style: AppTextStyles.bodyMd.copyWith(
                                          fontWeight: FontWeight.w500)),
                                  if (item.modifiers.isNotEmpty)
                                    Text(
                                      item.modifiers.join(', '),
                                      style: AppTextStyles.bodySm.copyWith(
                                          color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'PHP ${item.lineTotal.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMd
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _TotalRow('Subtotal', receipt.subtotal, secondary: true),
                    if (receipt.discount > 0)
                      _TotalRow('Discount', -receipt.discount,
                          secondary: true, color: AppColors.warning),
                    const Gap(4),
                    _TotalRow('TOTAL', receipt.total, large: true),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAYMENT',
                        style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.textDisabled, letterSpacing: 0.8)),
                    const Gap(AppSpacing.sm),
                    _InfoRow('Method', _formatMethod(receipt.paymentMethod)),
                    if (receipt.paymentMethod == 'cash') ...[
                      const Gap(4),
                      _InfoRow('Tendered',
                          'PHP ${receipt.amountPaid.toStringAsFixed(2)}'),
                      const Gap(4),
                      _InfoRow('Change',
                          'PHP ${receipt.change.toStringAsFixed(2)}',
                          valueColor: AppColors.success),
                    ] else if (receipt.reference != null) ...[
                      const Gap(4),
                      _InfoRow('Reference', receipt.reference!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.xl),

        // ── Print button ──────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: printing.value
              ? null
              : () => _print(context, receipt, printing),
          icon: printing.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print_outlined),
          label: const Text('Print Receipt'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize:
                const Size(double.infinity, AppSpacing.touchMin),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Future<void> _print(
    BuildContext context,
    HistoryReceiptData receipt,
    ValueNotifier<bool> printing,
  ) async {
    printing.value = true;
    try {
      // Convert to SaleReceiptData for PrintService
      final receiptData = SaleReceiptData(
        saleId: receipt.saleId,
        createdAt: receipt.createdAt,
        saleType: receipt.saleType,
        items: receipt.items
            .map((i) => CartItem(
                  cartId: i.saleItemId.toString(),
                  productId: i.saleItemId,
                  productName: i.productName,
                  groupName: '',
                  imageUrl: null,
                  basePrice: i.unitPrice,
                  quantity: i.qty,
                  modifiers: const [],
                ))
            .toList(),
        subtotal: receipt.subtotal,
        totalDiscount: receipt.discount,
        total: receipt.total,
        paymentMethod: receipt.paymentMethod,
        amountPaid: receipt.amountPaid,
        change: receipt.change,
        reference: receipt.reference,
        cashierName: receipt.cashierName,
      );
      final ok = await PrintService.printReceipt(receiptData);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Receipt printed'
              : 'No printer configured — go to Settings → Printer Setup'),
          backgroundColor: ok ? null : AppColors.warning,
        ));
      }
    } finally {
      printing.value = false;
    }
  }

  String _formatDate(DateTime dt) {
    final d = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  String _formatType(String t) => switch (t) {
        'dine_in' => 'Dine In',
        'take_out' => 'Take Out',
        'delivery' => 'Delivery',
        _ => t,
      };

  String _formatMethod(String m) => switch (m) {
        'cash' => 'Cash',
        'card' => 'Card',
        'ewallet' => 'E-Wallet',
        _ => m,
      };
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool secondary;
  final bool large;
  final Color? color;

  const _TotalRow(this.label, this.amount,
      {this.secondary = false, this.large = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: large
                  ? AppTextStyles.headingSm
                  : AppTextStyles.bodyMd
                      .copyWith(color: AppColors.textSecondary)),
          Text(
            amount < 0
                ? '-PHP ${(-amount).toStringAsFixed(2)}'
                : 'PHP ${amount.toStringAsFixed(2)}',
            style: large
                ? AppTextStyles.priceMd.copyWith(color: color ?? AppColors.primary)
                : AppTextStyles.bodyMd.copyWith(
                    color: color ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
```

---

## Task 7: RefundScreen

**Files:**
- Create: `mobile/lib/features/transactions/view/refund_screen.dart`

- [ ] **Step 1: Create the refund screen**

```dart
// mobile/lib/features/transactions/view/refund_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../state/refund_notifier.dart';

class RefundScreen extends HookConsumerWidget {
  final int saleId;
  const RefundScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(refundProvider(saleId));
    final notifier = ref.read(refundProvider(saleId).notifier);
    final reasonCtrl = useTextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Refund #${saleId.toString().padLeft(6, '0')}'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load items: $e',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
        ),
        data: (s) {
          if (s.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 56, color: AppColors.success),
                  const Gap(AppSpacing.md),
                  Text('All items already refunded',
                      style: AppTextStyles.headingSm
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Reason
                    Text('Reason',
                        style: AppTextStyles.labelLg
                            .copyWith(color: AppColors.textSecondary)),
                    const Gap(AppSpacing.xs),
                    TextField(
                      controller: reasonCtrl,
                      onChanged: notifier.setReason,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Customer changed mind…',
                        hintStyle: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.textDisabled),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.lg),

                    // Items
                    Text('Select Items to Refund',
                        style: AppTextStyles.labelLg
                            .copyWith(color: AppColors.textSecondary)),
                    const Gap(AppSpacing.sm),
                    ...s.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(
                            color: item.selectedQty > 0
                                ? AppColors.primary
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.source.productName,
                                      style: AppTextStyles.bodyMd.copyWith(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    'PHP ${item.source.unitPrice.toStringAsFixed(2)} × available: ${item.source.qty}',
                                    style: AppTextStyles.bodySm.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            // Qty stepper
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _SmallBtn(
                                  icon: Icons.remove_rounded,
                                  onTap: item.selectedQty > 0
                                      ? () => notifier.setQty(
                                          item.source.saleItemId,
                                          item.selectedQty - 1)
                                      : null,
                                ),
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${item.selectedQty}',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.headingSm,
                                  ),
                                ),
                                _SmallBtn(
                                  icon: Icons.add_rounded,
                                  filled: true,
                                  onTap: item.selectedQty < item.source.qty
                                      ? () => notifier.setQty(
                                          item.source.saleItemId,
                                          item.selectedQty + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Footer ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Refund Total',
                            style: AppTextStyles.headingSm),
                        Text(
                          'PHP ${s.totalRefund.toStringAsFixed(2)}',
                          style: AppTextStyles.priceMd
                              .copyWith(color: AppColors.error),
                        ),
                      ],
                    ),
                    const Gap(AppSpacing.md),
                    FilledButton(
                      onPressed: s.canSubmit
                          ? () => _submit(context, notifier)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        minimumSize: const Size(
                            double.infinity, AppSpacing.touchPreferred),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                      ),
                      child: s.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Confirm Refund'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    RefundNotifier notifier,
  ) async {
    final ok = await notifier.submit();
    if (context.mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund processed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process refund. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  const _SmallBtn({required this.icon, this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 14,
            color: filled
                ? Colors.white
                : onTap != null ? AppColors.primary : AppColors.textDisabled),
      ),
    );
  }
}
```

---

## Task 8: Router + Dashboard updates

**Files:**
- Modify: `mobile/lib/core/navigation/router.dart`
- Modify: `mobile/lib/features/dashboard/view/dashboard_screen.dart`

- [ ] **Step 1: Add three routes to router.dart**

In `mobile/lib/core/navigation/router.dart`, add these imports:

```dart
import '../../features/transactions/view/transactions_screen.dart';
import '../../features/transactions/view/transaction_receipt_screen.dart';
import '../../features/transactions/view/refund_screen.dart';
```

Then add to the `routes:` list inside `GoRouter(...)`:

```dart
GoRoute(
  path: '/transactions',
  builder: (context, state) => const TransactionsScreen(),
  routes: [
    GoRoute(
      path: 'receipt/:saleId',
      builder: (context, state) => TransactionReceiptScreen(
        saleId: int.parse(state.pathParameters['saleId']!),
      ),
    ),
    GoRoute(
      path: 'refund/:saleId',
      builder: (context, state) => RefundScreen(
        saleId: int.parse(state.pathParameters['saleId']!),
      ),
    ),
  ],
),
```

- [ ] **Step 2: Update DashboardScreen — add Transactions tile + role-based visibility**

In `mobile/lib/features/dashboard/view/dashboard_screen.dart`, replace the tiles list:

```dart
// Replace the existing tiles list at the top of the file with:

const _kTileNew   = _Tile(label: 'New Order',     icon: Icons.shopping_cart_outlined,   accent: Color(0xFF1B7A8C), route: '/order');
const _kTileTx    = _Tile(label: 'Transactions',  icon: Icons.receipt_long_outlined,    accent: Color(0xFF7B68EE), route: '/transactions');
const _kTileCat   = _Tile(label: 'Inventory',     icon: Icons.storefront_outlined,      accent: Color(0xFFE67E22), route: '/catalog');
const _kTileRep   = _Tile(label: 'Sales Reports', icon: Icons.bar_chart_rounded,        accent: Color(0xFF27AE60), route: '/reports');
const _kTileSett  = _Tile(label: 'Settings',      icon: Icons.settings_outlined,        accent: Color(0xFF6B7280), route: '/settings');
const _kTileUsers = _Tile(label: 'Users',          icon: Icons.manage_accounts_outlined, accent: Color(0xFFE67E22), route: '/users');
```

And inside `DashboardScreen.build`, replace the tiles computation:

```dart
    // Role-based tiles (mirrors kiosk: cashier sees New Order + Transactions only)
    final tiles = isAdmin
        ? [_kTileNew, _kTileTx, _kTileCat, _kTileRep, _kTileSett, _kTileUsers]
        : [_kTileNew, _kTileTx];
```

- [ ] **Step 3: Verify the app runs with no compilation errors**

```bash
cd mobile
fvm flutter run -d android
```

Walk through: Login → Dashboard shows correct tiles for role → tap Transactions → list loads → expand a row → test Reprint / Refund / Void flows.

---

## Self-review: Spec coverage

| Gap from kiosk | Covered by task |
|---|---|
| Transactions screen (list + void) | Tasks 3, 5, 8 |
| Refund flow | Tasks 4, 7 |
| Reprint from history | Tasks 1, 2, 6 |
| Role-based dashboard tiles | Task 8 |
| `/transactions` route | Task 8 |
| `/transactions/receipt/:id` route | Task 8 |
| `/transactions/refund/:id` route | Task 8 |

Items intentionally deferred (low priority for core flow):
- Setup PIN route (admin creates users with PIN already in the Add User dialog; setup-PIN flow is only needed if a user has no PIN yet — not the common case)
- Cashier Z-Reading / cashier daily reports (the existing `ReportsScreen` covers the essential summary; Z-Reading is an accounting feature that can be a follow-up plan)
