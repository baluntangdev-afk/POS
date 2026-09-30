import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_auth_dto.mapper.dart';

/// Response of the webhook-receiver's `POST /cartivo-auth`.
@MappableClass()
class CartivoAuthDto with CartivoAuthDtoMappable {
  const CartivoAuthDto({required this.authenticated, this.accessToken});

  final bool authenticated;

  /// Absent when the backend only confirms `authenticated`.
  @MappableField(key: 'access_token')
  final String? accessToken;

  static const fromJson = CartivoAuthDtoMapper.fromJson;
}
