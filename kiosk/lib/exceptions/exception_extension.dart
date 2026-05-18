import 'app_exception.dart';

extension ExceptionExtension on Object {
  String get message =>
      this is AppException && (this as AppException).message.isNotEmpty
          ? (this as AppException).message
          : 'Unexpected error occurred.';
}
