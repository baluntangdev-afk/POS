import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/customer_display/entities/customer_display_catalog.dart';
import 'package:pos_app/features/customer_display/view/menu_showcase.dart';

CustomerDisplayProduct _product(int id, {String? imageUrl}) {
  return CustomerDisplayProduct(id: id, name: 'Product $id', price: Decimal.parse('100.00'), imageUrl: imageUrl);
}

CustomerDisplayCategory _category({
  required int id,
  required String name,
  required List<CustomerDisplayProduct> products,
}) {
  return CustomerDisplayCategory(id: id, name: name, products: products);
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: SizedBox(width: 1600, height: 900, child: Material(child: child)),
    ),
  );
}

Finder _cards() => find.byWidgetPredicate((w) => w.runtimeType.toString() == '_MenuItemCard');

void main() {
  testWidgets('cards are the same size for a small category as for a large one', (tester) async {
    final small = _category(id: 1, name: 'Food', products: [_product(1), _product(2)]);
    final large = _category(
      id: 2,
      name: 'Coffee',
      products: List.generate(16, (i) => _product(i + 10)),
    );

    await _pump(tester, MenuShowcase(categories: [small], compact: false));
    final smallCardSize = tester.getSize(_cards().first);

    await _pump(tester, MenuShowcase(categories: [large], compact: false));
    final largeCardSize = tester.getSize(_cards().first);

    expect(smallCardSize, largeCardSize);
  });

  testWidgets('a product without a photo shows an accent initial instead of the cutlery icon', (tester) async {
    final category = _category(id: 1, name: 'Coffee', products: [_product(1)]);

    await _pump(tester, MenuShowcase(categories: [category], compact: false));

    expect(find.byIcon(Icons.restaurant_menu_rounded), findsNothing);
    expect(find.text('P'), findsOneWidget);
  });

  testWidgets('a category bigger than one page rotates into a second page at the same card size', (tester) async {
    final category = _category(
      id: 1,
      name: 'Coffee',
      products: List.generate(16, (i) => _product(i + 1)),
    );

    await _pump(tester, MenuShowcase(categories: [category], compact: false));
    expect(find.textContaining('Page 1 of 2'), findsOneWidget);
    final page1CardSize = tester.getSize(_cards().first);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Page 2 of 2'), findsOneWidget);
    expect(tester.getSize(_cards().first), page1CardSize);
  });
}
