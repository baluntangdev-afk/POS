import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_user_dto.mapper.dart';

@MappableClass()
class CartivoUserDto with CartivoUserDtoMappable {
  const CartivoUserDto({required this.id, required this.email, this.name, required this.createdAt});

  final String id;
  final String email;
  final String? name;

  @MappableField(key: 'created_at')
  final DateTime createdAt;

  static const fromJson = CartivoUserDtoMapper.fromJson;
}
