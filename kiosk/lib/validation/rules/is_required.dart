import 'package:flutter/material.dart';

FormFieldValidator<String> isRequired({String? message}) {
  return (input) {
    return (input == null || input.isEmpty) ? message ?? 'This field is required.' : null;
  };
}
