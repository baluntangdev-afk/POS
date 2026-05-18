import 'package:flutter/material.dart';

FormFieldValidator<String> isPhone({String? message}) {
  return (value) {
    if (value == null || value.isEmpty) return null;

    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'This field must be a valid phone number.';
    }

    if (value.replaceAll(RegExp(r'[\D]'), '').length < 10) {
      return 'Phone number must be at least 10 digits.';
    }

    return null;
  };
}
