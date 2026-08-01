import 'package:dart_mappable/dart_mappable.dart';

part 'product_list_item_dto.mapper.dart';

@MappableClass()
class ProductListItemDto with ProductListItemDtoMappable {
  const ProductListItemDto({required this.id, required this.name, required this.price, this.imageUrl, required this.categoryName});

  final int id;
  final String name;
  final String price;
  final String? imageUrl;
  final String categoryName;

  static const fromJson = ProductListItemDtoMapper.fromJson;
}
