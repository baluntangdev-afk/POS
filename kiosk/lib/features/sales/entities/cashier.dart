import 'package:dart_mappable/dart_mappable.dart';

part 'cashier.mapper.dart';

@MappableClass()
class Cashier with CashierMappable {
  const Cashier({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.suffix,
  });

  factory Cashier.unknown() => const Cashier(id: -1, employeeId: '', firstName: '', lastName: '');

  final int id;
  final String employeeId;
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
