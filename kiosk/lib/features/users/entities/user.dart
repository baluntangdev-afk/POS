import 'package:dart_mappable/dart_mappable.dart';

part 'user.mapper.dart';

@MappableClass()
class User with UserMappable {
  const User({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.systemAdmin,
    required this.emailVerified,
    required this.phoneVerified,
    required this.locked,
    required this.status,
    required this.createdAt,
    this.role = 'user',
    this.isPinChanged = false,
    this.middleName,
    this.image,
    this.lastLogin,
  });

  factory User.empty() {
    return User(
      id: '',
      userId: '',
      firstName: '',
      lastName: '',
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
  final String role;
  final String email;
  final String firstName;
  final String? middleName;
  final String lastName;
  final bool systemAdmin;
  final String? image;
  final String phone;
  final bool emailVerified;
  final bool phoneVerified;
  final bool isPinChanged;
  final bool locked;
  final String status;
  final DateTime? lastLogin;
  final DateTime createdAt;

  String get fullName => [
    firstName.trim(),
    middleName?.trim(),
    lastName.trim(),
  ].where((e) => e?.isNotEmpty ?? false).join(' ');
}
