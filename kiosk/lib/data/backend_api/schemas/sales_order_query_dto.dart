import 'package:dart_mappable/dart_mappable.dart';

import '../enums/sales_order_status.dart';
import '../enums/sales_order_type.dart';
import '../mappers/date_time_with_offset_mapper.dart';
import 'paginated_query_dto.dart';

part 'sales_order_query_dto.mapper.dart';

@MappableClass(ignoreNull: true, includeCustomMappers: [DateTimeWithOffsetMapper()])
class SalesOrderQueryDto extends PaginatedQueryDto with SalesOrderQueryDtoMappable {
  const SalesOrderQueryDto({
    super.page,
    super.limit,
    super.sort,
    this.soNumber,
    this.soDate,
    this.soType,
    this.createdBy,
    this.status,
  });

  final String? soNumber;
  final DateTime? soDate;
  final SalesOrderType? soType;
  final int? createdBy;
  final SalesOrderStatus? status;

  static const fromJson = SalesOrderQueryDtoMapper.fromJson;
}
