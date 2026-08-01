import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/users_table.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [UsersTable])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<List<UsersTableData>> getAllActiveUsers() =>
      (select(usersTable)..where((t) => t.isActive.equals(true))).get();

  Future<List<UsersTableData>> getAllUsers() => select(usersTable).get();

  Future<UsersTableData?> getUserById(int id) =>
      (select(usersTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<bool> hasAdmin() async {
    final result = await (select(usersTable)
          ..where((t) => t.role.equals('admin'))
          ..where((t) => t.isActive.equals(true)))
        .get();
    return result.isNotEmpty;
  }

  Future<int> insertUser(UsersTableCompanion companion) =>
      into(usersTable).insert(companion);

  Future<int> updateUser(UsersTableCompanion companion) =>
      (update(usersTable)..where((t) => t.id.equals(companion.id.value)))
          .write(companion);

  Future<int> deactivateUser(int id) => (update(usersTable)
        ..where((t) => t.id.equals(id)))
      .write(const UsersTableCompanion(isActive: Value(false)));

  Future<int> updatePinHash(int userId, String newPinHash) =>
      (update(usersTable)..where((t) => t.id.equals(userId)))
          .write(UsersTableCompanion(pinHash: Value(newPinHash)));

  Future<int> deleteUser(int id) =>
      (delete(usersTable)..where((t) => t.id.equals(id))).go();

  Future<int> resetPin(int userId, String defaultPinHash) =>
      (update(usersTable)..where((t) => t.id.equals(userId))).write(
        UsersTableCompanion(pinHash: Value(defaultPinHash), isPinChanged: const Value(false)),
      );

  Future<int> completePinSetup(int userId, String newPinHash) =>
      (update(usersTable)..where((t) => t.id.equals(userId))).write(
        UsersTableCompanion(pinHash: Value(newPinHash), isPinChanged: const Value(true)),
      );
}
