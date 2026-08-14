import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/receipt_print_document.dart';

void main() {
  group('PrintRow.resolvedWeights', () {
    test('returns the given weights unchanged when provided', () {
      const row = PrintRow(
        columns: [PrintText('A'), PrintText('B')],
        weights: [8, 4],
      );
      expect(row.resolvedWeights, [8, 4]);
    });

    test('defaults to equal weights across all columns when omitted', () {
      const row = PrintRow(
        columns: [PrintText('A'), PrintText('B')],
      );
      expect(row.resolvedWeights, [1, 1]);
    });

    test('defaults to equal weights for three columns when omitted', () {
      const row = PrintRow(
        columns: [PrintText('A'), PrintText('B'), PrintText('C')],
      );
      expect(row.resolvedWeights, [1, 1, 1]);
    });
  });
}
