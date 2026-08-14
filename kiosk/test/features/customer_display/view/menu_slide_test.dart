import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/customer_display/entities/customer_display_catalog.dart';
import 'package:pos_app/features/customer_display/view/menu_slide.dart';

CustomerDisplayProduct _product(int id) {
  return CustomerDisplayProduct(id: id, name: 'Product $id', price: Decimal.zero);
}

CustomerDisplayCategory _category({
  required int id,
  required String name,
  required int itemCount,
}) {
  return CustomerDisplayCategory(
    id: id,
    name: name,
    products: [for (var i = 1; i <= itemCount; i++) _product(i)],
  );
}

void main() {
  group('buildMenuSlides', () {
    test('returns no slides for an empty category list', () {
      final slides = buildMenuSlides(categories: const [], columns: 6, rows: 2);

      expect(slides, isEmpty);
    });

    test('a category smaller than one page produces a single slide padded with nulls', () {
      final category = _category(id: 1, name: 'Food', itemCount: 6);

      final slides = buildMenuSlides(categories: [category], columns: 6, rows: 2);

      expect(slides, hasLength(1));
      expect(slides.single.pageIndex, 0);
      expect(slides.single.pageCount, 1);
      expect(slides.single.products, hasLength(12));
      expect(slides.single.products.whereType<CustomerDisplayProduct>(), hasLength(6));
      expect(slides.single.products.sublist(6), everyElement(isNull));
    });

    test('a category that exactly fills one page has no empty cells', () {
      final category = _category(id: 1, name: 'Food', itemCount: 12);

      final slides = buildMenuSlides(categories: [category], columns: 6, rows: 2);

      expect(slides, hasLength(1));
      expect(slides.single.products, everyElement(isNotNull));
    });

    test('a category larger than one page splits into multiple slides at the same size', () {
      final category = _category(id: 1, name: 'Coffee', itemCount: 16);

      final slides = buildMenuSlides(categories: [category], columns: 6, rows: 2);

      expect(slides, hasLength(2));
      expect(slides[0].pageIndex, 0);
      expect(slides[0].pageCount, 2);
      expect(
        slides[0].products.whereType<CustomerDisplayProduct>().map((p) => p.id),
        List.generate(12, (i) => i + 1),
      );
      expect(slides[1].pageIndex, 1);
      expect(slides[1].pageCount, 2);
      expect(
        slides[1].products.whereType<CustomerDisplayProduct>().map((p) => p.id),
        [13, 14, 15, 16],
      );
      expect(slides[1].products.sublist(4), everyElement(isNull));
    });

    test('slides across multiple categories carry a stable categoryIndex/categoryCount', () {
      final categories = [
        _category(id: 1, name: 'Coffee', itemCount: 16),
        _category(id: 2, name: 'Food', itemCount: 6),
      ];

      final slides = buildMenuSlides(categories: categories, columns: 6, rows: 2);

      expect(slides, hasLength(3));
      expect(slides.map((s) => s.categoryIndex), [0, 0, 1]);
      expect(slides.every((s) => s.categoryCount == 2), isTrue);
    });

    test('an empty category still produces one slide of all-null cells', () {
      final category = _category(id: 1, name: 'Empty', itemCount: 0);

      final slides = buildMenuSlides(categories: [category], columns: 3, rows: 2);

      expect(slides, hasLength(1));
      expect(slides.single.products, hasLength(6));
      expect(slides.single.products, everyElement(isNull));
    });
  });
}
