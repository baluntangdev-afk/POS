import 'package:dart_mappable/dart_mappable.dart';

part 'user.mapper.dart';

@MappableClass()
class User with UserMappable {
  const User({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.suffix,
    required this.phone,
    required this.email,
    required this.systemAdmin,
    required this.emailVerified,
    required this.phoneVerified,
    required this.locked,
    required this.status,
    required this.createdAt,
    this.isPinChanged = false,
    this.middleName,
    this.image,
    this.lastLogin,
    this.address = '',
    this.gender = '',
    this.dateOfBirth,
  });

  factory User.empty() {
    return User(
      id: '',
      userId: '',
      firstName: '',
      lastName: '',
      suffix: '',
      phone: '',
      email: '',
      systemAdmin: false,
      emailVerified: false,
      phoneVerified: false,
      locked: false,
      status: '',
      createdAt: DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final String email;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String suffix;
  final bool systemAdmin;
  final String? image;
  final String phone;
  final String address;
  final bool emailVerified;
  final bool phoneVerified;
  final bool isPinChanged;
  final bool locked;
  final String status;
  final String gender;
  final DateTime? lastLogin;
  final DateTime? dateOfBirth;
  final DateTime createdAt;

  String get fullName => [
    firstName.trim(),
    middleName?.trim(),
    lastName.trim(),
    suffix.trim(),
  ].where((e) => e?.isNotEmpty ?? false).join(' ');
}
