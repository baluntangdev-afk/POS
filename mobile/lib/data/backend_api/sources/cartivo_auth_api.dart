import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../errors/api_call.dart';
import '../schemas/cartivo_auth_dto.dart';

final cartivoAuthApiProvider = Provider<CartivoAuthApi>((ref) {
  return CartivoAuthApi(ref.watch(dpoSocketApiClientProvider));
});

class CartivoAuthApi with ApiCall {
  const CartivoAuthApi(this._httpClient);

  final Dio _httpClient;

  Future<CartivoAuthDto> authenticate() => guard(() async {
    final response = await _httpClient.post<dynamic>('/cartivo-auth');
    return CartivoAuthDto.fromJson(jsonEncode(response.data));
  });
}
