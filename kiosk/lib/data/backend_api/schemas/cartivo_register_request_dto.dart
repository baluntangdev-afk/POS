import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_register_request_dto.mapper.dart';

@MappableClass()
class CartivoRegisterRequestDto with CartivoRegisterRequestDtoMappable {
  const CartivoRegisterRequestDto({required this.email, required this.password, this.name});

  final String email;
  final String password;
  final String? name;

  static const fromJson = CartivoRegisterRequestDtoMapper.fromJson;
}
