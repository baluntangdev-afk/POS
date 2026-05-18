import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

part 'payment.mapper.dart';

@MappableClass()
sealed class Payment with PaymentMappable {
  const Payment({
    this.id = '', // Empty string means payment was not recorded yet.
    required this.paidAmount,
  });

  final String id;
  final Decimal paidAmount;
}

@MappableClass()
class CashPayment extends Payment with CashPaymentMappable {
  const CashPayment({super.id, required super.paidAmount, required this.cashReceived})
    : assert(
        cashReceived >= paidAmount,
        'Cash received must be greater than or equal to paid amount.',
      );

  final Decimal cashReceived;

  Decimal get change => cashReceived - paidAmount;
}

@MappableClass()
class CardPayment extends Payment with CardPaymentMappable {
  const CardPayment({
    super.id,
    required super.paidAmount,
    required this.referenceNumber,
    required this.cardType,
    required this.cardNumber,
    this.cardHolder,
  }) : assert(cardNumber.length == 4, 'Card number must only include the last 4 digits.');

  final String referenceNumber;
  final String cardType;
  final String cardNumber;
  final String? cardHolder;
}

@MappableClass()
class QRPayment extends Payment with QRPaymentMappable {
  const QRPayment({
    super.id,
    required super.paidAmount,
    required this.referenceNumber,
    required this.walletProvider,
  });

  final String referenceNumber;
  final String walletProvider;
}

@MappableClass()
class ZeroPayment extends Payment with ZeroPaymentMappable {
  ZeroPayment({super.id}) : super(paidAmount: Decimal.zero);
}
