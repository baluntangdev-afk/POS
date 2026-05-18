import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/enums/payment_method.dart';
import '../../../data/backend_api/schemas/create_refund_dto.dart';
import '../../../data/backend_api/schemas/create_refund_item_dto.dart';
import '../../../data/backend_api/sources/refunds_api.dart';
import '../entities/payment.dart';
import '../entities/refund.dart';
import '../entities/refund_item.dart';

abstract class RefundRepository {
  Future<Refund> save(Refund refund);
}

final refundRepositoryProvider = Provider<RefundRepository>((ref) {
  final api = ref.watch(refundsApiProvider);
  return RefundRepositoryImpl(api);
});

class RefundRepositoryImpl implements RefundRepository {
  const RefundRepositoryImpl(this._refundsApi);

  final RefundsApi _refundsApi;

  @override
  Future<Refund> save(Refund refund) async {
    final request = _createRefundDtoFromRefund(refund);
    final response = await _refundsApi.create(request);
    return refund.copyWith(id: '${response.id}', docNumber: response.refundNumber);
  }

  CreateRefundDto _createRefundDtoFromRefund(Refund refund) {
    return CreateRefundDto(
      originalSalesOrderId: refund.receiptId,
      reason: refund.reason,
      totalRefundAmount: refund.payment.paidAmount.toDouble(),
      paymentMethod: _paymentMethodFromPayment(refund.payment),
      transactionReference: _transactionReferenceFromPayment(refund.payment),
      refundItems: refund.items.map(_createRefundItemDtoFromRefundItem).toList(),
    );
  }

  PaymentMethod _paymentMethodFromPayment(Payment payment) {
    return switch (payment) {
      CashPayment() => PaymentMethod.cash,
      CardPayment() => PaymentMethod.creditCard,
      QRPayment() => PaymentMethod.gCash,
      ZeroPayment() => PaymentMethod.other,
    };
  }

  String? _transactionReferenceFromPayment(Payment payment) {
    return switch (payment) {
      CashPayment() => null,
      CardPayment(:final referenceNumber) => referenceNumber,
      QRPayment(:final referenceNumber) => referenceNumber,
      ZeroPayment() => null,
    };
  }

  CreateRefundItemDto _createRefundItemDtoFromRefundItem(RefundItem item) {
    return CreateRefundItemDto(
      salesOrderItemId: item.receiptItemId,
      quantity: item.quantity,
      refundAmount: item.refundAmount.toDouble(),
    );
  }
}
