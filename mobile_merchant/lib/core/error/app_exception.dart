/// Exceptions thrown across the datasource boundary.
///
/// Datasource `Impl` methods throw these; repository `Impl` methods catch them
/// and convert back to `Left(Failure.…)`.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

class ServerException extends AppException {
  const ServerException(super.message, [this.statusCode]);

  final int? statusCode;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized.']);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Forbidden.']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found.']);
}
