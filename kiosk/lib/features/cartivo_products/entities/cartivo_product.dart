import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_product.mapper.dart';

@MappableClass()
class CartivoProduct with CartivoProductMappable {
  const CartivoProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double price;
  final String currency;
  final DateTime createdAt;
}
