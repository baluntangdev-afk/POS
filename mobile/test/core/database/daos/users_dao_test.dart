import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> _seedUser(String name, {String role = 'cashier', bool isPinChanged = true}) =>
      db.usersDao.insertUser(UsersTableCompanion.insert(
        name: name,
        role: role,
        pinHash: BCrypt.hashpw('135790', BCrypt.gensalt()),
        isPinChanged: Value(isPinChanged),
      ));

  test('schemaVersion is at least 5', () {
    expect(db.schemaVersion, greaterThanOrEqualTo(5));
  });

  test('employeeId, phone, avatarUrl, isPinChanged round-trip', () async {
    final id = await db.usersDao.insertUser(UsersTableCompanion.insert(
      name: 'Ana',
      role: 'cashier',
      pinHash: 'hash',
      employeeId: const Value('EMP-001'),
      phone: const Value('09171234567'),
      avatarUrl: const Value('/some/path.png'),
      isPinChanged: const Value(false),
    ));

    final row = await db.usersDao.getUserById(id);
    expect(row!.employeeId, 'EMP-001');
    expect(row.phone, '09171234567');
    expect(row.avatarUrl, '/some/path.png');
    expect(row.isPinChanged, isFalse);
  });

  test('isPinChanged defaults to true when not explicitly set (migration safety)', () async {
    final id = await db.usersDao.insertUser(UsersTableCompanion.insert(
      name: 'Boy',
      role: 'cashier',
      pinHash: 'hash',
    ));
    final row = await db.usersDao.getUserById(id);
    expect(row!.isPinChanged, isTrue);
  });

  test('updateUser performs a partial update without clobbering unspecified fields', () async {
    final id = await _seedUser('Ana');
    await db.usersDao.updateUser(UsersTableCompanion(
      id: Value(id),
      employeeId: const Value('EMP-999'),
      phone: const Value('09170000000'),
    ));

    await db.usersDao.updateUser(
      UsersTableCompanion(id: Value(id), phone: const Value('09171111111')),
    );

    final row = await db.usersDao.getUserById(id);
    expect(row!.phone, '09171111111');
    expect(row.employeeId, 'EMP-999');
    expect(row.name, 'Ana');
  });

  test('deleteUser removes the row entirely', () async {
    final id = await _seedUser('Ana');
    await db.usersDao.deleteUser(id);
    expect(await db.usersDao.getUserById(id), isNull);
  });

  test('resetPin sets the given hash and clears isPinChanged', () async {
    final id = await _seedUser('Ana', isPinChanged: true);
    final defaultHash = BCrypt.hashpw('000000', BCrypt.gensalt());

    await db.usersDao.resetPin(id, defaultHash);

    final row = await db.usersDao.getUserById(id);
    expect(row!.pinHash, defaultHash);
    expect(row.isPinChanged, isFalse);
  });

  test('completePinSetup sets the given hash and marks isPinChanged true', () async {
    final id = await _seedUser('Ana', isPinChanged: false);
    final newHash = BCrypt.hashpw('246810', BCrypt.gensalt());

    await db.usersDao.completePinSetup(id, newHash);

    final row = await db.usersDao.getUserById(id);
    expect(row!.pinHash, newHash);
    expect(row.isPinChanged, isTrue);
  });

  test('getAllUsers returns both active and inactive users; getAllActiveUsers only active', () async {
    final activeId = await _seedUser('Ana');
    final inactiveId = await db.usersDao.insertUser(UsersTableCompanion.insert(
      name: 'Boy',
      role: 'cashier',
      pinHash: 'hash',
      isActive: const Value(false),
    ));

    final all = await db.usersDao.getAllUsers();
    expect(all.map((u) => u.id), containsAll([activeId, inactiveId]));

    final active = await db.usersDao.getAllActiveUsers();
    expect(active.map((u) => u.id), contains(activeId));
    expect(active.map((u) => u.id), isNot(contains(inactiveId)));
  });
}
