import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/state/session_expired_provider.dart';
import 'errors/api_exception.dart';

bool isExpiredSessionError(Object error) {
  final apiError = ApiException.from(error);
  return apiError is ApiResponseException &&
      apiError.statusCode == 401 &&
      apiError.code == 'invalid_or_expired_token';
}

final sessionExpiredReporterProvider = Provider<void Function()>((ref) {
  return () => ref.read(sessionExpiredProvider.notifier).report();
});
