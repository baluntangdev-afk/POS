import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/catalog/data/models/product.dart';

void main() {
  group('CatalogProductVariant.fromJson', () {
    test('parses the ProductVariantDto shape (raw numeric price)', () {
      final variant = CatalogProductVariant.fromJson({
        'id': 3,
        'productId': 9,
        'name': 'Large',
        'price': 150.0,
        'isDefault': true,
      });

      expect(variant.id, '3');
      expect(variant.name, 'Large');
      expect(variant.price, 150.0);
      expect(variant.isDefault, true);
    });

    test('parses the ProductVariantDetailsDto shape (displayPrice string)', () {
      final variant = CatalogProductVariant.fromJson({
        'id': 5,
        'name': 'Venti',
        'displayPrice': '175.00',
        'isDefault': false,
      });

      expect(variant.id, '5');
      expect(variant.name, 'Venti');
      expect(variant.price, 175.0);
      expect(variant.isDefault, false);
    });
  });

  group('CatalogProductVariant.copyWith', () {
    test('overrides only the given fields', () {
      const original = CatalogProductVariant(id: '1', name: 'Regular', price: 100, isDefault: false);

      final updated = original.copyWith(price: 120, isDefault: true);

      expect(updated.id, '1');
      expect(updated.name, 'Regular');
      expect(updated.price, 120);
      expect(updated.isDefault, true);
    });
  });

  group('CatalogProduct.draft', () {
    test('produces an empty, unsaved product with no variants', () {
      final draft = CatalogProduct.draft();

      expect(draft.id, '');
      expect(draft.variants, isEmpty);
      expect(draft.category, isNull);
    });
  });

  group('CatalogProduct.copyWith', () {
    test('overrides only the given fields and preserves the rest', () {
      final original = CatalogProduct.draft().copyWith(
        name: 'Latte',
        category: const CatalogCategoryRef(id: '2', name: 'Beverages'),
      );

      final updated = original.copyWith(name: 'Cappuccino');

      expect(updated.name, 'Cappuccino');
      expect(updated.category?.id, '2');
      expect(updated.price, original.price);
    });
  });
}
