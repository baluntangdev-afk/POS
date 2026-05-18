import 'package:dart_mappable/dart_mappable.dart';

import '../enums/sales_order_type.dart';
import 'payment_details_dto.dart';

part 'confirm_sales_order_dto.mapper.dart';

@MappableClass()
class ConfirmSalesOrderDto with ConfirmSalesOrderDtoMappable {
  const ConfirmSalesOrderDto({required this.paymentDetails, required this.soType});

  @MappableField(key: 'payment_details')
  final PaymentDetailsDto paymentDetails;

  final SalesOrderType soType;

  static const fromJson = ConfirmSalesOrderDtoMapper.fromJson;
}
