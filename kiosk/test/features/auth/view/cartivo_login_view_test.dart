import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_app/features/auth/view/cartivo_login_view.dart';
import 'package:pos_app/features/cartivo_auth/entities/cartivo_auth.dart';
import 'package:pos_app/features/cartivo_auth/state/cartivo_auth_state_notifier.dart';

class _NoSessionCartivoAuthNotifier extends CartivoAuthStateNotifier {
  @override
  Future<CartivoAuth?> build() async => null;
}

void main() {
  Future<GoRouter> pumpCartivoLogin(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/cartivo-login',
      routes: [
        GoRoute(
          path: '/cartivo-login',
          builder: (_, __) => const Scaffold(body: CartivoLoginView()),
        ),
        GoRoute(path: '/order-source', builder: (_, __) => const Text('ORDER_SOURCE_SCREEN')),
        GoRoute(path: '/cartivo-register', builder: (_, __) => const Text('CARTIVO_REGISTER_SCREEN')),
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

  testWidgets('password field starts obscured and toggles visible on eye icon tap', (
    tester,
  ) async {
    await pumpCartivoLogin(tester);

    final passwordField = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    final toggledField = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(toggledField.obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('submitting empty fields shows inline validation errors and does not navigate', (
    tester,
  ) async {
    await pumpCartivoLogin(tester);

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.text('CARTIVO_HOME_SCREEN'), findsNothing);
  });

  testWidgets('back arrow navigates to the order source screen', (tester) async {
    await pumpCartivoLogin(tester);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('ORDER_SOURCE_SCREEN'), findsOneWidget);
  });

  testWidgets('Register link navigates to the Cartivo register screen', (tester) async {
    await pumpCartivoLogin(tester);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('CARTIVO_REGISTER_SCREEN'), findsOneWidget);
  });
}
