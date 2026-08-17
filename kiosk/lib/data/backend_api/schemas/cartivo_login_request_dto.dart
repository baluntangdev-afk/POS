import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_login_request_dto.mapper.dart';

@MappableClass()
class CartivoLoginRequestDto with CartivoLoginRequestDtoMappable {
  const CartivoLoginRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  static const fromJson = CartivoLoginRequestDtoMapper.fromJson;
}
