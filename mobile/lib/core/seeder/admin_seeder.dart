import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';

const _seededKey = 'admin_seeded';
const _defaultPin = '000000';

class AdminSeeder {
  final AppDatabase _db;

  const AdminSeeder(this._db);

  Future<void> seed() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) == true) return;

    final hasAdmin = await _db.usersDao.hasAdmin();
    if (!hasAdmin) {
      final pinHash = BCrypt.hashpw(_defaultPin, BCrypt.gensalt());
      await _db.usersDao.insertUser(
        UsersTableCompanion.insert(
          name: 'Admin',
          role: 'admin',
          pinHash: pinHash,
          isActive: const Value(true),
        ),
      );
    }

    await prefs.setBool(_seededKey, true);
  }
}
