import 'app_exception.dart';

enum CartivoAuthErrorKind { validation, emailTaken, invalidCredentials, rateLimited, network, unknown }

class CartivoAuthException implements AppException {
  CartivoAuthException(this.kind, this.message);

  final CartivoAuthErrorKind kind;

  @override
  final String message;
}
