class TransactionSummary {
  final int id;
  final String storeId;
  final String? soNumber;
  final String cashierName;
  final DateTime createdAt;
  final double total;
  final double discount;
  final String status;
  final String type;
  final double refundedAmount;
  final DateTime? syncedAt;

  const TransactionSummary({
    required this.id,
    this.soNumber,
    required this.storeId,
    required this.cashierName,
    required this.createdAt,
    required this.total,
    required this.discount,
    required this.status,
    required this.type,
    required this.refundedAmount,
    this.syncedAt,
  });

  bool get isSynced => syncedAt != null;

  bool get isVoided => status == 'voided';

  double get netTotal =>
      (total - discount - refundedAmount).clamp(0.0, double.infinity);

  bool get hasRefunds => refundedAmount > 0;

  bool get isFullyRefunded => refundedAmount >= (total - discount) - 0.001;

  String get invoiceNumber => soNumber ?? '#${id.toString().padLeft(6, '0')}';

  String get displayType => switch (type) {
    'dine_in' => 'Dine In',
    'take_out' => 'Take Out',
    'delivery' => 'Delivery',
    _ => type,
  };
}
