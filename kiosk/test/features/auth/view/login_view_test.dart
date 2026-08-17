import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_app/features/auth/entities/login_roster_item.dart';
import 'package:pos_app/features/auth/state/login_roster_notifier.dart';
import 'package:pos_app/features/auth/view/login_view.dart';

class _EmptyRosterNotifier extends LoginRosterNotifier {
  @override
  Future<List<LoginRosterItem>> build() async => [];
}

void main() {
  testWidgets('back arrow on the select-user step navigates to the order source screen', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: LoginView(isSmallHeight: false)),
        ),
        GoRoute(path: '/order-source', builder: (_, __) => const Text('ORDER_SOURCE_SCREEN')),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [loginRosterProvider.overrideWith(_EmptyRosterNotifier.new)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('ORDER_SOURCE_SCREEN'), findsOneWidget);
  });
}
