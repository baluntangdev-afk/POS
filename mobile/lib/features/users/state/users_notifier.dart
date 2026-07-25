import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/seeder/admin_seeder.dart';

class UsersNotifier extends AsyncNotifier<List<UsersTableData>> {
  @override
  Future<List<UsersTableData>> build() {
    final db = ref.watch(databaseProvider);
    return db.usersDao.getAllUsers();
  }

  /// New users always start on the same default PIN and `isPinChanged: false`
  /// (matching kiosk's `devicePin: '000000'` on create) — the admin/supervisor
  /// never chooses a new user's PIN directly.
  Future<void> addUser({
    required String name,
    required String role,
    String? employeeId,
    String? phone,
    String? avatarUrl,
  }) async {
    final db = ref.read(databaseProvider);
    final pinHash = BCrypt.hashpw(defaultSeededPin, BCrypt.gensalt());
    await db.usersDao.insertUser(UsersTableCompanion.insert(
      name: name,
      role: role,
      pinHash: pinHash,
      employeeId: Value(employeeId),
      phone: Value(phone),
      avatarUrl: Value(avatarUrl),
      isPinChanged: const Value(false),
    ));
    await _reload();
  }

  Future<void> editUser({
    required int id,
    required String name,
    required String role,
    required bool isActive,
    String? employeeId,
    String? phone,
    String? avatarUrl,
  }) async {
    final db = ref.read(databaseProvider);
    await db.usersDao.updateUser(UsersTableCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      isActive: Value(isActive),
      employeeId: Value(employeeId),
      phone: Value(phone),
      avatarUrl: Value(avatarUrl),
    ));
    await _reload();
  }

  /// Resets the target user back to the default PIN and clears
  /// `isPinChanged`, forcing them through setup again next login — mirrors
  /// kiosk's `resetPin(userId)`, which never lets the admin choose the value.
  Future<void> resetPin(int userId) async {
    final db = ref.read(databaseProvider);
    final pinHash = BCrypt.hashpw(defaultSeededPin, BCrypt.gensalt());
    await db.usersDao.resetPin(userId, pinHash);
    await _reload();
  }

  /// Called only by the user themselves from `SetupPinScreen` — sets their
  /// own chosen PIN and marks `isPinChanged: true` in one write.
  Future<void> completeOwnPinSetup({required int userId, required String newPin}) async {
    final db = ref.read(databaseProvider);
    final pinHash = BCrypt.hashpw(newPin, BCrypt.gensalt());
    await db.usersDao.completePinSetup(userId, pinHash);
    await _reload();
  }

  Future<void> deleteUser(int userId) async {
    final db = ref.read(databaseProvider);
    await db.usersDao.deleteUser(userId);
    await _reload();
  }

  Future<void> refresh() => _reload();

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

final usersProvider =
    AsyncNotifierProvider<UsersNotifier, List<UsersTableData>>(UsersNotifier.new);
