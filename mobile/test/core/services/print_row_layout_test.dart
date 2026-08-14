import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/print_row_layout.dart';
import 'package:mobile/core/services/receipt_print_document.dart';

void main() {
  group('buildPrintRowLine', () {
    test('returns the single column\'s text unchanged when there is only one column', () {
      final line = buildPrintRowLine([const PrintText('Total')], const [8], 48, 1);
      expect(line, 'Total');
    });

    test('returns null when column count does not match weight count', () {
      final line = buildPrintRowLine(
        [const PrintText('Label'), const PrintText('Amount')],
        const [8],
        48,
        1,
      );
      expect(line, isNull);
    });

    test('left-pads a default-aligned column to fill its weighted slot', () {
      final line = buildPrintRowLine(
        [const PrintText('AB'), const PrintText('CD')],
        const [8, 4],
        12,
        0,
      );
      expect(line, 'AB      CD  ');
    });

    test('right-aligns a column within its own slot based on its own align, independent of position', () {
      final line = buildPrintRowLine(
        [
          const PrintText('AB', align: PrintAlign.right),
          const PrintText('CD'),
        ],
        const [8, 4],
        12,
        0,
      );
      expect(line, '      ABCD  ');
    });

    test('center-aligns a column within its slot', () {
      final line = buildPrintRowLine(
        [
          const PrintText('AB', align: PrintAlign.center),
          const PrintText('CD'),
        ],
        const [8, 4],
        12,
        0,
      );
      expect(line, '   AB   CD  ');
    });

    test('returns null when a column plus minGap does not fit its slot', () {
      final line = buildPrintRowLine(
        [const PrintText('LongLabel'), const PrintText('9.00')],
        const [8, 4],
        12,
        10,
      );
      expect(line, isNull);
    });

    test('returns null when columns have differing bold, forcing per-column fallback', () {
      final line = buildPrintRowLine(
        [
          const PrintText('AB', bold: true),
          const PrintText('CD'),
        ],
        const [8, 4],
        12,
        0,
      );
      expect(line, isNull);
    });

    test('joins a single line when all columns share the same bold', () {
      final line = buildPrintRowLine(
        [
          const PrintText('AB', bold: true),
          const PrintText('CD', bold: true),
        ],
        const [8, 4],
        12,
        0,
      );
      expect(line, 'AB      CD  ');
    });
  });
}
