import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/shared_preferences/schemas/franchisee_info_pref.dart';
import '../../../data/shared_preferences/sources/franchisee_info_storage.dart';
import '../entities/franchisee_info.dart';

abstract class FranchiseeInfoRepository {
  Future<FranchiseeInfo> fetch();

  Future<void> save(FranchiseeInfo info);
}

final franchiseeInfoRepositoryProvider = Provider<FranchiseeInfoRepository>((ref) {
  final storage = ref.watch(franchiseeInfoStorageProvider);
  return FranchiseeInfoRepositoryImpl(storage);
});

class FranchiseeInfoRepositoryImpl implements FranchiseeInfoRepository {
  const FranchiseeInfoRepositoryImpl(this.storage);

  final FranchiseeInfoStorage storage;

  @override
  Future<FranchiseeInfo> fetch() async {
    final pref = await storage.fetch();
    return _franchiseeInfoFromPref(pref);
  }

  @override
  Future<void> save(FranchiseeInfo info) {
    final pref = _franchiseeInfoToPref(info);
    return storage.save(pref);
  }

  FranchiseeInfo _franchiseeInfoFromPref(FranchiseeInfoPref pref) {
    return FranchiseeInfo(
      legalName: pref.legalName,
      tin: pref.tin,
      addressLine1: pref.addressLine1,
      addressLine2: pref.addressLine2,
      franchiseLogo: pref.franchiseLogo,
    );
  }

  FranchiseeInfoPref _franchiseeInfoToPref(FranchiseeInfo info) {
    return FranchiseeInfoPref(
      legalName: info.legalName,
      tin: info.tin,
      addressLine1: info.addressLine1,
      addressLine2: info.addressLine2,
      franchiseLogo: info.franchiseLogo,
    );
  }
}
