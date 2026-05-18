import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

part 'selected_option.mapper.dart';

@MappableClass()
class SelectedOption with SelectedOptionMappable {
  const SelectedOption({required this.id, required this.name, required this.price});

  final int id;
  final String name;
  final Decimal price;
}
