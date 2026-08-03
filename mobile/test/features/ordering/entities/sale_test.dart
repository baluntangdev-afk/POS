import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ordering/entities/discount.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/entities/sale.dart';

void main() {
  test('Sale.total subtracts each item\'s computed discount from subtotal', () {
    final sale = Sale(
      type: 'dine_in',
      createdAt: DateTime(2026, 7, 30),
      items: [
        LineItem(
          id: 'a',
          productId: 1,
          productName: 'Burger',
          groupName: 'Mains',
          imageUrl: null,
          basePrice: 50,
          quantity: 2,
          modifiers: const [],
          discount: const SeniorPwdDiscount(beneficiaryId: '123', beneficiaryName: 'Juan'),
        ),
      ],
    );

    expect(sale.subtotal, 100);
    // 20% of the VAT-exclusive amount: (100 / 1.12) * 0.20 ≈ 17.86
    expect(sale.totalDiscount, closeTo(17.86, 0.01));
    expect(sale.total, closeTo(82.14, 0.01));
  });
}
