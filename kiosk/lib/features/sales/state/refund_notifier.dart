import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/receipt.dart';
import '../entities/receipt_item.dart';
import '../repositories/receipt_repository.dart';
import '../use_cases/process_refund.dart';

part 'refund_notifier.mapper.dart';

final refundProvider = AsyncNotifierProvider.autoDispose.family<RefundNotifier, RefundData, String>(
  RefundNotifier.new,
  name: 'refundProvider',
);

@MappableClass()
class RefundData with RefundDataMappable {
  const RefundData({
    required this.receipt,
    this.formData = const RefundForm(selectedQuantities: {}),
  });

  final Receipt receipt;
  final RefundForm formData;
}

@MappableClass()
class RefundForm with RefundFormMappable {
  const RefundForm({
    required this.selectedQuantities,
    this.reason = '',
    this.refundMethod = 'Cash Refund',
  });

  final Map<String, int> selectedQuantities;
  final String reason;
  final String refundMethod;
}

class RefundNotifier extends AsyncNotifier<RefundData> {
  RefundNotifier(this.receiptId);

  String receiptId;

  static final confirmAction = Mutation<void>();

  @override
  Future<RefundData> build() async {
    final repository = ref.watch(receiptRepositoryProvider);
    final receipt = await repository.getById(receiptId);
    return RefundData(receipt: receipt);
  }

  void toggleAllItemsSelection() {
    if (!state.hasValue) return;

    final receipt = state.requireValue.receipt;
    final refundedQtys = receipt.refundedQuantities;
    final prevQuantities = state.requireValue.formData.selectedQuantities;
    final selectableItems = receipt.items.where((item) {
      final remaining = item.quantity - (refundedQtys[item.id] ?? 0);
      return remaining > 0;
    }).toList();
    final Map<String, int> nextQuantities;

    if (prevQuantities.length == selectableItems.length) {
      nextQuantities = {};
    } else {
      nextQuantities = {
        for (final item in selectableItems)
          item.id: item.quantity - (refundedQtys[item.id] ?? 0),
      };
    }

    state = AsyncData(
      state.requireValue.copyWith(
        formData: state.requireValue.formData.copyWith(selectedQuantities: nextQuantities),
      ),
    );
  }

  void toggleItemSelection({required ReceiptItem item, required bool isSelected}) {
    if (!state.hasValue) return;

    final receipt = state.requireValue.receipt;
    final addOns = _getAddOnsForReceiptItem(receipt, item);
    final prevQuantities = state.requireValue.formData.selectedQuantities;
    final nextQuantities = Map<String, int>.from(prevQuantities);

    if (isSelected) {
      nextQuantities.remove(item.id);
      for (final addOn in addOns) {
        nextQuantities.remove(addOn.id);
      }
    } else {
      nextQuantities[item.id] = item.quantity;
      for (final addOn in addOns) {
        nextQuantities[addOn.id] = item.quantity;
      }
    }

    state = AsyncData(
      state.requireValue.copyWith(
        formData: state.requireValue.formData.copyWith(selectedQuantities: nextQuantities),
      ),
    );
  }

  void changeQuantity({required ReceiptItem item, required int quantity}) {
    if (!state.hasValue) return;

    final receipt = state.requireValue.receipt;
    final addOns = _getAddOnsForReceiptItem(receipt, item);
    final prevQuantities = state.requireValue.formData.selectedQuantities;
    final nextQuantities = Map<String, int>.from(prevQuantities);

    if (quantity > 0 && quantity <= item.quantity) {
      nextQuantities[item.id] = quantity;
      for (final addOn in addOns) {
        nextQuantities[addOn.id] = quantity;
      }
    }

    state = AsyncData(
      state.requireValue.copyWith(
        formData: state.requireValue.formData.copyWith(selectedQuantities: nextQuantities),
      ),
    );
  }

  void changeReason(String reason) {
    if (!state.hasValue) return;

    state = AsyncData(
      state.requireValue.copyWith(formData: state.requireValue.formData.copyWith(reason: reason)),
    );
  }

  void changeRefundMethod(String refundMethod) {
    if (!state.hasValue) return;

    state = AsyncData(
      state.requireValue.copyWith(
        formData: state.requireValue.formData.copyWith(refundMethod: refundMethod),
      ),
    );
  }

  Future<void> confirmRefund() async {
    if (!state.hasValue) return;

    final receipt = state.requireValue.receipt;
    final formData = state.requireValue.formData;

    final processRefund = ref.read(processRefundProvider);
    await processRefund(
      receipt: receipt,
      selectedQuantities: formData.selectedQuantities,
      reason: formData.reason,
      refundMethod: formData.refundMethod,
    );
  }

  IList<ReceiptItem> _getAddOnsForReceiptItem(Receipt receipt, ReceiptItem item) {
    final mainItemsWithAddons = receipt.mainItemsWithAddOns;

    for (final (:mainItem, :addOns) in mainItemsWithAddons) {
      if (mainItem.id == item.id) {
        return addOns;
      }
    }

    return const IList<ReceiptItem>.empty();
  }
}
