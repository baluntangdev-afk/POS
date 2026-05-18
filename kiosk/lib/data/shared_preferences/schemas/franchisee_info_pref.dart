import 'package:dart_mappable/dart_mappable.dart';

import '../preferences_storage.dart';

part 'franchisee_info_pref.mapper.dart';

@MappableClass()
class FranchiseeInfoPref with FranchiseeInfoPrefMappable implements Serializable {
  const FranchiseeInfoPref({
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

  static const fromJson = FranchiseeInfoPrefMapper.fromJson;

  static const empty = FranchiseeInfoPref(
    legalName: '',
    addressLine1: '',
    addressLine2: '',
    tin: '',
  );
}
