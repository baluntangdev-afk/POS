import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../entities/cart_item.dart';
import '../entities/cart_state.dart';
import '../entities/sale_receipt_data.dart';

class OrderingNotifier extends AsyncNotifier<CartState> {
  SaleReceiptData? lastReceipt;

  @override
  Future<CartState> build() => _load();

  Future<CartState> _load() async {
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
    return CartState(
      groups: groups,
      allProducts: products,
      selectedGroupId: current?.selectedGroupId,
      items: current?.items ?? const [],
      saleType: current?.saleType ?? 'dine_in',
      orderDiscount: current?.orderDiscount ?? 0,
    );
  }

  void selectGroup(int? groupId) {
    state = state.whenData((s) => s.copyWith(selectedGroupId: () => groupId));
  }

  void addItem(CartItem item) {
    state = state.whenData((s) => s.copyWith(items: [...s.items, item]));
  }

  void removeItem(String cartId) {
    state = state.whenData(
      (s) => s.copyWith(items: s.items.where((i) => i.cartId != cartId).toList()),
    );
  }

  void updateQuantity(String cartId, int qty) {
    if (qty <= 0) {
      removeItem(cartId);
      return;
    }
    state = state.whenData((s) => s.copyWith(
          items: s.items
              .map((i) => i.cartId == cartId ? i.copyWith(quantity: qty) : i)
              .toList(),
        ));
  }

  void updateNotes(String cartId, String? notes) {
    state = state.whenData((s) => s.copyWith(
          items: s.items
              .map((i) => i.cartId == cartId
                  ? i.copyWith(notes: (notes?.isEmpty == true) ? null : notes)
                  : i)
              .toList(),
        ));
  }

  void applyItemDiscount(String cartId, double amount) {
    state = state.whenData((s) => s.copyWith(
          items: s.items
              .map((i) => i.cartId == cartId ? i.copyWith(discountAmount: () => amount) : i)
              .toList(),
        ));
  }

  void clearItemDiscount(String cartId) {
    state = state.whenData((s) => s.copyWith(
          items: s.items
              .map((i) => i.cartId == cartId ? i.copyWith(discountAmount: () => null) : i)
              .toList(),
        ));
  }

  void applyOrderDiscount(double amount) {
    state = state.whenData((s) => s.copyWith(orderDiscount: amount));
  }

  void clearOrderDiscount() {
    state = state.whenData((s) => s.copyWith(orderDiscount: 0));
  }

  void setSaleType(String type) {
    state = state.whenData((s) => s.copyWith(saleType: type));
  }

  void clearCart() {
    state = state.whenData((s) => s.copyWith(items: const [], orderDiscount: 0));
  }

  Future<int> confirmSale({
    required int cashierId,
    required String cashierName,
    required String method,
    required double amountPaid,
    String? reference,
  }) async {
    final cartState = state.value!;
    final db = ref.read(databaseProvider);
    final now = DateTime.now();

    final saleId = await db.salesDao.insertSale(
      SalesTableCompanion.insert(
        cashierId: cashierId,
        total: cartState.total,
        discount: Value(cartState.totalDiscount),
        status: 'completed',
        type: cartState.saleType,
        createdAt: now,
      ),
    );

    for (final item in cartState.items) {
      final itemId = await db.salesDao.insertSaleItem(
        SaleItemsTableCompanion.insert(
          saleId: saleId,
          productId: item.productId,
          variantName: '',
          qty: item.quantity,
          unitPrice: item.unitPrice,
        ),
      );

      for (final group in item.modifiers) {
        for (final opt in group.selected) {
          await db.salesDao.insertSaleItemModifier(
            SaleItemModifiersTableCompanion.insert(
              itemId: itemId,
              modifierName: '${group.groupName}: ${opt.name}',
              additionalPrice: Value(opt.additionalPrice),
            ),
          );
        }
      }
    }

    await db.salesDao.insertPayment(
      PaymentsTableCompanion.insert(
        saleId: saleId,
        method: method,
        amount: amountPaid,
        reference: Value(reference),
        createdAt: now,
      ),
    );

    final change = method == 'cash' ? (amountPaid - cartState.total).clamp(0.0, double.infinity) : 0.0;

    lastReceipt = SaleReceiptData(
      saleId: saleId,
      createdAt: now,
      saleType: cartState.saleType,
      items: List.unmodifiable(cartState.items),
      subtotal: cartState.subtotal,
      totalDiscount: cartState.totalDiscount,
      total: cartState.total,
      paymentMethod: method,
      amountPaid: amountPaid,
      change: change,
      reference: reference,
      cashierName: cashierName,
    );

    clearCart();
    return saleId;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final orderingProvider =
    AsyncNotifierProvider<OrderingNotifier, CartState>(OrderingNotifier.new);
