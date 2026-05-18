import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

part 'selected_variant.mapper.dart';

@MappableClass()
class SelectedVariant with SelectedVariantMappable {
  const SelectedVariant({required this.id, required this.name, required this.price});

  final int id;
  final String name;
  final Decimal price;
}
