import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/shared_preferences/schemas/franchisee_info_pref.dart';
import '../../../data/shared_preferences/sources/franchisee_info_storage.dart';
import '../entities/store.dart';

abstract class StoreRepository {
  Future<Store> getCurrent();
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final storage = ref.watch(franchiseeInfoStorageProvider);
  return StoreRepositoryImpl(storage);
});

class StoreRepositoryImpl implements StoreRepository {
  const StoreRepositoryImpl(this._franchiseeInfoStorage);

  final FranchiseeInfoStorage _franchiseeInfoStorage;

  @override
  Future<Store> getCurrent() async {
    final pref = await _franchiseeInfoStorage.fetch();
    return _storeFromFranchiseeInfoPref(pref);
  }

  Store _storeFromFranchiseeInfoPref(FranchiseeInfoPref pref) {
    return Store(
      legalName: pref.legalName,
      tin: pref.tin,
      addressLine1: pref.addressLine1,
      addressLine2: pref.addressLine2,
      logo: pref.franchiseLogo,
    );
  }
}
