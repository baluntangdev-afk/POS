import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/customer_display/entities/customer_display_snapshot.dart';
import 'package:pos_app/features/customer_display/view/order_customer_view.dart';

void main() {
  testWidgets('OrderCustomerView renders line items and totals', (tester) async {
    final snapshot = CustomerDisplayOrdering(
      items: [
        CustomerDisplayLineItem(
          productName: 'Iced Coffee',
          quantity: 2,
          variantLabel: 'Large',
          lineTotal: Decimal.parse('240.00'),
          discountAmount: Decimal.zero,
        ),
      ],
      subtotal: Decimal.parse('240.00'),
      discount: Decimal.parse('20.00'),
      tax: Decimal.zero,
      total: Decimal.parse('220.00'),
    );

    await tester.pumpWidget(
      MaterialApp(home: OrderCustomerView(snapshot: snapshot, catalog: null)),
    );

    expect(find.textContaining('Iced Coffee'), findsOneWidget);
    expect(find.textContaining('2'), findsWidgets);
    expect(find.textContaining('220.00'), findsOneWidget);
  });

  testWidgets('OrderCustomerView shows the discount tag on the discounted item', (tester) async {
    final snapshot = CustomerDisplayOrdering(
      items: [
        CustomerDisplayLineItem(
          productName: 'Iced Coffee',
          quantity: 1,
          lineTotal: Decimal.parse('120.00'),
          discountLabel: 'Senior Citizen / PWD',
          discountAmount: Decimal.parse('20.00'),
        ),
      ],
      subtotal: Decimal.parse('120.00'),
      discount: Decimal.parse('20.00'),
      tax: Decimal.zero,
      total: Decimal.parse('100.00'),
    );

    await tester.pumpWidget(
      MaterialApp(home: OrderCustomerView(snapshot: snapshot, catalog: null)),
    );

    expect(find.text('Senior Citizen / PWD'), findsOneWidget);
    // Shows twice by design here: once as the per-item tag, once in the
    // aggregate "Discount" totals row — expected since there's only one
    // item, so the aggregate equals that item's own discount.
    expect(find.text('-₱20.00'), findsNWidgets(2));
  });
}
