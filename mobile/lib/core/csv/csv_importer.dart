import 'dart:io';

class CsvRowError {
  final int row;
  final String message;
  const CsvRowError(this.row, this.message);
}

class ImportResult {
  final int successCount;
  final int skippedCount;
  final List<CsvRowError> errors;

  const ImportResult({
    required this.successCount,
    required this.skippedCount,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get totalRows => successCount + skippedCount + errors.length;
}

abstract interface class CsvImporter {
  Future<ImportResult> importFile(File file);
}
