import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'selected_option.dart';

part 'selected_modifier.mapper.dart';

@MappableClass()
class SelectedModifier with SelectedModifierMappable {
  const SelectedModifier({required this.id, required this.name, required this.options});

  final int id;
  final String name;
  final IList<SelectedOption> options;

  Decimal get price => options.fold(Decimal.zero, (total, option) => total + option.price);
}
