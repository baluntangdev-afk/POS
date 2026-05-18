import 'package:dart_mappable/dart_mappable.dart';

part 'login_response_dto.mapper.dart';

@MappableClass()
class LoginResponseDto with LoginResponseDtoMappable {
  const LoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;

  final String refreshToken;
  final String expiresIn;

  static const fromJson = LoginResponseDtoMapper.fromJson;
}
