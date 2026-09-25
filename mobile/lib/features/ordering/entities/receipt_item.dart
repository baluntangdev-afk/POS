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

  /// Category (product group) of the product at print time; null when the
  /// product or its category no longer exists. Add-ons carry their parent's.
  final String? categoryName;
  final int categorySortOrder;

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
    this.categoryName,
    this.categorySortOrder = 0,
  });

  bool get isVatExempt => vatExemptAmount > 0;
  // Legacy VAT-exempt (Senior/PWD) lines report their VAT-exclusive gross;
  // every other line is taxed on what was actually paid (net of discount).
  double get _vatBase => isVatExempt ? grossAmount : grossAmount - discountAmount;
  double get vatExclusiveAmount => _vatBase.vatExclusiveAmount;
  double get vatAmount => isVatExempt ? 0 : _vatBase.vatAmount;

  /// Amount actually paid per unit — net of discount and, for VAT-exempt
  /// (Senior/PWD) lines, net of VAT.
  double get netUnitPrice => quantity == 0 ? 0 : totalAmount / quantity;

  /// Refund owed for [qty] units, based on what the customer actually paid.
  double refundAmountFor(int qty) =>
      quantity == 0 ? 0 : ((totalAmount * qty / quantity) * 100).round() / 100;
}
