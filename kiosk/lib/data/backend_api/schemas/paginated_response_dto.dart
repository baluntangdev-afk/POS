import 'package:dart_mappable/dart_mappable.dart';

part 'paginated_response_dto.mapper.dart';

@MappableClass()
class PaginatedResponseDto<T> with PaginatedResponseDtoMappable<T> {
  const PaginatedResponseDto({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<T> data;
  final int total;
  final int page;
  final int limit;
}
