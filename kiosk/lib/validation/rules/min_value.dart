import 'package:flutter/material.dart';

FormFieldValidator<double> minValue(double limit, {String? message}) {
  return (input) {
    if (input == null) return null;
    return (input < limit) ? message ?? 'This field must be at least $limit.' : null;
  };
}
