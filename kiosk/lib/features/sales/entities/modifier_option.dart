import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

part 'modifier_option.mapper.dart';

@MappableClass()
class ModifierOption with ModifierOptionMappable {
  const ModifierOption({required this.id, required this.name, required this.price, this.image});

  final int id;
  final String name;
  final Decimal price;
  final Uint8List? image;
}
