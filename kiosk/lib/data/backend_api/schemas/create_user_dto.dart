import 'package:dart_mappable/dart_mappable.dart';

part 'create_user_dto.mapper.dart';

@MappableClass()
class CreateUserDto with CreateUserDtoMappable {
  const CreateUserDto({
    required this.email,
    required this.userId,
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    this.suffix = '',
    this.image = '',
    required this.status,
    required this.systemAdmin,
    required this.role,
    required this.phone,
    this.emailVerified = false,
    this.phoneVerified = false,
    required this.address,
    this.gender = '',
    this.dateOfBirth = '',
    this.profilePicture = '',
    this.locked = false,
    this.id,
  });

  final String email;
  final String userId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String image;
  final String status;
  final bool systemAdmin;
  final String role;
  final String phone;
  final bool emailVerified;
  final bool phoneVerified;
  final String address;
  final String gender;
  final String dateOfBirth;
  final String profilePicture;
  final bool locked;
  final String? id;
}
