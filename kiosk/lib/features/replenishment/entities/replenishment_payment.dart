import 'package:dart_mappable/dart_mappable.dart';

part 'replenishment_payment.mapper.dart';

@MappableClass()
class ReplenishmentPayment with ReplenishmentPaymentMappable {
  const ReplenishmentPayment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;
}
