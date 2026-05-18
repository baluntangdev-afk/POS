import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/enums/payment_method.dart';
import '../../../data/backend_api/enums/sales_order_status.dart';
import '../../../data/backend_api/enums/sales_order_type.dart';
import '../../../data/backend_api/schemas/confirm_sales_order_dto.dart';
import '../../../data/backend_api/schemas/payment_details_dto.dart';
import '../../../data/backend_api/schemas/payment_query_dto.dart';
import '../../../data/backend_api/schemas/payment_response_dto.dart';
import '../../../data/backend_api/schemas/refund_item_response_dto.dart';
import '../../../data/backend_api/schemas/refund_query_dto.dart';
import '../../../data/backend_api/schemas/refund_with_items_response_dto.dart';
import '../../../data/backend_api/schemas/sales_order_item_response_dto.dart';
import '../../../data/backend_api/schemas/sales_order_query_dto.dart';
import '../../../data/backend_api/schemas/sales_order_with_items_response_dto.dart';
import '../../../data/backend_api/schemas/user_dto.dart';
import '../../../data/backend_api/sources/payments_api.dart';
import '../../../data/backend_api/sources/refunds_api.dart';
import '../../../data/backend_api/sources/sales_orders_api.dart';
import '../../../data/backend_api/sources/user_api.dart';
import '../../../data/shared_preferences/schemas/franchisee_info_pref.dart';
import '../../../data/shared_preferences/sources/franchisee_info_storage.dart';
import '../../../utils/paginated_data.dart';
import '../entities/cashier.dart';
import '../entities/payment.dart';
import '../entities/receipt.dart';
import '../entities/receipt_item.dart';
import '../entities/refund.dart';
import '../entities/refund_item.dart';
import '../entities/store.dart';
import '../enums/sale_type.dart';

abstract class ReceiptRepository {
  Future<Receipt> save(Receipt receipt);

  Future<Receipt> getById(String id);

  Future<PaginatedData<Receipt>> getAll({
    required int page,
    required int limit,
    String? soNumber,
    DateTime? soDate,
    String? sort,
  });
}

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepositoryImpl(
    ref.watch(salesOrdersApiProvider),
    ref.watch(userApiProvider),
    ref.watch(paymentsApiProvider),
    ref.watch(refundsApiProvider),
    ref.watch(franchiseeInfoStorageProvider),
  );
});

class ReceiptRepositoryImpl implements ReceiptRepository {
  const ReceiptRepositoryImpl(
    this._salesOrdersApi,
    this._usersApi,
    this._paymentsApi,
    this._refundsApi,
    this._franchiseeInfoStorage,
  );

  final SalesOrdersApi _salesOrdersApi;
  final UserApi _usersApi;
  final PaymentsApi _paymentsApi;
  final RefundsApi _refundsApi;
  final FranchiseeInfoStorage _franchiseeInfoStorage;

  @override
  Future<Receipt> save(Receipt receipt) async {
    final confirmRequestDto = _createConfirmSalesOrderDtoFromReceipt(receipt);
    final confirmResponseDto = await _salesOrdersApi.confirm(receipt.id, confirmRequestDto);

    final (userDto, paginatedPaymentDto) =
        await (
          _usersApi.getUserById(confirmResponseDto.createdBy),
          _paymentsApi.getAll(PaymentQueryDto(soNumber: confirmResponseDto.soNumber)),
        ).wait;

    return _receiptFromSalesOrderWithItemsDto(
      confirmResponseDto,
      cashier: _cashierFromUserDto(userDto),
      payment: _paymentFromPaymentResponseDto(paginatedPaymentDto.data.first),
      store: receipt.store,
    );
  }

  @override
  Future<Receipt> getById(String id) async {
    final getResponse = await _salesOrdersApi.getById(id);

    final (userDto, paginatedPaymentDto, paginatedRefundDto, franchiseeInfoPref) =
        await (
          _usersApi.getUserById(getResponse.createdBy),
          _paymentsApi.getAll(PaymentQueryDto(soNumber: getResponse.soNumber)),
          _refundsApi.getAll(RefundQueryDto(originalSalesOrderId: getResponse.id)),
          _franchiseeInfoStorage.fetch(),
        ).wait;

    return _receiptFromSalesOrderWithItemsDto(
      getResponse,
      cashier: _cashierFromUserDto(userDto),
      payment: _paymentFromPaymentResponseDto(paginatedPaymentDto.data.firstOrNull),
      store: _storeFromFranchiseeInfoPref(franchiseeInfoPref),
      refunds:
          paginatedRefundDto.data
              .map((dto) => _refundFromRefundWithItemsResponseDto(dto, salesOrder: getResponse))
              .toIList(),
    );
  }

  @override
  Future<PaginatedData<Receipt>> getAll({
    required int page,
    required int limit,
    String? soNumber,
    DateTime? soDate,
    String? sort,
  }) async {
    final salesOrdersQuery = SalesOrderQueryDto(
      page: page,
      limit: limit,
      soNumber: soNumber,
      soDate: soDate,
      sort: sort,
      status: SalesOrderStatus.confirmed,
    );

    final (salesOrdersResponse, franchiseeInfoPref) =
        await (_salesOrdersApi.getAll(salesOrdersQuery), _franchiseeInfoStorage.fetch()).wait;

    return PaginatedData(
      page: page,
      limit: limit,
      total: salesOrdersResponse.total,
      data:
          salesOrdersResponse.data.map((dto) {
            return _receiptFromSalesOrderWithItemsDto(
              dto,
              store: _storeFromFranchiseeInfoPref(franchiseeInfoPref),
              cashier: Cashier.unknown(),
              payment: ZeroPayment(),
            );
          }).toIList(),
    );
  }

  ConfirmSalesOrderDto _createConfirmSalesOrderDtoFromReceipt(Receipt receipt) {
    return ConfirmSalesOrderDto(
      paymentDetails: _paymentDetailsDtoFromReceipt(receipt),
      soType: _salesOrderTypeFromSaleType(receipt.type),
    );
  }

  PaymentDetailsDto _paymentDetailsDtoFromReceipt(Receipt receipt) {
    return switch (receipt.payment) {
      CashPayment(:final cashReceived, :final change) => PaymentDetailsDto(
        payeeName: '',
        method: PaymentMethod.cash,
        grossAmount: receipt.grossAmount.toString(),
        taxAmount: receipt.vatAmount.toString(),
        netAmount: receipt.totalAmount.toString(),
        amountPaid: cashReceived.toString(),
        change: change.toString(),
      ),
      CardPayment() => throw 'Card payment is unsupported.',
      QRPayment() => throw 'QR payment is unsupported.',
      ZeroPayment() => throw 'Zero payment is unsupported.',
    };
  }

  SalesOrderType _salesOrderTypeFromSaleType(SaleType type) {
    return switch (type) {
      SaleType.dineIn => SalesOrderType.dineIn,
      SaleType.takeOut => SalesOrderType.takeOut,
      SaleType.delivery => SalesOrderType.delivery,
    };
  }

  Receipt _receiptFromSalesOrderWithItemsDto(
    SalesOrderWithItemsResponseDto dto, {
    required Cashier cashier,
    required Payment payment,
    required Store store,
    IList<Refund> refunds = const IList.empty(),
  }) {
    return Receipt(
      id: dto.id,
      store: store,
      cashier: cashier,
      docNumber: dto.soNumber,
      docDate: dto.soDate,
      type: _saleTypeFromSalesOrderType(dto.soType),
      payment: payment,
      items:
          dto.salesOrderItems
              .sorted((a, b) {
                final comparison = (a.itemSequence ?? 0).compareTo(b.itemSequence ?? 0);
                if (comparison != 0) return comparison;
                // Main item comes first
                return a.addOn ? 1 : -1;
              })
              .map(_receiptItemFromSalesOrderItemDto)
              .toIList(),
      refunds: refunds,
    );
  }

  Payment _paymentFromPaymentResponseDto(PaymentResponseDto? dto) {
    return switch (dto) {
      null => ZeroPayment(),
      CashPaymentDto(:final id, :final amountPaid, :final change) => CashPayment(
        id: id,
        paidAmount: Decimal.parse(amountPaid) - Decimal.parse(change),
        cashReceived: Decimal.parse(amountPaid),
      ),
      CreditCardPaymentDto() => throw 'CreditCardPayment is unsupported.',
      GCashPaymentDto() => throw 'GCashPayment is unsupported.',
      OtherPaymentDto() => throw 'OtherPayment is unsupported.',
    };
  }

  ReceiptItem _receiptItemFromSalesOrderItemDto(SalesOrderItemResponseDto dto) {
    return ReceiptItem(
      id: dto.id,
      sequence: dto.itemSequence ?? 0,
      description: dto.description,
      quantity: (double.tryParse(dto.qty) ?? 1).round(),
      unitPrice: Decimal.parse(dto.unitPrice.toString()),
      grossAmount: Decimal.parse(
        ((double.tryParse(dto.qty) ?? 1).round() * dto.unitPrice).toString(),
      ),
      discountCode: '',
      discountRate: Decimal.parse(dto.itemDiscountRate.toString()),
      discountAmount: Decimal.parse(dto.itemDiscountedPrice.toString()),
      vatExclusiveAmount: Decimal.parse(dto.vatExclusiveAmount.toString()),
      vatAmount: Decimal.parse((dto.vatAmount ?? 0.0).toString()),
      totalAmount: Decimal.parse(dto.itemTotalAmount.toString()),
      isMain: !dto.addOn,
    );
  }

  SaleType _saleTypeFromSalesOrderType(SalesOrderType type) {
    return switch (type) {
      SalesOrderType.dineIn => SaleType.dineIn,
      SalesOrderType.takeOut => SaleType.takeOut,
      SalesOrderType.delivery => SaleType.delivery,
    };
  }

  Cashier _cashierFromUserDto(UserDto dto) {
    return Cashier(
      id: dto.id,
      employeeId: dto.userId,
      firstName: dto.firstName,
      middleName: dto.middleName,
      lastName: dto.lastName,
      suffix: dto.suffix == 'None' ? null : dto.suffix,
    );
  }

  Store _storeFromFranchiseeInfoPref(FranchiseeInfoPref pref) {
    return Store(
      legalName: pref.legalName,
      tin: pref.tin,
      addressLine1: pref.addressLine1,
      addressLine2: pref.addressLine2,
      logo: pref.franchiseLogo,
    );
  }

  Refund _refundFromRefundWithItemsResponseDto(
    RefundWithItemsResponseDto dto, {
    required SalesOrderWithItemsResponseDto salesOrder,
  }) {
    return Refund(
      id: dto.id.toString(),
      docNumber: dto.refundNumber,
      docDate: dto.refundDate,
      receiptId: salesOrder.id,
      reason: dto.reason,
      payment: _paymentFromRefundWithItemsResponseDto(dto),
      items:
          dto.refundItems
              .map((refundItem) {
                return _refundItemFromRefundItemResponseDto(
                  refundItem,
                  salesOrderItems: salesOrder.salesOrderItems,
                );
              })
              .sorted((a, b) {
                final comparison = a.sequence.compareTo(b.sequence);
                if (comparison != 0) return comparison;
                // Main item comes first
                return a.isMain ? -1 : 1;
              })
              .toIList(),
    );
  }

  Payment _paymentFromRefundWithItemsResponseDto(RefundWithItemsResponseDto dto) {
    return switch (dto) {
      CashRefundDto() => CashPayment(
        paidAmount: Decimal.parse(dto.totalRefundAmount.toString()),
        cashReceived: Decimal.parse(dto.totalRefundAmount.toString()),
      ),
      CreditCardRefundDto() => throw 'Credit card refund is unsupported.',
      GCashRefundDto() => throw 'GCash refund is unsupported.',
      OtherRefundDto() => throw 'Other refund payment method is unsupported.',
    };
  }

  RefundItem _refundItemFromRefundItemResponseDto(
    RefundItemResponseDto dto, {
    required List<SalesOrderItemResponseDto> salesOrderItems,
  }) {
    final salesOrderItem = salesOrderItems.firstWhereOrNull(
      (item) => item.id == dto.salesOrderItemId,
    );
    return RefundItem(
      id: dto.id.toString(),
      receiptItemId: dto.salesOrderItemId,
      sequence: salesOrderItem?.itemSequence ?? 0,
      description: salesOrderItem?.description ?? '',
      quantity: dto.quantity,
      refundAmount: Decimal.parse(dto.refundAmount.toString()),
      isMain: !(salesOrderItem?.addOn ?? true),
    );
  }
}
