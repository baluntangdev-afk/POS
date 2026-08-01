class ImportProductsCsvResult {
  const ImportProductsCsvResult({
    required this.categoriesInserted,
    required this.categoriesUpdated,
    required this.categoriesDeleted,
    required this.productsInserted,
    required this.productsUpdated,
    required this.productsDeleted,
    required this.variantsInserted,
    required this.variantsUpdated,
    required this.variantsDeleted,
  });

  final int categoriesInserted;
  final int categoriesUpdated;
  final int categoriesDeleted;
  final int productsInserted;
  final int productsUpdated;
  final int productsDeleted;
  final int variantsInserted;
  final int variantsUpdated;
  final int variantsDeleted;

  factory ImportProductsCsvResult.fromJson(Map<String, dynamic> json) {
    return ImportProductsCsvResult(
      categoriesInserted: json['categoriesInserted'] as int,
      categoriesUpdated: json['categoriesUpdated'] as int,
      categoriesDeleted: json['categoriesDeleted'] as int,
      productsInserted: json['productsInserted'] as int,
      productsUpdated: json['productsUpdated'] as int,
      productsDeleted: json['productsDeleted'] as int,
      variantsInserted: json['variantsInserted'] as int,
      variantsUpdated: json['variantsUpdated'] as int,
      variantsDeleted: json['variantsDeleted'] as int,
    );
  }
}
