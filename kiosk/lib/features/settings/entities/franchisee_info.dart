import 'package:dart_mappable/dart_mappable.dart';

part 'franchisee_info.mapper.dart';

@MappableClass()
class FranchiseeInfo with FranchiseeInfoMappable {
  const FranchiseeInfo({
    required this.legalName,
    required this.tin,
    required this.addressLine1,
    required this.addressLine2,
    this.franchiseLogo,
  });

  final String legalName;
  final String tin;
  final String addressLine1;
  final String addressLine2;
  final String? franchiseLogo;
}
