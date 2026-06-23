import 'package:dart_mappable/dart_mappable.dart';

part 'auth.mapper.dart';

@MappableClass()
class Auth with AuthMappable {
  const Auth({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.suffix,
    this.isPinChanged = false,
    this.role = 'user',
  });

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? suffix;
  final bool isPinChanged;
  final String role;

  bool get isAdminOrSupervisor => role == 'admin' || role == 'supervisor';

  String get fullName => [
    firstName.trim(),
    middleName?.trim(),
    lastName.trim(),
    suffix?.trim(),
  ].where((e) => e?.isNotEmpty ?? false).join(' ');
}
