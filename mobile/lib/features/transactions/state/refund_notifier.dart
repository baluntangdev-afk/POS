import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ordering/entities/receipt.dart';
import '../../ordering/entities/receipt_item.dart';
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
    final receipt = state.requireValue.receipt;
    final addOns = _addOnsFor(receipt, itemId);
    final current = Map<int, int>.from(state.requireValue.form.selectedQuantities);
    if (current.containsKey(itemId)) {
      current.remove(itemId);
      for (final addOn in addOns) {
        current.remove(addOn.id);
      }
    } else {
      current[itemId] = maxQuantity;
      for (final addOn in addOns) {
        current[addOn.id] = maxQuantity;
      }
    }
    state = AsyncData(state.requireValue.copyWith(
      form: state.requireValue.form.copyWith(selectedQuantities: current),
    ));
  }

  void changeQuantity({required int itemId, required int quantity}) {
    if (!state.hasValue) return;
    final receipt = state.requireValue.receipt;
    final item = receipt.items.firstWhere((i) => i.id == itemId);
    if (quantity <= 0 || quantity > item.quantity) return;
    final addOns = _addOnsFor(receipt, itemId);
    final current = Map<int, int>.from(state.requireValue.form.selectedQuantities);
    current[itemId] = quantity;
    for (final addOn in addOns) {
      current[addOn.id] = quantity;
    }
    state = AsyncData(state.requireValue.copyWith(
      form: state.requireValue.form.copyWith(selectedQuantities: current),
    ));
  }

  List<ReceiptItem> _addOnsFor(Receipt receipt, int mainItemId) {
    for (final entry in receipt.mainItemsWithAddOns) {
      if (entry.mainItem.id == mainItemId) return entry.addOns;
    }
    return const [];
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
