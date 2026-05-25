import 'modifier.dart';

class CatalogModifierGroup {
  const CatalogModifierGroup({
    required this.id,
    required this.name,
    this.description,
    required this.selectionType,
    required this.minSelections,
    required this.maxSelections,
    required this.isRequired,
    required this.modifiers,
  });

  final String id;
  final String name;
  final String? description;
  final String selectionType;
  final int minSelections;
  final int maxSelections;
  final bool isRequired;
  final List<CatalogModifier> modifiers;

  factory CatalogModifierGroup.fromJson(Map<String, dynamic> json) {
    return CatalogModifierGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      selectionType: json['selection_type'] as String,
      minSelections: json['min_selections'] as int,
      maxSelections: json['max_selections'] as int,
      isRequired: json['is_required'] as bool,
      modifiers: (json['modifiers'] as List<dynamic>)
          .map((m) => CatalogModifier.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
