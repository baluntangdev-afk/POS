import 'package:dart_mappable/dart_mappable.dart';

import '../preferences_storage.dart';

part 'user_grant_pref.mapper.dart';

@MappableClass()
class UserGrantPref with UserGrantPrefMappable implements Serializable {
  const UserGrantPref({required this.permissions});

  final Map<String, List<String>> permissions;

  static const fromJson = UserGrantPrefMapper.fromJson;

  static const empty = UserGrantPref(permissions: {});
}
