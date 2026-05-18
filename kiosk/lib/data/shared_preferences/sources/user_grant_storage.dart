import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../preferences_storage.dart';
import '../schemas/user_grant_pref.dart';
import '../shared_preferences.dart';

final userGrantStorageProvider = Provider<UserGrantStorage>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return UserGrantStorage(preferences);
});

class UserGrantStorage with PreferencesStorage<UserGrantPref> {
  UserGrantStorage(this.preferences);

  @override
  final SharedPreferencesAsync preferences;

  @override
  String get key => 'preferences.user_grant';

  @override
  UserGrantPref get defaults => UserGrantPref.empty;

  @override
  UserGrantPref fromJson(String json) => UserGrantPref.fromJson(json);
}
