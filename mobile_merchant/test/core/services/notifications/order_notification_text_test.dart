import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_merchant/core/notifications/order_toast.dart';
import 'package:mobile_merchant/core/services/notifications/order_notifications_service.dart';
import 'package:mobile_merchant/features/orders/data/models/order_data_dto.dart';
import 'package:mobile_merchant/features/orders/data/models/order_event_dto.dart';
import 'package:mobile_merchant/features/orders/data/models/order_item_dto.dart';

OrderEventDto event(String eventType, {int itemCount = 1, double total = 12.5}) =>
    OrderEventDto(
      id: 1,
      receivedAt: DateTime(2026, 1, 1),
      eventId: 'evt_1',
      eventType: eventType,
      createdAt: DateTime(2026, 1, 1),
      data: OrderDataDto(
        id: 'ord_1',
        customerId: 'c',
        status: 'preparing',
        total: total,
        currency: 'PHP',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        merchantId: 'm',
        items: List.generate(
          itemCount,
          (_) => const OrderItemDto(
              productId: 'p', productName: 'X', quantity: 1, price: 1),
        ),
      ),
    );

void main() {
  group('orderNotificationText', () {
    test('order.created: title + item/total body', () {
      final t = orderNotificationText(event('order.created', itemCount: 2, total: 30));
      expect(t.title, 'New order #ord_1');
      expect(t.body, '2 items · PHP 30.00');
    });

    test('order.created: singular item', () {
      expect(orderNotificationText(event('order.created', itemCount: 1)).body,
          startsWith('1 item · '));
    });

    test('order.cancelled: empty body', () {
      final t = orderNotificationText(event('order.cancelled'));
      expect(t.title, 'Order #ord_1 cancelled');
      expect(t.body, '');
    });

    test('any other type: updated + status', () {
      final t = orderNotificationText(event('order.updated'));
      expect(t.title, 'Order #ord_1 updated');
      expect(t.body, 'Status: preparing');
    });
  });

  test('showOrderToast is a no-op when no ScaffoldMessenger is attached', () {
    // appScaffoldMessengerKey.currentState is null in a pure unit test.
    expect(() => showOrderToast(event('order.created')), returnsNormally);
  });
}
