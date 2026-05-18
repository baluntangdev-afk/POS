import 'package:dart_mappable/dart_mappable.dart';

import '../enums/payment_method.dart';
import 'paginated_query_dto.dart';

part 'refund_query_dto.mapper.dart';

@MappableClass(ignoreNull: true)
class RefundQueryDto extends PaginatedQueryDto with RefundQueryDtoMappable {
  const RefundQueryDto({
    super.page,
    super.limit,
    super.sort,
    this.paymentMethod,
    this.refundDate,
    this.transactionReference,
    this.originalSalesOrderId,
    this.refundNumber,
  });

  final PaymentMethod? paymentMethod;
  final String? refundDate;
  final String? transactionReference;
  final String? originalSalesOrderId;
  final String? refundNumber;

  static const fromJson = RefundQueryDtoMapper.fromJson;
}
