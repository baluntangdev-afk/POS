import '../../features/ordering/entities/discount.dart';

class SaleItemExportRow {
  final int saleId;
  final String productName;
  final String variantName;
  final int qty;
  final double unitPrice;
  final double discountAmount;
  final double vatExemptAmount;

  const SaleItemExportRow({
    required this.saleId,
    required this.productName,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
    required this.discountAmount,
    this.vatExemptAmount = 0,
  });

  double get _gross => qty * unitPrice;

  // VAT-exempt (Senior/PWD) lines are sold VAT-exclusive, matching the receipt.
  double get lineTotal =>
      (vatExemptAmount > 0 ? _gross.vatExclusiveAmount : _gross) - discountAmount;
}
