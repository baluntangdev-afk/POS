import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/merchant_device_storage.dart';
import '../../../core/utils/app_logger.dart';
import '../../merchant/data/merchant_api.dart';
import '../../merchant/domain/repositories/merchant_repository.dart';
import '../../merchant/state/merchant_notifier.dart';
import '../data/models/order_data_dto.dart';
import '../data/models/order_event_dto.dart';

class OrdersState {
  const OrdersState({required this.events, this.isStale = false});

  final List<OrderEventDto> events;

  /// True when remote fetch failed and the list was loaded from local cache.
  final bool isStale;
}

// ---------------------------------------------------------------------------

class OrdersNotifier extends AsyncNotifier<OrdersState> {
  /// Bounded ring of event ids already folded into the list via
  /// [applyLiveEvent]. A status change made here (`PATCH /merchant/orders/...`)
  /// is applied from the response, then echoed back on the live socket a moment
  /// later — this ring drops that echo so the list isn't re-mutated (which,
  /// with an out-of-order echo, could briefly revert the status).
  final Queue<String> _appliedEventIds = Queue();
  final Set<String> _appliedEventIdSet = {};

  @override
  Future<OrdersState> build() async {
    _appliedEventIds.clear();
    _appliedEventIdSet.clear();

    final merchant = await ref.watch(merchantProvider.future);
    if (merchant == null) return const OrdersState(events: []);

    final storage = getIt<MerchantDeviceStorage>();
    // A merchant with no registered device has no token path yet — show empty
    // rather than minting a throwaway token for a device that can't connect.
    if (await storage.registeredMerchantId == null) {
      return const OrdersState(events: []);
    }

    final dao = getIt<AppDatabase>().orderEventsDao;

    try {
      // Never reuse `storage.token` directly: after a merchant switch it may
      // still be scoped to the previous merchant, which the backend rejects
      // ("merchant_id does not match the merchant this token is scoped to").
      final token = await getIt<MerchantRepository>()
          .ensureWebhookToken(merchant.merchantId);
      final result = await getIt<MerchantApi>().fetchOrders(
        merchantId: merchant.merchantId,
        token: token,
      );
      // `result.events` is already current-state: MerchantOrdersDto applies
      // `order.deleted` tombstones and drops unparseable events.
      await dao.replaceAll(merchant.merchantId, result.events);
      return OrdersState(events: result.events);
    } catch (e, s) {
      AppLogger.logError('OrdersNotifier.build', e, s);
      final cached = await dao.getEvents(merchant.merchantId);
      if (cached.isEmpty) rethrow;
      return OrdersState(events: cached, isStale: true);
    }
  }

  /// Re-fetches from remote. Triggers a full rebuild via [ref.invalidateSelf].
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Moves [orderId] to [newStatus] via `PATCH /merchant/orders/{orderId}`,
  /// then folds the canonical `order.updated` event from the response into the
  /// list and local DB. Throws [MerchantApiException] on failure — the order
  /// card surfaces the message and the displayed status is left unchanged.
  Future<void> updateStatus(String orderId, String newStatus) async {
    final merchant = await ref.read(merchantProvider.future);
    if (merchant == null) {
      throw const MerchantApiException(
        statusCode: 0,
        error: 'no_merchant',
        message: 'No merchant is registered on this device.',
      );
    }

    if (await getIt<MerchantDeviceStorage>().registeredMerchantId == null) {
      throw const MerchantApiException(
        statusCode: 0,
        error: 'not_registered',
        message: 'This device is not registered yet.',
      );
    }

    // Re-mint if the stored token is stale or scoped to another merchant.
    final token = await getIt<MerchantRepository>()
        .ensureWebhookToken(merchant.merchantId);

    final result = await getIt<MerchantApi>().updateOrderStatus(
      orderId: orderId,
      status: newStatus,
      token: token,
    );

    final event = result.event;
    if (event != null) {
      await applyLiveEvent(event, merchant.merchantId);
      return;
    }

    // PATCH succeeded but echoed no usable event — write the status through
    // locally so the card still reflects the change.
    await getIt<AppDatabase>()
        .orderEventsDao
        .updateOrderStatus(orderId, newStatus);
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      OrdersState(
        events: current.events
            .map((e) => e.data.id == orderId ? _withStatus(e, newStatus) : e)
            .toList(),
        isStale: current.isStale,
      ),
    );
  }

  /// Cancels [orderId] — same endpoint, `status: 'cancelled'`.
  Future<void> cancelOrder(String orderId) =>
      updateStatus(orderId, 'cancelled');

  /// Applies one live WebSocket event without a REST reload: upsert the local
  /// row, then merge the event into the in-memory list. A DB failure is logged
  /// but never blocks the UI update; if [build] has not resolved yet only the
  /// DB write lands (the list catches up on the next fetch).
  Future<void> applyLiveEvent(OrderEventDto event, String merchantId) async {
    if (!_rememberApplied(event.eventId)) return;

    if (event.eventType == 'order.deleted') {
      await _applyDeletedEvent(event, merchantId);
      return;
    }

    try {
      await getIt<AppDatabase>()
          .orderEventsDao
          .upsertLiveEvent(merchantId, event);
    } catch (e, s) {
      AppLogger.logError('OrdersNotifier.applyLiveEvent', e, s);
    }

    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      OrdersState(
        events: mergeLiveOrderEvent(current.events, event),
        isStale: current.isStale,
      ),
    );
  }

  /// Applies one live `order.deleted` event: drop the local row (and its line
  /// items), then remove the order from the in-memory list. A DB failure is
  /// logged but never blocks the UI update.
  Future<void> _applyDeletedEvent(
    OrderEventDto event,
    String merchantId,
  ) async {
    try {
      await getIt<AppDatabase>()
          .orderEventsDao
          .deleteOrder(merchantId, event.data.id);
    } catch (e, s) {
      AppLogger.logError('OrdersNotifier._applyDeletedEvent', e, s);
    }

    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      OrdersState(
        events:
            current.events.where((e) => e.data.id != event.data.id).toList(),
        isStale: current.isStale,
      ),
    );
  }

  /// Adds [eventId] to the bounded applied-events ring. Returns false when it
  /// was already present — a duplicate delivery or the socket echo of a change
  /// we just made, which must not be folded in a second time.
  bool _rememberApplied(String eventId) {
    if (!_appliedEventIdSet.add(eventId)) return false;
    _appliedEventIds.add(eventId);
    if (_appliedEventIds.length > 200) {
      _appliedEventIdSet.remove(_appliedEventIds.removeFirst());
    }
    return true;
  }

  // ---------------------------------------------------------------------------

  static OrderEventDto _withStatus(OrderEventDto e, String newStatus) {
    final d = e.data;
    return OrderEventDto(
      id: e.id,
      receivedAt: e.receivedAt,
      eventId: e.eventId,
      eventType: e.eventType,
      createdAt: e.createdAt,
      data: OrderDataDto(
        id: d.id,
        customerId: d.customerId,
        customerName: d.customerName,
        customerEmail: d.customerEmail,
        status: newStatus,
        total: d.total,
        currency: d.currency,
        createdAt: d.createdAt,
        updatedAt: DateTime.now(),
        merchantId: d.merchantId,
        items: d.items,
        fulfillmentType: d.fulfillmentType,
        facilityName: d.facilityName,
        districtName: d.districtName,
      ),
    );
  }
}

final ordersProvider =
    AsyncNotifierProvider<OrdersNotifier, OrdersState>(OrdersNotifier.new);

/// Merges one live event into the current in-memory list: drop any existing
/// entry for the same order, then prepend the new event. Explicit by
/// `data.id` so an `updated` / `cancelled` event replaces the row correctly,
/// independent of `orders_body`'s id-based de-dupe.
List<OrderEventDto> mergeLiveOrderEvent(
  List<OrderEventDto> current,
  OrderEventDto incoming,
) =>
    [incoming, ...current.where((e) => e.data.id != incoming.data.id)];
