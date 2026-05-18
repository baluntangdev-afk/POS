import 'package:dart_mappable/dart_mappable.dart';

part 'store.mapper.dart';

@MappableClass()
class Store with StoreMappable {
  const Store({
    required this.legalName,
    required this.tin,
    required this.addressLine1,
    required this.addressLine2,
    this.logo,
  });

  final String legalName;
  final String tin;
  final String addressLine1;
  final String addressLine2;
  final String? logo;
}
