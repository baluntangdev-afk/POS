import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

part 'modifier_group.mapper.dart';

@MappableClass()
class Modifier with ModifierMappable {
  const Modifier({required this.id, required this.name, required this.price});

  factory Modifier.draft() => const Modifier(id: 0, name: '', price: 0.0);

  final int id;
  final String name;
  final double price;
}

@MappableClass()
class ModifierGroup with ModifierGroupMappable {
  const ModifierGroup({required this.id, required this.name, this.modifiers = const IList.empty()});

  factory ModifierGroup.draft() => const ModifierGroup(id: 0, name: '');

  final int id;
  final String name;
  final IList<Modifier> modifiers;
}

@MappableClass()
class ProductModifierAssignment with ProductModifierAssignmentMappable {
  const ProductModifierAssignment({
    required this.productId,
    this.variantId,
    required this.modifierGroupId,
  });

  final int productId;
  final int? variantId;
  final int modifierGroupId;
}
