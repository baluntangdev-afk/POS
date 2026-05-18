import 'package:shared_preferences/shared_preferences.dart';

abstract class Serializable {
  String toJson();
}

mixin PreferencesStorage<T extends Serializable> {
  SharedPreferencesAsync get preferences;

  String get key;

  T get defaults;

  T fromJson(String json);

  Future<void> save(T value) async {
    await preferences.setString(key, value.toJson());
  }

  Future<void> clear() async {
    await preferences.remove(key);
  }

  Future<T> fetch() async {
    final stored = await preferences.getString(key);

    if (stored == null) return defaults;

    try {
      return fromJson(stored);
    } catch (e) {
      return defaults;
    }
  }
}
