import 'package:dart_mappable/dart_mappable.dart';

part 'login_roster_item.mapper.dart';

@MappableClass()
class LoginRosterItem with LoginRosterItemMappable {
  const LoginRosterItem({
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

  String get fullName => [
    firstName.trim(),
    middleName?.trim(),
    lastName.trim(),
    suffix?.trim(),
  ].where((e) => e?.isNotEmpty ?? false).join(' ');

  String get initials {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    return '$first$last'.toUpperCase();
  }
}
