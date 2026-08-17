import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/features/order_source/view/order_source_screen.dart';

void main() {
  Future<GoRouter> pumpOrderSource(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/order-source',
      routes: [
        GoRoute(path: '/order-source', builder: (_, __) => const OrderSourceContent()),
        GoRoute(path: '/login', builder: (_, __) => const Text('LOGIN_SCREEN')),
        GoRoute(path: '/cartivo-login', builder: (_, __) => const Text('CARTIVO_SCREEN')),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('tapping In Store navigates to /login', (tester) async {
    await pumpOrderSource(tester);

    expect(find.text('In Store'), findsOneWidget);
    await tester.tap(find.text('In Store'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN_SCREEN'), findsOneWidget);
  });

  testWidgets('tapping Cartivo Merchant navigates to /cartivo-login', (tester) async {
    await pumpOrderSource(tester);

    expect(find.text('Cartivo Merchant'), findsOneWidget);
    await tester.tap(find.text('Cartivo Merchant'));
    await tester.pumpAndSettle();

    expect(find.text('CARTIVO_SCREEN'), findsOneWidget);
  });
}
