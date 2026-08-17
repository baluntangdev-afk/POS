import 'package:dart_mappable/dart_mappable.dart';

import 'cartivo_user_dto.dart';

part 'cartivo_auth_response_dto.mapper.dart';

@MappableClass()
class CartivoAuthResponseDto with CartivoAuthResponseDtoMappable {
  const CartivoAuthResponseDto({required this.user, required this.token, required this.expiresAt});

  final CartivoUserDto user;
  final String token;

  @MappableField(key: 'expires_at')
  final DateTime expiresAt;

  static const fromJson = CartivoAuthResponseDtoMapper.fromJson;
}
