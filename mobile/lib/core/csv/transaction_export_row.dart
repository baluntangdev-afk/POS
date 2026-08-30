class TransactionExportRow {
  final int id;
  final String? soNumber;
  final String cashierName;
  final DateTime createdAt;
  final double total;
  final double discount;
  final String status;
  final String type;
  final double refundedAmount;
  final String? voidReason;
  final List<String> paymentMethods;

  const TransactionExportRow({
    required this.id,
    this.soNumber,
    required this.cashierName,
    required this.createdAt,
    required this.total,
    required this.discount,
    required this.status,
    required this.type,
    required this.refundedAmount,
    this.voidReason,
    required this.paymentMethods,
  });

  String get invoiceNumber => soNumber ?? '#${id.toString().padLeft(6, '0')}';

  String get displayType => switch (type) {
        'dine_in' => 'Dine In',
        'take_out' => 'Take Out',
        'delivery' => 'Delivery',
        _ => type,
      };

  String get displayStatus => switch (status) {
        'completed' => 'Completed',
        'voided' => 'Voided',
        'refunded' => 'Refunded',
        _ => status,
      };

  double get netTotal => (total - discount - refundedAmount).clamp(0.0, double.infinity);
}
