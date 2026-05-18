import 'package:dart_mappable/dart_mappable.dart';

import '../enums/role.dart';

part 'access.mapper.dart';

@MappableClass()
class Access with AccessMappable {
  const Access({
    required this.employeeId,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.suffix,
  });

  factory Access.unknown() {
    return const Access(employeeId: '', role: Role.user, firstName: '', lastName: '');
  }

  final String employeeId;
  final Role role;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? suffix;

  String get fullName => [
    firstName.trim(),
    middleName?.trim(),
    lastName.trim(),
    suffix?.trim(),
  ].where((e) => e?.isNotEmpty ?? false).join(' ');
}
