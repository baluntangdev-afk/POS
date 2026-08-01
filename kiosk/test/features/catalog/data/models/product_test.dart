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
        'isActive': true,
      });

      expect(variant.id, '3');
      expect(variant.name, 'Large');
      expect(variant.price, 150.0);
      expect(variant.isDefault, true);
      expect(variant.isActive, true);
    });

    test('parses the ProductVariantDetailsDto shape (displayPrice string)', () {
      final variant = CatalogProductVariant.fromJson({
        'id': 5,
        'name': 'Venti',
        'displayPrice': '175.00',
        'isDefault': false,
        'isActive': false,
      });

      expect(variant.id, '5');
      expect(variant.name, 'Venti');
      expect(variant.price, 175.0);
      expect(variant.isDefault, false);
      expect(variant.isActive, false);
    });

    test('defaults isActive to true when the backend omits it', () {
      final variant = CatalogProductVariant.fromJson({
        'id': 5,
        'name': 'Venti',
        'displayPrice': '175.00',
        'isDefault': false,
      });

      expect(variant.isActive, true);
    });
  });

  group('CatalogProductVariant.copyWith', () {
    test('overrides only the given fields', () {
      const original = CatalogProductVariant(
        id: '1',
        name: 'Regular',
        price: 100,
        isDefault: false,
        isActive: true,
      );

      final updated = original.copyWith(price: 120, isDefault: true, isActive: false);

      expect(updated.id, '1');
      expect(updated.name, 'Regular');
      expect(updated.price, 120);
      expect(updated.isDefault, true);
      expect(updated.isActive, false);
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
