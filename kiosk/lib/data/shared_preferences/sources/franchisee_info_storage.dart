import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../preferences_storage.dart';
import '../schemas/franchisee_info_pref.dart';
import '../shared_preferences.dart';

final franchiseeInfoStorageProvider = Provider<FranchiseeInfoStorage>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return FranchiseeInfoStorage(preferences);
});

class FranchiseeInfoStorage with PreferencesStorage<FranchiseeInfoPref> {
  FranchiseeInfoStorage(this.preferences);

  @override
  final SharedPreferencesAsync preferences;

  @override
  String get key => 'preferences.franchisee_info';

  @override
  FranchiseeInfoPref get defaults => FranchiseeInfoPref.empty;

  @override
  FranchiseeInfoPref fromJson(String json) => FranchiseeInfoPref.fromJson(json);
}
