import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

part 'paginated_data.mapper.dart';

@MappableClass()
class PaginatedData<T> with PaginatedDataMappable<T> {
  const PaginatedData({
    required this.page,
    required this.limit,
    required this.total,
    required this.data,
  });

  final int page;
  final int limit;
  final int total;
  final IList<T> data;

  int get totalPages => (total / limit).ceil();
}
