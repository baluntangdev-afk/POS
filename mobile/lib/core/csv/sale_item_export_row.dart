class SaleItemExportRow {
  final int saleId;
  final String productName;
  final String variantName;
  final int qty;
  final double unitPrice;
  final double discountAmount;

  const SaleItemExportRow({
    required this.saleId,
    required this.productName,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
    required this.discountAmount,
  });

  double get lineTotal => qty * unitPrice - discountAmount;
}
