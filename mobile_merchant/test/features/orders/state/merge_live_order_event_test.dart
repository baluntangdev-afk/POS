import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_merchant/features/orders/data/models/order_data_dto.dart';
import 'package:mobile_merchant/features/orders/data/models/order_event_dto.dart';
import 'package:mobile_merchant/features/orders/state/orders_notifier.dart';

OrderEventDto event({
  required int id,
  required String orderId,
  String status = 'pending',
}) =>
    OrderEventDto(
      id: id,
      receivedAt: DateTime(2026, 1, 1),
      eventId: 'evt_$id',
      eventType: 'order.updated',
      createdAt: DateTime(2026, 1, 1),
      data: OrderDataDto(
        id: orderId,
        customerId: 'c',
        status: status,
        total: 1,
        currency: 'PHP',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        merchantId: 'm',
        items: const [],
      ),
    );

void main() {
  group('mergeLiveOrderEvent', () {
    test('prepends a brand-new order', () {
      final current = [event(id: 1, orderId: 'ord_1')];
      final merged = mergeLiveOrderEvent(current, event(id: 2, orderId: 'ord_2'));
      expect(merged.map((e) => e.data.id), ['ord_2', 'ord_1']);
    });

    test('replaces an existing order in place at the head, no duplicate', () {
      final current = [
        event(id: 1, orderId: 'ord_1', status: 'pending'),
        event(id: 2, orderId: 'ord_2'),
      ];
      final merged =
          mergeLiveOrderEvent(current, event(id: 9, orderId: 'ord_1', status: 'ready'));
      expect(merged, hasLength(2));
      expect(merged.first.data.id, 'ord_1');
      expect(merged.first.data.status, 'ready');
      expect(merged.where((e) => e.data.id == 'ord_1'), hasLength(1));
    });

    test('handles an empty starting list', () {
      final merged = mergeLiveOrderEvent(const [], event(id: 1, orderId: 'ord_1'));
      expect(merged.map((e) => e.data.id), ['ord_1']);
    });
  });
}
