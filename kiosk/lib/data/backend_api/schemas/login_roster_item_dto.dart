import 'package:dart_mappable/dart_mappable.dart';

part 'login_roster_item_dto.mapper.dart';

@MappableClass()
class LoginRosterItemDto with LoginRosterItemDtoMappable {
  const LoginRosterItemDto({
    required this.id,
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.suffix,
    this.image,
  });

  final int id;
  final String userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? suffix;
  final String? image;

  static const fromJson = LoginRosterItemDtoMapper.fromJson;
}
