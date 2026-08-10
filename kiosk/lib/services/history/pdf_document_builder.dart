import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Shared layout helper for the History PDFs (receipt + cashier reports). Mirrors the
/// narrow, continuous-roll layout the ESC/POS encoders already produce for the thermal
/// printer (see `encode_esc_pos_receipt.dart` and friends) so a saved PDF looks like the
/// paper receipt/report it was generated alongside, rather than a generic A4 document.
class PdfDocumentBuilder {
  final List<pw.Widget> _children = [];

  static const _pageWidth = 80 * PdfPageFormat.mm;
  static const _margin = 4 * PdfPageFormat.mm;

  void text(String value, {bool bold = false, bool center = true, double fontSize = 9}) {
    _children.add(
      pw.Text(
        value,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null),
      ),
    );
  }

  void row(String left, String right, {bool bold = false, double fontSize = 9}) {
    final style = pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null);
    _children.add(
      pw.Row(
        children: [
          pw.Expanded(flex: 3, child: pw.Text(left, style: style)),
          pw.Expanded(
            flex: 2,
            child: pw.Text(right, textAlign: pw.TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }

  /// A row of arbitrary [cells], each taking an equal share unless [flex] is given
  /// (same length as [cells]). Used for line-item tables (qty+description | amount).
  void tableRow(List<String> cells, {List<int>? flex, bool bold = false, double fontSize = 9}) {
    final style = pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null);
    _children.add(
      pw.Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            pw.Expanded(
              flex: flex != null ? flex[i] : 1,
              child: pw.Text(
                cells[i],
                style: style,
                textAlign: i == cells.length - 1 ? pw.TextAlign.right : pw.TextAlign.left,
              ),
            ),
        ],
      ),
    );
  }

  void divider() {
    _children.add(pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Divider()));
  }

  void spacing([double height = 6]) {
    _children.add(pw.SizedBox(height: height));
  }

  Future<Uint8List> build() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          _pageWidth,
          double.infinity,
          marginAll: _margin,
        ),
        build: (context) {
          return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: _children);
        },
      ),
    );
    return doc.save();
  }
}
