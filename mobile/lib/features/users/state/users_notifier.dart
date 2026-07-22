import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class UsersNotifier extends AsyncNotifier<List<UsersTableData>> {
  @override
  Future<List<UsersTableData>> build() {
    final db = ref.watch(databaseProvider);
    return db.usersDao.getAllActiveUsers();
  }

  Future<void> addUser({
    required String name,
    required String role,
    required String pin,
  }) async {
    final db = ref.read(databaseProvider);
    final pinHash = BCrypt.hashpw(pin, BCrypt.gensalt());
    await db.usersDao.insertUser(UsersTableCompanion(
      name: Value(name),
      role: Value(role),
      pinHash: Value(pinHash),
    ));
    await _reload();
  }

  Future<void> editUser({
    required int id,
    required String name,
    required String role,
  }) async {
    final db = ref.read(databaseProvider);
    final user = await db.usersDao.getUserById(id);
    if (user == null) return;
    await db.usersDao.updateUser(UsersTableCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      pinHash: Value(user.pinHash),
      isActive: Value(user.isActive),
    ));
    await _reload();
  }

  Future<void> changePin({required int userId, required String newPin}) async {
    final db = ref.read(databaseProvider);
    final pinHash = BCrypt.hashpw(newPin, BCrypt.gensalt());
    await db.usersDao.updatePinHash(userId, pinHash);
    await _reload();
  }

  Future<void> deactivateUser(int userId) async {
    final db = ref.read(databaseProvider);
    await db.usersDao.deactivateUser(userId);
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
