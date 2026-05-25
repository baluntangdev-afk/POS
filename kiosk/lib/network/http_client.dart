import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'log_interceptor.dart';

final httpClientProvider = Provider.family<Dio, ({String baseUrl, List<Interceptor> interceptors})>(
  (ref, params) {
    final options = BaseOptions(
      baseUrl: params.baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(minutes: 1),
      receiveTimeout: const Duration(minutes: 1),
    );
    final client = Dio(options)..interceptors.addAll(params.interceptors);
    if (kDebugMode) {
      final logInterceptor = ref.watch(logInterceptorProvider);
      client.interceptors.add(logInterceptor);
    }
    ref.onDispose(() => client.close(force: true));
    return client;
  },
);
