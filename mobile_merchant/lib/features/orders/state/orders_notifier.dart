import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/merchant_device_storage.dart';
import '../../../core/utils/app_logger.dart';
import '../../merchant/data/merchant_api.dart';
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
  @override
  Future<OrdersState> build() async {
    final merchant = await ref.watch(merchantProvider.future);
    if (merchant == null) return const OrdersState(events: []);

    final storage = getIt<MerchantDeviceStorage>();
    final token = await storage.token;
    if (token == null || token.isEmpty) return const OrdersState(events: []);

    final dao = getIt<AppDatabase>().orderEventsDao;

    try {
      final result = await getIt<MerchantApi>().fetchOrders(
        merchantId: merchant.merchantId,
        token: token,
      );
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

  /// Optimistically updates the status of an order in both local state and DB.
  // TODO: wire to a backend PATCH /merchant/orders/{orderId}/status endpoint
  // once the API is available.
  Future<void> updateStatus(String orderId, String newStatus) async {
    final current = state.value;
    if (current == null) return;

    await getIt<AppDatabase>()
        .orderEventsDao
        .updateOrderStatus(orderId, newStatus);

    state = AsyncData(
      OrdersState(
        events: current.events
            .map((e) => e.data.id == orderId ? _withStatus(e, newStatus) : e)
            .toList(),
        isStale: current.isStale,
      ),
    );
  }

  Future<void> cancelOrder(String orderId) =>
      updateStatus(orderId, 'cancelled');

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
      ),
    );
  }
}

final ordersProvider =
    AsyncNotifierProvider<OrdersNotifier, OrdersState>(OrdersNotifier.new);
