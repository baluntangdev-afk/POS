import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/clock/app_clock.dart';
import '../../../data/backend_api/schemas/cartivo_order_status_request.dart';
import '../../../data/backend_api/schemas/cartivo_products_page_dto.dart';
import '../../../data/backend_api/sources/cartivo_pos_api.dart';
import '../entities/pos_order_status.dart';

final cartivoPosRepositoryProvider = Provider<CartivoPosRepository>((ref) {
  return CartivoPosRepositoryImpl(
    ref.watch(cartivoPosApiProvider),
    ref.watch(appClockProvider),
  );
});

/// Order responses are returned unchanged (as JSON maps) since their shape
/// isn't fixed yet; the products listing is decoded into typed DTOs. Failures surface as `ApiException`; map them
/// with `cartivoPosErrorFrom`.
abstract interface class CartivoPosRepository {
  Future<Map<String, dynamic>> getOrder(String orderNumber);

  /// A single page of the merchant's products. Walking every page is the
  /// caller's job (see `FetchAllCartivoProducts`).
  Future<CartivoProductsPageDto> getProductsPage(
    String merchantId, {
    int? page,
    int? limit,
    DateTime? updatedSince,
  });

  Future<Map<String, dynamic>> updateOrderStatus(
    String orderNumber,
    PosOrderStatus status, {
    String? reason,
  });
}

class CartivoPosRepositoryImpl implements CartivoPosRepository {
  const CartivoPosRepositoryImpl(this._api, this._clock);

  final CartivoPosApi _api;
  final AppClock _clock;

  @override
  Future<Map<String, dynamic>> getOrder(String orderNumber) =>
      _api.fetchOrder(orderNumber);

  @override
  Future<CartivoProductsPageDto> getProductsPage(
    String merchantId, {
    int? page,
    int? limit,
    DateTime? updatedSince,
  }) => _api.fetchMerchantProducts(
    merchantId,
    page: page,
    limit: limit,
    updatedSince: updatedSince,
  );

  @override
  Future<Map<String, dynamic>> updateOrderStatus(
    String orderNumber,
    PosOrderStatus status, {
    String? reason,
  }) => _api.updateOrderStatus(
    orderNumber,
    CartivoOrderStatusRequest(
      eventId: 'evt_${_uuidV4()}',
      status: status.cartivoName,
      occurredAt: _clock.now(),
      reason: reason,
    ),
  );

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
