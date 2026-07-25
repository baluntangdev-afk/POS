import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/auth/repositories/auth_repository_provider.dart';
import 'package:mobile/features/auth/state/auth_providers.dart';
import 'package:mobile/features/auth/state/auth_state.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> _seedUser(
    String name,
    String pin, {
    String role = 'admin',
    bool isPinChanged = true,
  }) =>
      db.usersDao.insertUser(
        UsersTableCompanion.insert(
          name: name,
          role: role,
          pinHash: BCrypt.hashpw(pin, BCrypt.gensalt()),
          isPinChanged: Value(isPinChanged),
        ),
      );

  test('logging in with isPinChanged=false sets mustChangePin, regardless of PIN typed', () async {
    // The typed PIN is deliberately NOT '000000' — proving the check is
    // driven by the persisted flag, not a transient string comparison.
    final userId = await _seedUser('Ana', '482913', isPinChanged: false);
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);

    final ok = await container.read(authNotifierProvider.notifier).login(userId, '482913');
    expect(ok, isTrue);

    final state = container.read(authNotifierProvider);
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).mustChangePin, isTrue);
  });

  test('logging in with isPinChanged=true never sets mustChangePin, even if the PIN is 000000', () async {
    // Proves the old transient "pin == '000000'" check is truly gone —
    // a user who has already changed their PIN is never re-gated, even
    // if they happen to change it back to the old default value.
    final userId = await _seedUser('Boy', '000000', isPinChanged: true);
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);

    final ok = await container.read(authNotifierProvider.notifier).login(userId, '000000');
    expect(ok, isTrue);

    final state = container.read(authNotifierProvider);
    expect((state as AuthAuthenticated).mustChangePin, isFalse);
  });

  test('completePinSetup clears mustChangePin without logging the user out', () async {
    final userId = await _seedUser('Admin', '000000', isPinChanged: false);
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.notifier).login(userId, '000000');
    expect((container.read(authNotifierProvider) as AuthAuthenticated).mustChangePin, isTrue);

    container.read(authNotifierProvider.notifier).completePinSetup();

    final state = container.read(authNotifierProvider);
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).mustChangePin, isFalse);
    expect(state.user.id, userId);
  });

  test('verifySupervisorPin succeeds for a supervisor role user, not just admin', () async {
    await _seedUser('Sup', '111222', role: 'supervisor');
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);

    final ok = await container.read(authNotifierProvider.notifier).verifySupervisorPin('111222');
    expect(ok, isTrue);
  });

  test('verifyAdminPin (repository) rejects a plain cashier role user', () async {
    await _seedUser('Cash', '333444', role: 'cashier');
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);

    final result = await container.read(authRepositoryProvider).verifyAdminPin('333444');
    expect(result.fold(onSuccess: (ok) => ok, onFailure: (_) => true), isFalse);
  });
}
