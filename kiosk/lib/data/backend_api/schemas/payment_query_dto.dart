import 'package:dart_mappable/dart_mappable.dart';

import '../enums/payment_method.dart';
import 'paginated_query_dto.dart';

part 'payment_query_dto.mapper.dart';

@MappableClass(ignoreNull: true)
class PaymentQueryDto extends PaginatedQueryDto with PaymentQueryDtoMappable {
  const PaymentQueryDto({
    super.page,
    super.limit,
    super.sort,
    this.paymentMethod,
    this.paymentDate,
    this.transactionReference,
    this.soNumber,
  });

  final PaymentMethod? paymentMethod;
  final String? paymentDate;
  final String? transactionReference;
  final String? soNumber;

  static const fromJson = PaymentQueryDtoMapper.fromJson;
}
