enum SalesDataItemType {
  productGroup('Product Group'),
  product('Product'),
  user('User'),
  payment('Payment Method');

  const SalesDataItemType(this.title);

  final String title;
}
