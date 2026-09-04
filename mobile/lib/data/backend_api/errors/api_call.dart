import 'api_exception.dart';

/// Mixed into every class in `lib/data/backend_api/sources/`. [guard] runs a
/// Dio request and rethrows any failure as an [ApiException], so callers in
/// the repository and feature layers never handle a `DioException` directly.
mixin ApiCall {
  Future<T> guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
