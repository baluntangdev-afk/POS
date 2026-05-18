import 'dart:math'; // Import math for min/max

import 'package:flutter/services.dart';

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Calculate cursor position relative to digits
    var meaningfulCharsBeforeCursor = 0;
    for (var i = 0; i < newValue.selection.end; i++) {
      if (newValue.text[i].contains(RegExp(r'[0-9.]'))) {
        meaningfulCharsBeforeCursor++;
      }
    }

    // Sanitize and validate
    final newTextRaw = newValue.text.replaceAll(',', '');

    // Handle empty input
    if (newTextRaw.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Prevent non-numeric input
    if (newTextRaw.contains(RegExp(r'[^0-9.]'))) {
      return oldValue;
    }

    // Prevent multiple dots
    if (newTextRaw.indexOf('.') != newTextRaw.lastIndexOf('.')) {
      return oldValue;
    }

    // Separate integer and decimal parts
    final parts = newTextRaw.split('.');
    var integerPart = parts[0];
    var decimalPart = parts.length > 1 ? parts[1] : null;

    // Truncate decimal parts to 2 places
    if (decimalPart != null && decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    // Remove leading zeros (e.g. 05 -> 5)
    if (integerPart.length > 1 && integerPart.startsWith('0')) {
      integerPart = integerPart.substring(1);
    }

    // Format the integer part with commas
    final regEx = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInteger = integerPart.replaceAllMapped(regEx, (matches) => '${matches[1]},');

    // Reassemble final string
    var finalString = formattedInteger;
    if (decimalPart != null) {
      finalString += '.$decimalPart';
    } else if (newTextRaw.endsWith('.')) {
      finalString += '.';
    }

    // Restore cursor position
    var newCursorOffset = 0;
    var meaningfulCharsEncountered = 0;

    for (var i = 0; i < finalString.length; i++) {
      // If we've found our spot, break
      if (meaningfulCharsEncountered == meaningfulCharsBeforeCursor) {
        break;
      }

      // If the current char is a digit or dot, increment our counter
      if (finalString[i].contains(RegExp(r'[0-9.]'))) {
        meaningfulCharsEncountered++;
      }

      // Move cursor forward
      newCursorOffset++;
    }

    // Ensure cursor is within bounds
    newCursorOffset = min(newCursorOffset, finalString.length);

    return TextEditingValue(
      text: finalString,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}
