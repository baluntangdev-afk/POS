import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_app/features/auth/view/cartivo_register_view.dart';
import 'package:pos_app/features/cartivo_auth/entities/cartivo_auth.dart';
import 'package:pos_app/features/cartivo_auth/state/cartivo_auth_state_notifier.dart';

class _NoSessionCartivoAuthNotifier extends CartivoAuthStateNotifier {
  @override
  Future<CartivoAuth?> build() async => null;
}

void main() {
  Future<GoRouter> pumpCartivoRegister(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/cartivo-register',
      routes: [
        GoRoute(
          path: '/cartivo-register',
          builder: (_, __) => const Scaffold(body: CartivoRegisterView()),
        ),
        GoRoute(path: '/cartivo-login', builder: (_, __) => const Text('CARTIVO_LOGIN_SCREEN')),
        GoRoute(path: '/cartivo-home', builder: (_, __) => const Text('CARTIVO_HOME_SCREEN')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cartivoAuthStateProvider.overrideWith(_NoSessionCartivoAuthNotifier.new)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('mismatched confirm-password shows an inline error and does not navigate', (
    tester,
  ) async {
    await pumpCartivoRegister(tester);

    await tester.enterText(find.byType(TextField).at(1), 'merchant@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), 'password456');

    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(find.text('CARTIVO_HOME_SCREEN'), findsNothing);
  });

  testWidgets('short password shows an inline error', (tester) async {
    await pumpCartivoRegister(tester);

    await tester.enterText(find.byType(TextField).at(1), 'merchant@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'short');
    await tester.enterText(find.byType(TextField).at(3), 'short');

    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters.'), findsOneWidget);
  });

  testWidgets('back arrow and login link both navigate to the Cartivo login screen', (
    tester,
  ) async {
    await pumpCartivoRegister(tester);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('CARTIVO_LOGIN_SCREEN'), findsOneWidget);
  });
}
