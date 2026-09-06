import 'package:injectable/injectable.dart';

import 'app_database.dart';

/// Registers the Drift [AppDatabase] as a lazy singleton. Kept separate from the
/// entity class so the injectable generator does not try to resolve the
/// `@visibleForTesting` test constructor.
@module
abstract class DatabaseModule {
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();
}
