import 'package:flutter/material.dart';

typedef ProductPlaceholderStyle = ({IconData icon, Color bg, Color fg});

const ProductPlaceholderStyle defaultProductPlaceholder = (
  icon: Icons.lunch_dining,
  bg: Color(0xFFFFF3E0),
  fg: Color(0xFFD4854A),
);

/// Returns a placeholder style matched against a category name or product name.
ProductPlaceholderStyle productPlaceholder(String? hint) {
  if (hint == null) return defaultProductPlaceholder;
  final n = hint.toLowerCase();

  if (_any(n, ['drink', 'beverage', 'juice', 'soda', 'coffee', 'tea', 'shake', 'smoothie', 'water', 'buko', 'latte', 'cappuccino', 'espresso', 'frappe', 'mocha'])) {
    return (icon: Icons.local_cafe, bg: const Color(0xFFE3F2FD), fg: const Color(0xFF1565C0));
  }
  if (_any(n, ['baking', 'bakery', 'bread', 'pastry', 'croissant', 'pandesal', 'loaf', 'muffin', 'biscuit'])) {
    return (icon: Icons.bakery_dining, bg: const Color(0xFFFFF8F0), fg: const Color(0xFFBF8B5F));
  }
  if (_any(n, ['dessert', 'cake', 'ice cream', 'sweet', 'halo', 'candy', 'cookie', 'donut', 'gelato', 'chocolate', 'caramel', 'pudding'])) {
    return (icon: Icons.icecream, bg: const Color(0xFFFCE4EC), fg: const Color(0xFFAD1457));
  }
  if (_any(n, ['pizza'])) {
    return (icon: Icons.local_pizza, bg: const Color(0xFFFFF3E0), fg: const Color(0xFFE65100));
  }
  if (_any(n, ['burger', 'sandwich', 'wrap', 'hotdog'])) {
    return (icon: Icons.lunch_dining, bg: const Color(0xFFFFF3E0), fg: const Color(0xFFD4854A));
  }
  if (_any(n, ['noodle', 'pasta', 'ramen', 'mami', 'pansit', 'pancit', 'spaghetti', 'soup', 'lomi', 'batchoy'])) {
    return (icon: Icons.ramen_dining, bg: const Color(0xFFFFF8E1), fg: const Color(0xFFF9A825));
  }
  if (_any(n, ['rice', 'silog', 'sinangag', 'kanin'])) {
    return (icon: Icons.rice_bowl, bg: const Color(0xFFF1F8E9), fg: const Color(0xFF558B2F));
  }
  if (_any(n, ['chicken', 'pork', 'beef', 'meat', 'steak', 'bbq', 'barbeque', 'grill', 'fried', 'inasal', 'liempo', 'lechon'])) {
    return (icon: Icons.set_meal, bg: const Color(0xFFFBE9E7), fg: const Color(0xFFBF360C));
  }
  if (_any(n, ['breakfast', 'egg', 'brunch', 'morning'])) {
    return (icon: Icons.breakfast_dining, bg: const Color(0xFFFFFDE7), fg: const Color(0xFFF57F17));
  }
  if (_any(n, ['snack', 'side', 'fries', 'chips', 'appetizer', 'starter', 'merienda'])) {
    return (icon: Icons.cookie, bg: const Color(0xFFFFF8E1), fg: const Color(0xFFFF8F00));
  }
  if (_any(n, ['seafood', 'fish', 'shrimp', 'crab', 'sushi', 'bangus', 'tilapia', 'squid'])) {
    return (icon: Icons.set_meal, bg: const Color(0xFFE0F7FA), fg: const Color(0xFF00695C));
  }
  if (_any(n, ['salad', 'veggie', 'vegetable', 'healthy', 'green'])) {
    return (icon: Icons.eco, bg: const Color(0xFFE8F5E9), fg: const Color(0xFF2E7D32));
  }
  return defaultProductPlaceholder;
}

bool _any(String text, List<String> keywords) => keywords.any((k) => text.contains(k));
