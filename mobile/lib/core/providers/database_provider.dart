import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in ProviderScope');
});
