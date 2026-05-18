import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../secure_storage/schemas/auth_doc.dart';
import '../secure_storage/sources/auth_storage.dart';
import 'api_clients.dart';
import 'schemas/login_response_dto.dart';

final tokenInterceptorProvider = Provider<TokenInterceptor>((ref) {
  final authStorage = ref.watch(authStorageProvider);
  final openApiClient = ref.watch(openApiClientProvider);
  return TokenInterceptor(authStorage, openApiClient);
});

class TokenInterceptor extends QueuedInterceptor {
  TokenInterceptor(this._source, this._refreshClient);

  final AuthStorage _source;
  final Dio _refreshClient;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await _getLatestToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final DioException(:response, :requestOptions) = err;
    if (response?.statusCode != 401) {
      return handler.next(err);
    }
    try {
      final latestToken = await _getLatestToken();
      final requestToken = requestOptions.headers['Authorization']?.toString().replaceAll(
        'Bearer ',
        '',
      );
      final retryToken =
          (latestToken != null && latestToken != requestToken)
              ? latestToken
              : await _refreshToken();
      requestOptions.headers['Authorization'] = 'Bearer $retryToken';
      final retryResponse = await _refreshClient.fetch<dynamic>(requestOptions);
      return handler.resolve(retryResponse);
    } catch (e) {
      final error = DioException(requestOptions: err.requestOptions, error: e);
      return handler.reject(error);
    }
  }

  Future<String?> _getLatestToken() async {
    try {
      final AuthDoc(:accessToken) = await _source.latest;
      return accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<String> _refreshToken() async {
    try {
      final AuthDoc(:refreshToken) = await _source.latest;
      final response = await _refreshClient.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final dto = LoginResponseDto.fromJson(jsonEncode(response.data));
      final doc = AuthDoc(refreshToken: dto.refreshToken, accessToken: dto.accessToken);
      await _source.write(doc);
      return doc.accessToken;
    } catch (e) {
      await _source.clear();
      rethrow;
    }
  }
}
