@TestOn('vm')
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_merchant/core/database/app_database.dart';
import 'package:mobile_merchant/features/orders/data/models/order_data_dto.dart';
import 'package:mobile_merchant/features/orders/data/models/order_event_dto.dart';
import 'package:mobile_merchant/features/orders/data/models/order_item_dto.dart';

OrderEventDto liveEvent({
  required int id,
  required String orderId,
  String status = 'pending',
  List<OrderItemDto> items = const [],
  String dataMerchantId = 'ignored-uses-arg',
}) =>
    OrderEventDto(
      id: id,
      receivedAt: DateTime(2026, 1, 1),
      eventId: 'evt_$id',
      eventType: status == 'cancelled' ? 'order.cancelled' : 'order.updated',
      createdAt: DateTime(2026, 1, 1),
      data: OrderDataDto(
        id: orderId,
        customerId: 'c',
        status: status,
        total: 10,
        currency: 'PHP',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1, id),
        merchantId: dataMerchantId,
        items: items,
      ),
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.withExecutor(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('inserts a new live event as one row with its items', () async {
    await db.orderEventsDao.upsertLiveEvent(
      'merch_1',
      liveEvent(
        id: 1000,
        orderId: 'ord_1',
        items: const [
          OrderItemDto(productId: 'p1', productName: 'A', quantity: 2, price: 5),
        ],
      ),
    );

    final events = await db.orderEventsDao.getEvents('merch_1');
    expect(events, hasLength(1));
    expect(events.single.data.id, 'ord_1');
    expect(events.single.data.merchantId, 'merch_1');
    expect(events.single.data.items, hasLength(1));
  });

  test('a second event for the same order updates in place, keeps the id, replaces items', () async {
    await db.orderEventsDao.upsertLiveEvent(
      'merch_1',
      liveEvent(
        id: 1000,
        orderId: 'ord_1',
        items: const [
          OrderItemDto(productId: 'p1', productName: 'A', quantity: 1, price: 5),
        ],
      ),
    );
    await db.orderEventsDao.upsertLiveEvent(
      'merch_1',
      liveEvent(
        id: 2000,
        orderId: 'ord_1',
        status: 'ready',
        items: const [
          OrderItemDto(productId: 'p2', productName: 'B', quantity: 3, price: 7),
        ],
      ),
    );

    final events = await db.orderEventsDao.getEvents('merch_1');
    expect(events, hasLength(1));
    expect(events.single.id, 1000); // kept the original row id
    expect(events.single.data.status, 'ready');
    expect(events.single.data.items.map((i) => i.productId), ['p2']);
  });

  test('same orderId under two merchants stays separate', () async {
    await db.orderEventsDao.upsertLiveEvent('merch_1', liveEvent(id: 1, orderId: 'ord_x'));
    await db.orderEventsDao.upsertLiveEvent('merch_2', liveEvent(id: 2, orderId: 'ord_x'));

    expect(await db.orderEventsDao.getEvents('merch_1'), hasLength(1));
    expect(await db.orderEventsDao.getEvents('merch_2'), hasLength(1));
  });

  test('replaceAll collapses a multi-event order history to one row', () async {
    await db.orderEventsDao.replaceAll('merch_1', [
      liveEvent(id: 10, orderId: 'ord_1', status: 'pending', dataMerchantId: 'merch_1'),
      liveEvent(id: 20, orderId: 'ord_1', status: 'ready', dataMerchantId: 'merch_1'),
      liveEvent(id: 5, orderId: 'ord_2', status: 'pending', dataMerchantId: 'merch_1'),
    ]);

    final events = await db.orderEventsDao.getEvents('merch_1');
    expect(events, hasLength(2));
    final ord1 = events.firstWhere((e) => e.data.id == 'ord_1');
    expect(ord1.id, 20); // kept the latest event
    expect(ord1.data.status, 'ready');
  });

  test('upsertLiveEvent heals pre-existing duplicate rows for an order',
      () async {
    // Simulate a cache written before replaceAll deduped: two rows, one order.
    await db.orderEventsDao.replaceAll('merch_1', [
      liveEvent(id: 100, orderId: 'ord_1', status: 'pending', dataMerchantId: 'merch_1'),
    ]);
    await db.into(db.orderEventsTable).insert(
          OrderEventsTableCompanion.insert(
            id: const Value(101),
            eventId: 'evt_101',
            eventType: 'order.updated',
            receivedAt: DateTime(2026, 1, 1).toIso8601String(),
            createdAt: DateTime(2026, 1, 1).toIso8601String(),
            merchantId: 'merch_1',
            orderId: 'ord_1',
            customerId: 'c',
            orderStatus: 'ready',
            orderTotal: 10,
            currency: 'PHP',
            orderCreatedAt: DateTime(2026, 1, 1).toIso8601String(),
            orderUpdatedAt: DateTime(2026, 1, 1).toIso8601String(),
          ),
        );

    // Would previously throw StateError: Too many elements.
    await db.orderEventsDao.upsertLiveEvent(
      'merch_1',
      liveEvent(id: 999, orderId: 'ord_1', status: 'completed'),
    );

    final events = await db.orderEventsDao.getEvents('merch_1');
    expect(events, hasLength(1));
    expect(events.single.id, 101); // newest surviving row updated in place
    expect(events.single.data.status, 'completed');
  });
}
