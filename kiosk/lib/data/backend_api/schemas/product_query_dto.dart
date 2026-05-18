import 'package:dart_mappable/dart_mappable.dart';

import 'paginated_query_dto.dart';

part 'product_query_dto.mapper.dart';

@MappableClass(ignoreNull: true)
class ProductQueryDto extends PaginatedQueryDto with ProductQueryDtoMappable {
  const ProductQueryDto({
    super.page,
    super.limit,
    super.sort,
    this.groupId,
    this.name,
    this.description,
  });

  final int? groupId;
  final String? name;
  final String? description;

  static const fromJson = ProductQueryDtoMapper.fromJson;
}
