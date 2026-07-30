class RefundItem {
  final int id;
  final int receiptItemId;
  final int sequence;
  final String description;
  final int quantity;
  final double refundAmount;
  final bool isMain;

  const RefundItem({
    required this.id,
    required this.receiptItemId,
    required this.sequence,
    required this.description,
    required this.quantity,
    required this.refundAmount,
    required this.isMain,
  });
}
