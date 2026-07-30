import 'discount.dart';

class ReceiptItem {
  final int id;
  final int sequence;
  final String description;
  final int quantity;
  final double unitPrice;
  final double grossAmount;
  final double discountAmount;
  final double totalAmount;
  final bool isMain;
  final String? discountType;
  final String? discountBeneficiaryId;
  final String? discountBeneficiaryName;
  final double vatExemptAmount;

  const ReceiptItem({
    required this.id,
    required this.sequence,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.grossAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.isMain,
    this.discountType,
    this.discountBeneficiaryId,
    this.discountBeneficiaryName,
    this.vatExemptAmount = 0,
  });

  bool get isVatExempt => vatExemptAmount > 0;
  double get vatExclusiveAmount => grossAmount.vatExclusiveAmount;
  double get vatAmount => isVatExempt ? 0 : grossAmount.vatAmount;
}
