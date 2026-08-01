import 'package:bcrypt/bcrypt.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/users/state/users_notifier.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('addUser creates with the default PIN and isPinChanged false', () async {
    await container.read(usersProvider.future);
    await container.read(usersProvider.notifier).addUser(
          name: 'Ana',
          role: 'supervisor',
          employeeId: 'EMP-001',
          phone: '09171234567',
        );

    final users = await container.read(usersProvider.future);
    final ana = users.firstWhere((u) => u.name == 'Ana');
    expect(ana.role, 'supervisor');
    expect(ana.employeeId, 'EMP-001');
    expect(ana.isPinChanged, isFalse);
    expect(BCrypt.checkpw('000000', ana.pinHash), isTrue);
  });

  test('editUser updates fields including isActive without needing a prior fetch', () async {
    await container.read(usersProvider.future);
    await container.read(usersProvider.notifier).addUser(name: 'Ana', role: 'cashier');
    var users = await container.read(usersProvider.future);
    final id = users.firstWhere((u) => u.name == 'Ana').id;

    await container.read(usersProvider.notifier).editUser(
          id: id,
          name: 'Ana Cruz',
          role: 'supervisor',
          isActive: false,
          phone: '09179999999',
        );

    users = await container.read(usersProvider.future);
    final updated = users.firstWhere((u) => u.id == id);
    expect(updated.name, 'Ana Cruz');
    expect(updated.role, 'supervisor');
    expect(updated.isActive, isFalse);
    expect(updated.phone, '09179999999');
  });

  test('resetPin resets to the default PIN and clears isPinChanged', () async {
    await container.read(usersProvider.future);
    await container.read(usersProvider.notifier).addUser(name: 'Ana', role: 'cashier');
    var users = await container.read(usersProvider.future);
    final id = users.firstWhere((u) => u.name == 'Ana').id;

    await container.read(usersProvider.notifier).completeOwnPinSetup(userId: id, newPin: '246810');
    users = await container.read(usersProvider.future);
    expect(users.firstWhere((u) => u.id == id).isPinChanged, isTrue);

    await container.read(usersProvider.notifier).resetPin(id);
    users = await container.read(usersProvider.future);
    final reset = users.firstWhere((u) => u.id == id);
    expect(reset.isPinChanged, isFalse);
    expect(BCrypt.checkpw('000000', reset.pinHash), isTrue);
  });

  test('deleteUser removes the row entirely', () async {
    await container.read(usersProvider.future);
    await container.read(usersProvider.notifier).addUser(name: 'Ana', role: 'cashier');
    var users = await container.read(usersProvider.future);
    final id = users.firstWhere((u) => u.name == 'Ana').id;

    await container.read(usersProvider.notifier).deleteUser(id);
    users = await container.read(usersProvider.future);
    expect(users.any((u) => u.id == id), isFalse);
  });

  test('build() lists inactive users too, not just active ones', () async {
    await container.read(usersProvider.future);
    await container.read(usersProvider.notifier).addUser(name: 'Ana', role: 'cashier');
    var users = await container.read(usersProvider.future);
    final id = users.firstWhere((u) => u.name == 'Ana').id;

    await container.read(usersProvider.notifier).editUser(
          id: id,
          name: 'Ana',
          role: 'cashier',
          isActive: false,
        );

    users = await container.read(usersProvider.future);
    expect(users.any((u) => u.id == id && !u.isActive), isTrue);
  });
}
