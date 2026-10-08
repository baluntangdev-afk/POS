import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/cartivo_products_page_dto.dart';
import '../repositories/cartivo_pos_repository.dart';
import 'cartivo_pos_error.dart';

final fetchAllCartivoProductsProvider = Provider<FetchAllCartivoProducts>((ref) {
  return FetchAllCartivoProducts(ref.watch(cartivoPosRepositoryProvider));
});

typedef CartivoSyncProgress = void Function(int fetched, int total);

class CartivoProductsSyncResult {
  const CartivoProductsSyncResult({
    required this.products,
    required this.watermark,
    required this.total,
  });

  final List<CartivoProductDto> products;

  final DateTime watermark;

  final int total;
}

enum CartivoProductsSyncFailure {
  pageOverrun,
  incomplete,
}

class CartivoProductsSyncException implements Exception {
  const CartivoProductsSyncException(this.failure);

  final CartivoProductsSyncFailure failure;

  String get message => switch (failure) {
    CartivoProductsSyncFailure.pageOverrun =>
      'Cartivo returned more pages than expected. Try again shortly.',
    CartivoProductsSyncFailure.incomplete =>
      'The product list changed while syncing. Try again.',
  };

  @override
  String toString() => 'CartivoProductsSyncException($failure)';
}

class FetchAllCartivoProducts {
  const FetchAllCartivoProducts(
    this._repository, {
    this.pageSize = 100,
    this.maxAttemptsPerPage = 3,
    this.retryBaseDelay = const Duration(milliseconds: 500),
  });

  final CartivoPosRepository _repository;
  final int pageSize;
  final int maxAttemptsPerPage;
  final Duration retryBaseDelay;

  Future<CartivoProductsSyncResult> call(
    String merchantId, {
    DateTime? updatedSince,
    CartivoSyncProgress? onProgress,
    bool verifyTotalOnDelta = false,
  }) async {
    final verify = updatedSince == null || verifyTotalOnDelta;

    // A second pass covers the catalog shifting mid-sync (offset paging can
    // skip rows when products are edited between requests).
    for (var pass = 0; pass < 2; pass++) {
      final result = await _readAllPages(
        merchantId,
        updatedSince: updatedSince,
        onProgress: onProgress,
      );
      if (!verify || result.products.length >= result.total) return result;
    }
    throw const CartivoProductsSyncException(
      CartivoProductsSyncFailure.incomplete,
    );
  }

  Future<CartivoProductsSyncResult> _readAllPages(
    String merchantId, {
    required DateTime? updatedSince,
    required CartivoSyncProgress? onProgress,
  }) async {
    final products = <int, CartivoProductDto>{};
    DateTime? watermark;
    var page = 1;
    var total = 0;

    while (true) {
      final response = await _fetchPageWithRetry(
        merchantId,
        page: page,
      );
      watermark ??= response.generatedAt;
      total = response.meta.total;
      for (final product in response.data) {
        products[product.productId] = product;
      }
      onProgress?.call(products.length, total);

      // An empty page ends the walk even if has_next lies, so a backend bug
      // can't spin this loop forever.
      if (!response.meta.hasNext || response.data.isEmpty) break;

      page += 1;
      final limit = response.meta.limit > 0 ? response.meta.limit : pageSize;
      final expectedPages = (total / limit).ceil();
      if (page > expectedPages + 1) {
        throw const CartivoProductsSyncException(
          CartivoProductsSyncFailure.pageOverrun,
        );
      }
    }

    return CartivoProductsSyncResult(
      products: products.values.toList(growable: false),
      watermark: watermark,
      total: total,
    );
  }

  Future<CartivoProductsPageDto> _fetchPageWithRetry(
    String merchantId, {
    required int page,
  }) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await _repository.getProductsPage(
          merchantId,
          page: page,
          limit: pageSize,
        );
      } catch (error) {
        final transient = switch (cartivoPosErrorFrom(error)) {
          CartivoPosError.network || CartivoPosError.serviceUnavailable => true,
          _ => false,
        };
        if (!transient || attempt >= maxAttemptsPerPage) rethrow;
        await Future<void>.delayed(retryBaseDelay * (1 << (attempt - 1)));
      }
    }
  }
}
