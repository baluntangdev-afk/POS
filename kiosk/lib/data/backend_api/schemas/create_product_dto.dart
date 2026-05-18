import 'package:dart_mappable/dart_mappable.dart';

part 'create_product_dto.mapper.dart';

@MappableClass()
class CreateProductDto with CreateProductDtoMappable {
  const CreateProductDto({required this.groupId, required this.name, this.description});

  final int groupId;
  final String name;
  final String? description;

  static const fromJson = CreateProductDtoMapper.fromJson;
}
