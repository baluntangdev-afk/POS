import 'package:dart_mappable/dart_mappable.dart';

part 'create_product_group_dto.mapper.dart';

@MappableClass()
class CreateProductGroupDto with CreateProductGroupDtoMappable {
  const CreateProductGroupDto({required this.name, this.description});

  final String name;
  final String? description;

  static const fromJson = CreateProductGroupDtoMapper.fromJson;
}
