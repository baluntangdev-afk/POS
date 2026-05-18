import 'package:dart_mappable/dart_mappable.dart';

part 'user_dto.mapper.dart';

@MappableClass()
class UserDto with UserDtoMappable {
  const UserDto({
    required this.id,
    required this.userId,
    required this.email,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.suffix,
    required this.systemAdmin,
    this.image,
    this.phone,
    required this.emailVerified,
    required this.phoneVerified,
    required this.locked,
    required this.status,
    this.lastLogin,
    required this.createdAt,
    this.userDetails,
    required this.isPinChanged,
  });

  final int id;
  final String userId;
  final String email;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String suffix;
  final bool isPinChanged;
  final bool systemAdmin;
  final String? image;
  final String? phone;
  final bool emailVerified;
  final bool phoneVerified;
  final bool locked;
  final String status;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final UserDetailsDto? userDetails;

  static const fromJson = UserDtoMapper.fromJson;
}

@MappableClass()
class UserDetailsDto with UserDetailsDtoMappable {
  const UserDetailsDto({required this.id, this.phone, this.address, this.gender, this.dateOfBirth});

  final int id;
  final String? phone;
  final String? address;
  final String? gender;
  final DateTime? dateOfBirth;
}
