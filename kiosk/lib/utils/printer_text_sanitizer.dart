/// ESC/POS text is encoded as latin1 by `esc_pos_utils_plus`, which throws
/// `Invalid argument (string): Contains invalid characters.` for any
/// character outside 0x00-0xFF. Sources like `intl` date formatting (which
/// can insert a narrow no-break space U+202F between time and AM/PM) or
/// backend-supplied names/addresses/notes can contain such characters, so
/// every piece of dynamic text sent to the printer must be sanitized first.
const _charReplacements = <int, String>{
  0x2018: "'", 0x2019: "'", 0x201A: "'", 0x201B: "'", // single quotes
  0x201C: '"', 0x201D: '"', 0x201E: '"', 0x201F: '"', // double quotes
  0x2012: '-', 0x2013: '-', 0x2014: '-', 0x2015: '-', // dashes
  0x2026: '...', // ellipsis
  0x00A0: ' ', 0x1680: ' ', 0x2000: ' ', 0x2001: ' ', 0x2002: ' ',
  0x2003: ' ', 0x2004: ' ', 0x2005: ' ', 0x2006: ' ', 0x2007: ' ',
  0x2008: ' ', 0x2009: ' ', 0x200A: ' ', 0x202F: ' ', 0x205F: ' ',
  0x3000: ' ', // Unicode space variants (incl. the narrow no-break space
  // intl inserts between time and AM/PM in newer CLDR data)
  0x200B: '', 0xFEFF: '', // zero-width space / BOM
};

/// Replaces common typographic Unicode characters with ASCII equivalents and
/// falls back to `?` for anything else outside the latin1 range, so the
/// result is always safe to hand to `Generator.text`/`Generator.row`.
String sanitizeForPrinter(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final replacement = _charReplacements[rune];
    if (replacement != null) {
      buffer.write(replacement);
    } else if (rune <= 0xFF) {
      buffer.writeCharCode(rune);
    } else {
      buffer.write('?');
    }
  }
  return buffer.toString();
}
