import 'receipt_print_document.dart';

/// Columns are laid out in fixed-width slots sized proportionally to
/// [weights], spanning the full [lineWidth] edge-to-edge — like a real
/// receipt table rather than a two-item spaceBetween row. Each column is
/// aligned per its own [PrintText.align] within its slot, so a
/// right-aligned column lands flush against the right edge of that slot
/// regardless of position.
///
/// Returns null (signalling the row should instead be printed as one line
/// per column) when:
/// - [columns] and [weights] lengths don't match,
/// - a column's text doesn't fit its weighted slot (with at least [minGap]
///   chars to spare before non-last columns), or
/// - the columns don't all share the same [PrintText.bold] — a single
///   printed line can only carry one bold style.
String? buildPrintRowLine(
  List<PrintText> columns,
  List<int> weights,
  int lineWidth,
  int minGap,
) {
  if (columns.length == 1) return columns[0].text;
  if (columns.length != weights.length) return null;
  if (columns.any((c) => c.bold != columns.first.bold)) return null;

  final totalWeight = weights.reduce((a, b) => a + b);
  final widths = <int>[];
  var used = 0;
  for (var i = 0; i < columns.length - 1; i++) {
    final width = (lineWidth * weights[i] / totalWeight).floor();
    widths.add(width);
    used += width;
  }
  widths.add(lineWidth - used);

  final segments = <String>[];
  for (var i = 0; i < columns.length; i++) {
    final text = columns[i].text;
    final width = widths[i];
    final isLast = i == columns.length - 1;

    if (text.length + (isLast ? 0 : minGap) > width) return null;

    segments.add(alignTextWithin(text, width, columns[i].align));
  }
  return segments.join();
}

String alignTextWithin(String text, int width, PrintAlign align) {
  final pad = width - text.length;
  if (pad <= 0) return text;
  return switch (align) {
    PrintAlign.left => text.padRight(width),
    PrintAlign.right => text.padLeft(width),
    PrintAlign.center => ''.padLeft(pad ~/ 2) + text + ''.padRight(pad - pad ~/ 2),
  };
}
