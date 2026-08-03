class SalePayment {
  final String method; // 'cash' | 'card' | 'ewallet'
  final double amountPaid;
  final double cashReceived;
  final String? reference;

  const SalePayment({
    required this.method,
    required this.amountPaid,
    required this.cashReceived,
    this.reference,
  });

  double get change => (cashReceived - amountPaid).clamp(0.0, double.infinity);
}
