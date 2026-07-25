import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';

const _seededKey = 'admin_seeded';

/// The default PIN assigned to every newly-created user (matching kiosk's
/// `devicePin: '000000'` on create). Every such user is created with
/// `isPinChanged: false`, forcing them through the setup-PIN gate on first
/// login — this constant is public so `UsersNotifier.addUser`/`resetPin` can
/// reuse it instead of duplicating the literal.
const defaultSeededPin = '000000';

class AdminSeeder {
  final AppDatabase _db;

  const AdminSeeder(this._db);

  Future<void> seed() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) == true) return;

    final hasAdmin = await _db.usersDao.hasAdmin();
    if (!hasAdmin) {
      final pinHash = BCrypt.hashpw(defaultSeededPin, BCrypt.gensalt());
      await _db.usersDao.insertUser(
        UsersTableCompanion.insert(
          name: 'Admin',
          role: 'admin',
          pinHash: pinHash,
          isActive: const Value(true),
          isPinChanged: const Value(false),
        ),
      );
    }

    await prefs.setBool(_seededKey, true);
  }
}
