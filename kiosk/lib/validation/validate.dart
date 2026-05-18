import 'package:flutter/material.dart';

class Validate<T> {
  Validate({required this.rules});

  final List<FormFieldValidator<T>> rules;

  String? call(T? input) {
    for (final rule in rules) {
      final error = rule(input);
      if (error != null) return error;
    }
    return null;
  }
}
