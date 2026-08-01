import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/receipt.dart';
import '../entities/sale.dart';
import '../repositories/receipt_repository.dart';
import '../repositories/sale_repository.dart';

final finalizeSaleProvider = Provider<FinalizeSale>((ref) {
  return FinalizeSale(ref.watch(saleRepositoryProvider), ref.watch(receiptRepositoryProvider));
});

class FinalizeSale {
  const FinalizeSale(this._saleRepository, this._receiptRepository);

  final SaleRepository _saleRepository;
  final ReceiptRepository _receiptRepository;

  Future<Receipt> call(Sale sale, {required int cashierId}) async {
    if (sale.payment == null) throw StateError('Payment is required to finalize sale.');
    final savedSale = await _saleRepository.save(sale, cashierId: cashierId);
    return _receiptRepository.save(savedSale.id!);
  }
}
