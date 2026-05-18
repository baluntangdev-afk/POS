import 'app_exception.dart';

class MissingRecordException implements AppException {
  MissingRecordException(this.message);

  @override
  final String message;
}
