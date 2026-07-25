import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/auth/state/auth_providers.dart';
import 'package:mobile/features/auth/state/auth_state.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> _seedUser(String name, String pin, {String role = 'admin'}) => db.usersDao.insertUser(
        UsersTableCompanion.insert(
          name: name,
          role: role,
          pinHash: BCrypt.hashpw(pin, BCrypt.gensalt()),
        ),
      );

  test('logging in with the known default PIN sets mustChangePin', () async {
    final userId = await _seedUser('Admin', '000000');
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);

    final ok = await container.read(authNotifierProvider.notifier).login(userId, '000000');
    expect(ok, isTrue);

    final state = container.read(authNotifierProvider);
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).mustChangePin, isTrue);
  });

  test('logging in with a non-default PIN does not set mustChangePin', () async {
    final userId = await _seedUser('Ana', '135790', role: 'user');
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);

    final ok = await container.read(authNotifierProvider.notifier).login(userId, '135790');
    expect(ok, isTrue);

    final state = container.read(authNotifierProvider);
    expect((state as AuthAuthenticated).mustChangePin, isFalse);
  });

  test('completePinSetup clears mustChangePin without logging the user out', () async {
    final userId = await _seedUser('Admin', '000000');
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
}
