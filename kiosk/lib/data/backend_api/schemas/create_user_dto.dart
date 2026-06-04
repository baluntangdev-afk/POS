import 'package:dart_mappable/dart_mappable.dart';

part 'create_user_dto.mapper.dart';

@MappableClass()
class CreateUserDto with CreateUserDtoMappable {
  const CreateUserDto({
    required this.userId,
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    this.image = '',
    required this.status,
    required this.systemAdmin,
    required this.role,
    required this.phone,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.profilePicture = '',
    this.locked = false,
    this.id,
  });

  final String userId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String image;
  final String status;
  final bool systemAdmin;
  final String role;
  final String phone;
  final bool emailVerified;
  final bool phoneVerified;
  final String profilePicture;
  final bool locked;
  final String? id;
}
