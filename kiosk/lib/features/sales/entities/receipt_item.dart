import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

import '../enums/sale_type.dart';

part 'receipt_item.mapper.dart';

@MappableClass()
class ReceiptItem with ReceiptItemMappable {
  const ReceiptItem({
    required this.id,
    required this.sequence,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.grossAmount,
    required this.discountCode,
    required this.discountRate,
    required this.discountAmount,
    required this.vatExclusiveAmount,
    required this.vatAmount,
    required this.totalAmount,
    required this.isMain,
    this.saleType,
    this.note,
    this.category,
    this.discountBeneficiaryIdNumber,
    this.discountBeneficiaryName,
  });

  final String id;
  final int sequence;
  final String description;
  final int quantity;
  final Decimal unitPrice;
  final Decimal grossAmount;
  final String discountCode;
  final Decimal discountRate;
  final Decimal discountAmount;
  final Decimal vatExclusiveAmount;
  final Decimal vatAmount;
  final Decimal totalAmount;
  final bool isMain;
  final SaleType? saleType;
  final String? note;
  final String? category;
  final String? discountBeneficiaryIdNumber;
  final String? discountBeneficiaryName;
}
