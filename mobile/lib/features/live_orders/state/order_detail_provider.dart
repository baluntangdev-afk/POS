import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/order_event.dart';
import '../repositories/cartivo_pos_repository.dart';

final orderDetailProvider = FutureProvider.autoDispose.family<OrderData, String>((
  ref,
  orderNumber,
) async {
  final body = await ref.watch(cartivoPosRepositoryProvider).getOrder(orderNumber);
  return OrderData.fromJson(_unwrapOrder(body, orderNumber));
});

Map<String, dynamic> _unwrapOrder(Map<String, dynamic> body, String orderNumber) {
  var json = body;
  for (final key in const ['data', 'order']) {
    final nested = json[key];
    if (nested is Map) json = nested.cast<String, dynamic>();
  }
  if (json['id'] is! String) json = {...json, 'id': orderNumber};
  return json;
}
