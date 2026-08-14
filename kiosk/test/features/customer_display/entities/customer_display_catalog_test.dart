import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/customer_display/entities/customer_display_catalog.dart';
import 'package:pos_app/features/sales/entities/product.dart';
import 'package:pos_app/features/sales/entities/product_group.dart';
import 'package:pos_app/features/sales/entities/store.dart';

Product _product({required int id, required String name, required String price, String image = ''}) {
  return Product(
    id: id,
    name: name,
    image: image,
    price: Decimal.parse(price),
    modifierGroups: const IList.empty(),
    categoryName: 'Coffee',
  );
}

void main() {
  group('CustomerDisplayProduct.fromProduct', () {
    test('maps id, name, price and treats an empty image string as no image', () {
      final result = CustomerDisplayProduct.fromProduct(
        _product(id: 1, name: 'Iced Coffee', price: '120.00'),
      );

      expect(result.id, 1);
      expect(result.name, 'Iced Coffee');
      expect(result.price, Decimal.parse('120.00'));
      expect(result.imageUrl, isNull);
    });

    test('keeps a non-empty image URL', () {
      final result = CustomerDisplayProduct.fromProduct(
        _product(id: 2, name: 'Cheeseburger', price: '150.00', image: 'https://example.com/cb.png'),
      );

      expect(result.imageUrl, 'https://example.com/cb.png');
    });
  });

  group('CustomerDisplayCategory.build', () {
    test('maps group fields and treats an empty image as no image', () {
      final group = ProductGroup(id: 5, name: 'Coffee & Cold Brew', image: Uint8List(0));

      final result = CustomerDisplayCategory.build(
        group: group,
        products: [_product(id: 1, name: 'Iced Coffee', price: '120.00')],
      );

      expect(result.id, 5);
      expect(result.name, 'Coffee & Cold Brew');
      expect(result.image, isNull);
      expect(result.products.single.name, 'Iced Coffee');
    });

    test('keeps a non-empty category image', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final group = ProductGroup(id: 5, name: 'Coffee', image: bytes);

      final result = CustomerDisplayCategory.build(group: group, products: const []);

      expect(result.image, bytes);
    });
  });

  group('CustomerDisplayCatalog.build', () {
    test('maps store name/logo and carries categories through', () {
      const store = Store(
        legalName: 'Test Store',
        tin: '000',
        addressLine1: 'Addr 1',
        addressLine2: 'Addr 2',
        logo: 'https://example.com/logo.png',
      );
      final group = ProductGroup(id: 5, name: 'Coffee', image: Uint8List(0));
      final category = CustomerDisplayCategory.build(group: group, products: const []);

      final result = CustomerDisplayCatalog.build(store: store, categories: [category]);

      expect(result.storeName, 'Test Store');
      expect(result.storeLogoUrl, 'https://example.com/logo.png');
      expect(result.categories.single.id, 5);
    });
  });

  group('CustomerDisplayCatalog transport round-trip', () {
    test('survives toTransportMap/fromTransportMap including bytes and Decimal', () {
      final bytes = Uint8List.fromList([9, 8, 7]);
      final catalog = CustomerDisplayCatalog(
        storeName: 'Test Store',
        storeLogoUrl: null,
        categories: [
          CustomerDisplayCategory(
            id: 5,
            name: 'Coffee',
            image: bytes,
            products: [
              CustomerDisplayProduct(id: 1, name: 'Iced Coffee', price: Decimal.zero, imageUrl: null),
            ],
          ),
        ],
      );

      final decoded = CustomerDisplayCatalog.fromTransportMap(catalog.toTransportMap());

      expect(decoded.storeName, 'Test Store');
      expect(decoded.categories.single.name, 'Coffee');
      expect(decoded.categories.single.image, bytes);
      expect(decoded.categories.single.products.single.name, 'Iced Coffee');
    });

    test(
      'decodes a real platform-channel-shaped payload (two levels of Map<Object?, Object?> nesting)',
      () {
        // Regression test — see the matching test in customer_display_snapshot_test.dart
        // for why: desktop_multi_window's IPC round-trips arguments through
        // StandardMethodCodec, which decodes nested maps/lists as
        // Map<Object?, Object?>/List<Object?>, not Map<String, dynamic>. The catalog
        // is two levels deep (categories -> products), so both levels need to survive.
        final Map<Object?, Object?> channelShaped = {
          'storeName': 'Tambayan Picklehub',
          'storeLogoUrl': null,
          'categories': <Object?>[
            <Object?, Object?>{
              'id': 1,
              'name': 'Coffee',
              'image': null,
              'products': <Object?>[
                <Object?, Object?>{
                  'id': 10,
                  'name': 'Iced Coffee',
                  'price': '120.00',
                  'imageUrl': null,
                },
              ],
            },
          ],
        };

        final decoded = CustomerDisplayCatalog.fromTransportMap(channelShaped);

        expect(decoded.storeName, 'Tambayan Picklehub');
        expect(decoded.categories.single.name, 'Coffee');
        expect(decoded.categories.single.products.single.name, 'Iced Coffee');
        expect(decoded.categories.single.products.single.price, Decimal.parse('120.00'));
      },
    );
  });
}
