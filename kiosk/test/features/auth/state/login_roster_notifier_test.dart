import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_app/features/auth/entities/auth.dart';
import 'package:pos_app/features/auth/entities/login_roster_item.dart';
import 'package:pos_app/features/auth/repositories/auth_repository.dart';
import 'package:pos_app/features/auth/state/login_roster_notifier.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.roster);

  List<LoginRosterItem> roster;
  bool shouldThrow = false;
  int getLoginRosterCallCount = 0;

  @override
  Future<List<LoginRosterItem>> getLoginRoster() async {
    getLoginRosterCallCount++;
    if (shouldThrow) throw Exception('network error');
    return roster;
  }

  @override
  Future<Auth> getCurrent() async => throw UnimplementedError();

  @override
  Future<Auth> login(String username, String pin) async => throw UnimplementedError();

  @override
  Future<bool> logout() async => throw UnimplementedError();

  @override
  Future<Auth> changePin(int id, String newPin) async => throw UnimplementedError();
}

const _jane = LoginRosterItem(id: 1, userId: 'USR-001', firstName: 'Jane', lastName: 'Doe');

void main() {
  test('build() fetches the roster from the repository', () async {
    final repo = _FakeAuthRepository([_jane]);
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final result = await container.read(loginRosterProvider.future);

    expect(result, [_jane]);
    expect(repo.getLoginRosterCallCount, 1);
  });

  test('build() surfaces repository errors as AsyncError', () async {
    final repo = _FakeAuthRepository([])..shouldThrow = true;
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    try {
      await container.read(loginRosterProvider.future);
    } catch (_) {
      // Expected: build() rethrows the repository's error.
    }

    expect(container.read(loginRosterProvider).hasError, isTrue);
    expect(repo.getLoginRosterCallCount, 1);
  });
}
