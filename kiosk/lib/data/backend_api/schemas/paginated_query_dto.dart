import 'package:dart_mappable/dart_mappable.dart';

part 'paginated_query_dto.mapper.dart';

@MappableClass(ignoreNull: true)
abstract class PaginatedQueryDto with PaginatedQueryDtoMappable {
  const PaginatedQueryDto({this.page, this.limit, this.sort});

  final int? page;
  final int? limit;
  final String? sort;
}
