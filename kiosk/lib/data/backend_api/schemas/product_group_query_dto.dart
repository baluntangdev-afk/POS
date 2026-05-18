import 'package:dart_mappable/dart_mappable.dart';

import 'paginated_query_dto.dart';

part 'product_group_query_dto.mapper.dart';

@MappableClass(ignoreNull: true)
class ProductGroupQueryDto extends PaginatedQueryDto with ProductGroupQueryDtoMappable {
  const ProductGroupQueryDto({super.page, super.limit, super.sort, this.name, this.description});

  final String? name;
  final String? description;

  static const fromJson = ProductGroupQueryDtoMapper.fromJson;
}
