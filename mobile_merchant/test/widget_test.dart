import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_merchant/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen renders its title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DashboardScreen()),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
