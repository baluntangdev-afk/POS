import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/cashier_accounting/daily_report/entities/daily_report_data.dart';
import '../../features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import '../../features/cashier_accounting/z_reading/entities/z_reading_data.dart';
import '../../features/ordering/entities/receipt.dart';
import 'built_in_printer.dart';
import 'print_row_layout.dart';
import 'receipt_print_document.dart';
import 'report_print_document.dart';

const _prefMacKey = 'printer_mac';
const _prefNameKey = 'printer_name';

abstract final class PrintService {
  static Future<String?> getSavedMac() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefMacKey);
  }

  static Future<String?> getSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefNameKey);
  }

  static Future<void> savePrinter(String mac, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefMacKey, mac);
    await prefs.setString(_prefNameKey, name);
  }

  static Future<void> clearPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefMacKey);
    await prefs.remove(_prefNameKey);
  }

  static Future<bool> printReceipt(
    Receipt receipt, {
    String storeFooter = 'Thank You!',
    String? storeName,
    String? storeAddress,
    String? storeTin,
    String? terminalName,
  }) {
    final document = ReceiptPrintDocument.build(
      receipt,
      storeName: storeName,
      storeAddress: storeAddress,
      storeTin: storeTin,
      terminalName: terminalName,
      storeFooter: storeFooter,
    );
    return _printDocument(document);
  }

  static Future<bool> printXReading(
    XReadingData data, {
    String currency = 'PHP',
  }) {
    return _printDocument(
      XReadingPrintDocument.build(data, currency: currency),
    );
  }

  static Future<bool> printDailyReport(
    DailyReportData data, {
    String currency = 'PHP',
  }) {
    return _printDocument(
      DailyReportPrintDocument.build(data, currency: currency),
    );
  }

  static Future<bool> printZReading(
    ZReadingData data, {
    String currency = 'PHP',
  }) {
    return _printDocument(
      ZReadingPrintDocument.build(data, currency: currency),
    );
  }

  /// Prints a two-line ruler (tens markers over a repeating 0-9 scale) via
  /// whichever path [_printDocument] would normally pick. Both printer paths
  /// send the raw line unbroken and let the printer's own firmware wrap it,
  /// so the column where the first physical line ends is the printer's true
  /// edge-to-edge character capacity — use that to correct [_lineWidthChars]
  /// (Bluetooth, below) or `LINE_WIDTH_CHARS` in NyxPrinterPlugin.kt.
  static Future<bool> printCalibration() => _printDocument(_calibrationDocument());

  /// Same ruler, forced through the Bluetooth path even if a built-in
  /// printer is also available, so both printers can be measured
  /// independently.
  static Future<bool> printCalibrationBluetooth() =>
      _printViaBluetooth(_calibrationDocument());

  static List<PrintInstruction> _calibrationDocument({int length = 96}) {
    return [
      const PrintText('CALIBRATION', align: PrintAlign.center, bold: true),
      PrintText(_calibrationTensLine(length)),
      PrintText(_calibrationUnitsLine(length)),
      const PrintFeed(3),
    ];
  }

  static String _calibrationTensLine(int length) {
    final buffer = StringBuffer();
    for (var i = 1; i <= length; i++) {
      buffer.write(i % 10 == 0 ? (i ~/ 10 % 10).toString() : ' ');
    }
    return buffer.toString();
  }

  static String _calibrationUnitsLine(int length) {
    final buffer = StringBuffer();
    for (var i = 1; i <= length; i++) {
      buffer.write((i % 10).toString());
    }
    return buffer.toString();
  }

  /// Prints one labelled test line per candidate width in [range]: each line
  /// is exactly that many characters, ending in `|`. If the printer's true
  /// capacity is >= the candidate width, the `|` prints attached to the end
  /// of the line; otherwise it spills alone onto the next physical line.
  /// The highest candidate whose `|` stays attached is the printer's real
  /// edge-to-edge character capacity — no character-counting required, just
  /// reading whether each `|` is attached or wrapped.
  static Future<bool> printWidthProbe({List<int> range = const [
    50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
  ]}) => _printDocument(_widthProbeDocument(range));

  static Future<bool> printWidthProbeBluetooth({List<int> range = const [
    50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
  ]}) => _printViaBluetooth(_widthProbeDocument(range));

  static List<PrintInstruction> _widthProbeDocument(List<int> range) {
    final instructions = <PrintInstruction>[
      const PrintText('WIDTH PROBE', align: PrintAlign.center, bold: true),
    ];
    for (final width in range) {
      instructions.add(PrintText('W=$width'));
      instructions.add(PrintText('${'#' * (width - 1)}|'));
    }
    instructions.add(const PrintFeed(3));
    return instructions;
  }

  /// Prints via the device's built-in thermal printer when present, falling
  /// back to a paired Bluetooth printer otherwise. Every document type
  /// (receipt, X-Reading, Daily Report, Z-Reading) goes through this same
  /// dispatch so none of them can silently skip the built-in printer.
  static Future<bool> _printDocument(List<PrintInstruction> document) async {
    if (await BuiltInPrinter.isAvailable()) {
      return BuiltInPrinter.print(document);
    }
    return _printViaBluetooth(document);
  }

  static Future<bool> _printViaBluetooth(
    List<PrintInstruction> document,
  ) async {
    final mac = await getSavedMac();
    if (mac == null) return false;

    final connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: mac,
    );
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      var bytes = <int>[];

      bytes += generator.reset();
      for (final instruction in document) {
        bytes += _encodeBluetoothInstruction(generator, instruction);
      }
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }

  static List<int> _encodeBluetoothInstruction(
    Generator generator,
    PrintInstruction instruction,
  ) {
    return switch (instruction) {
      PrintText(
        :final text,
        :final align,
        :final bold,
        :final sizeMultiplier,
      ) =>
        generator.text(
          text,
          styles: PosStyles(
            align: _posAlign(align),
            bold: bold,
            height: sizeMultiplier >= 2 ? PosTextSize.size2 : PosTextSize.size1,
            width: sizeMultiplier >= 2 ? PosTextSize.size2 : PosTextSize.size1,
          ),
        ),
      PrintRow(:final columns, :final resolvedWeights, :final minGap) =>
        _generateRowBytes(generator, columns, resolvedWeights, minGap),
      PrintDivider() => generator.hr(),
      PrintFeed(:final lines) => generator.feed(lines),
    };
  }

  // esc_pos_utils_plus (PaperSize.mm80, font A) prints 48 chars/line — see
  // Generator._getMaxCharsPerLine, which isn't exposed publicly.
  static const int _lineWidthChars = 48;

  // Columns are laid out in fixed-width slots sized proportionally to
  // [weights], spanning the full [_lineWidthChars] edge-to-edge — like a
  // real receipt table rather than a two-item spaceBetween row. Each column
  // is aligned per its own [PrintText.align] within its slot, so a
  // right-aligned column lands flush against the right edge of that slot.
  // A row is only joined into one physical line when every column shares
  // the same [PrintText.bold]; otherwise each column is printed with its
  // own style on its own line. Matches the built-in Nyx printer path
  // (NyxPrinterPlugin.kt).
  static List<int> _generateRowBytes(
    Generator generator,
    List<PrintText> columns,
    List<int> weights,
    int minGap,
  ) {
    final line = buildPrintRowLine(columns, weights, _lineWidthChars, minGap);
    if (line != null) {
      return generator.text(line, styles: PosStyles(bold: columns.first.bold));
    }

    var bytes = <int>[];
    for (final column in columns) {
      bytes += generator.text(
        column.text,
        styles: PosStyles(align: _posAlign(column.align), bold: column.bold),
      );
    }
    return bytes;
  }

  static PosAlign _posAlign(PrintAlign align) => switch (align) {
    PrintAlign.left => PosAlign.left,
    PrintAlign.center => PosAlign.center,
    PrintAlign.right => PosAlign.right,
  };
}
