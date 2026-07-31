enum PaymentMethodType {
  cash('Cash'),
  gCash('GCash'),
  other('Other');

  const PaymentMethodType(this.label);

  final String label;
}
