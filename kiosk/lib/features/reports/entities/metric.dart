import 'package:flutter/material.dart';

class Metric {
  const Metric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isMonetary = true,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isMonetary;
  final String? subtitle;
}
