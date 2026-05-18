import 'package:dart_mappable/dart_mappable.dart';

part 'update_product_dto.mapper.dart';

@MappableClass(ignoreNull: true)
class UpdateProductDto with UpdateProductDtoMappable {
  const UpdateProductDto({this.groupId, this.name, this.description});

  final int? groupId;
  final String? name;
  final String? description;

  static const fromJson = UpdateProductDtoMapper.fromJson;
}
