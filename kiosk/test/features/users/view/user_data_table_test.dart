import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/users/entities/user.dart';
import 'package:pos_app/features/users/view/user_data_table.dart';

void main() {
  // Regression test: an InkWell inside a sortable DataColumn's label pushes
  // DataTable's `SemanticsRole.columnHeader` onto its own node under the
  // heading's InkWell node, and Flutter then throws "A columnHeader must be a
  // child or another cell" on every frame — but only once semantics is on,
  // which on Windows happens as soon as any UI Automation client attaches.
  // ensureSemantics() reproduces that condition.
  testWidgets('builds a valid semantics tree with semantics enabled', (tester) async {
    final handle = tester.ensureSemantics();

    final users = [
      User.empty().copyWith(
        id: '1',
        userId: 'U-001',
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@example.com',
        phone: '0900',
        role: 'admin',
      ),
    ];

    var sorted = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserDataTable(
            users: users,
            sortColumn: 'id',
            sortAscending: true,
            onSort: (column) => sorted = column,
            onEdit: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    // Sorting still runs from the heading now that DataColumn.onSort owns the tap.
    await tester.tap(find.text('Name'));
    await tester.pump();
    expect(sorted, 'name');

    handle.dispose();
  });
}
