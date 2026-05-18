enum SaleType {
  dineIn('Dine In'),
  takeOut('Takeout'),
  delivery('Delivery');

  const SaleType(this.displayName);
  final String displayName;
}
