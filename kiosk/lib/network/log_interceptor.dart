import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final logInterceptorProvider = Provider<LogInterceptor>((ref) {
  return LogInterceptor(requestBody: true, responseBody: true);
});
