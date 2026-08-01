sealed class AppError {
  final String message;
  const AppError(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

final class DatabaseError extends AppError {
  const DatabaseError(super.message);
}

final class ValidationError extends AppError {
  final Map<String, String> fieldErrors;
  const ValidationError(super.message, {this.fieldErrors = const {}});
}

final class NotFoundError extends AppError {
  const NotFoundError(super.message);
}

final class CsvParseError extends AppError {
  final int? rowIndex;
  const CsvParseError(super.message, {this.rowIndex});
}

final class PrintError extends AppError {
  const PrintError(super.message);
}
