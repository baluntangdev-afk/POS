extension VatCalculator on double {
  double get vatExclusiveAmount {
    final net = this / 1.12;
    return (net * 100).round() / 100;
  }

  double get vatAmount => this - vatExclusiveAmount;
}

sealed class Discount {
  const Discount();

  bool get isVatExempt;

  String get code;

  double calculateAmount(double originalAmount);
}

class SeniorPwdDiscount extends Discount {
  const SeniorPwdDiscount({required this.beneficiaryId, required this.beneficiaryName});

  final String beneficiaryId;
  final String beneficiaryName;

  @override
  bool get isVatExempt => true;

  @override
  String get code => 'Senior Citizen / PWD';

  static const rate = 20;

  @override
  double calculateAmount(double originalAmount) {
    final vatExclusive = originalAmount.vatExclusiveAmount;
    return ((vatExclusive * rate / 100) * 100).round() / 100;
  }
}

class PromoDiscount extends Discount {
  const PromoDiscount({required this.code});

  @override
  final String code;

  @override
  bool get isVatExempt => false;

  // Mirrors kiosk's current Promo behavior: captures a code but doesn't
  // apply an actual discount amount yet.
  @override
  double calculateAmount(double originalAmount) => 0;
}
