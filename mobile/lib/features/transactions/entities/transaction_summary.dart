class TransactionSummary {
  final int id;
  final String cashierName;
  final DateTime createdAt;
  final double total;
  final double discount;
  final String status;
  final String type;
  final double refundedAmount;

  const TransactionSummary({
    required this.id,
    required this.cashierName,
    required this.createdAt,
    required this.total,
    required this.discount,
    required this.status,
    required this.type,
    required this.refundedAmount,
  });

  bool get isVoided => status == 'voided';
  double get netTotal => (total - discount - refundedAmount).clamp(0.0, double.infinity);
  bool get hasRefunds => refundedAmount > 0;
  bool get isFullyRefunded => refundedAmount >= (total - discount) - 0.001;
  String get invoiceNumber => '#${id.toString().padLeft(6, '0')}';

  String get displayType => switch (type) {
        'dine_in' => 'Dine In',
        'take_out' => 'Take Out',
        'delivery' => 'Delivery',
        _ => type,
      };
}
