import 'app_exception.dart';

class LoginPinException implements AppException {
  LoginPinException(this.message);
  @override
  final String message;
}
