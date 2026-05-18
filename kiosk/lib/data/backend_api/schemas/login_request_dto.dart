import 'package:dart_mappable/dart_mappable.dart';

part 'login_request_dto.mapper.dart';

@MappableClass()
class LoginRequestDto with LoginRequestDtoMappable {
  const LoginRequestDto({required this.userId, required this.devicePin});

  final String userId;

  final String devicePin;

  static const fromJson = LoginRequestDtoMapper.fromJson;
}
