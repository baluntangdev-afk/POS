import '../../../core/database/app_database.dart';

class PaymentBreakdown {
  final String method;
  final double total;
  final double percentage;

  const PaymentBreakdown({
    required this.method,
    required this.total,
    required this.percentage,
  });

  String get displayName => switch (method) {
        'cash' => 'Cash',
        'card' => 'Card',
        'ewallet' => 'E-Wallet',
        _ => method,
      };
}

class TopProductData {
  final String name;
  final int quantity;
  final double total;
  const TopProductData({required this.name, required this.quantity, required this.total});
}

class ReportData {
  final double totalSales;
  final int transactionCount;
  final double averageOrder;
  final List<PaymentBreakdown> paymentBreakdown;
  final List<TopProductData> topProducts;
  final List<SalesTableData> recentSales;
  final DateTime from;
  final DateTime to;

  const ReportData({
    required this.totalSales,
    required this.transactionCount,
    required this.averageOrder,
    required this.paymentBreakdown,
    required this.topProducts,
    required this.recentSales,
    required this.from,
    required this.to,
  });
}
