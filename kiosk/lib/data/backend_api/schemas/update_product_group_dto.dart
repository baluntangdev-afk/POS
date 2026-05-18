import 'package:dart_mappable/dart_mappable.dart';

part 'update_product_group_dto.mapper.dart';

@MappableClass(ignoreNull: true)
class UpdateProductGroupDto with UpdateProductGroupDtoMappable {
  const UpdateProductGroupDto({this.name, this.description});

  final String? name;
  final String? description;

  static const fromJson = UpdateProductGroupDtoMapper.fromJson;
}
