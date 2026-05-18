import 'package:flutter/material.dart';

FormFieldValidator<String> isEmail({String? message}) {
  return (value) {
    if (value == null || value.isEmpty) return null;

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'This field must be a valid email address.';
    }

    return null;
  };
}
