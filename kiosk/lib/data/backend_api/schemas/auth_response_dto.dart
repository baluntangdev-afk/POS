import 'package:dart_mappable/dart_mappable.dart';

part 'auth_response_dto.mapper.dart';

@MappableClass()
class AuthResponseDto with AuthResponseDtoMappable {
  const AuthResponseDto({required this.id, required this.email, required this.systemAdmin});

  final int id;

  final String email;
  final bool systemAdmin;

  static const fromJson = AuthResponseDtoMapper.fromJson;
}
