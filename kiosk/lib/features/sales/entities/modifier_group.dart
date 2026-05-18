import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'modifier_option.dart';

part 'modifier_group.mapper.dart';

@MappableClass()
class ModifierGroup with ModifierGroupMappable {
  const ModifierGroup({
    required this.id,
    required this.name,
    required this.minSelections,
    required this.maxSelections,
    required this.options,
  });

  final int id;
  final String name;
  final int minSelections;
  final int maxSelections;
  final IList<ModifierOption> options;
}
