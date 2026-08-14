import 'package:flutter/services.dart';

import 'receipt_print_document.dart';

const _channel = MethodChannel('com.dpo.mobile/nyx_printer');

abstract final class BuiltInPrinter {
  static bool? _availableCache;

  static Future<bool> isAvailable() async {
    if (_availableCache != null) return _availableCache!;
    try {
      _availableCache = await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      _availableCache = false;
    }
    return _availableCache!;
  }

  static Future<bool> print(List<PrintInstruction> document) async {
    final payload = document.map(_encodeInstruction).toList();
    try {
      return await _channel.invokeMethod<bool>('printDocument', payload) ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Map<String, dynamic> _encodeInstruction(PrintInstruction instruction) {
    return switch (instruction) {
      PrintText() => {'type': 'text', ..._encodeText(instruction)},
      PrintRow(:final columns, :final resolvedWeights, :final minGap) => {
          'type': 'row',
          'columns': columns.map(_encodeText).toList(),
          'weights': resolvedWeights,
          'minGap': minGap,
        },
      PrintDivider(:final char) => {'type': 'divider', 'char': char},
      PrintFeed(:final lines) => {'type': 'feed', 'lines': lines},
    };
  }

  static Map<String, dynamic> _encodeText(PrintText text) => {
        'text': text.text,
        'align': text.align.name,
        'bold': text.bold,
        'sizeMultiplier': text.sizeMultiplier,
      };
}
