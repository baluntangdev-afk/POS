import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/print_service.dart';
import '../entities/receipt.dart';
import '../repositories/receipt_repository.dart';
import '../use_cases/void_sale.dart';

final storeInfoProvider = FutureProvider.autoDispose<StoreInfoTableData?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.storeInfoDao.getStoreInfo();
});

final receiptProvider =
    AsyncNotifierProvider.autoDispose.family<ReceiptNotifier, Receipt, int>(
  ReceiptNotifier.new,
  name: 'receiptProvider',
);

class ReceiptNotifier extends AsyncNotifier<Receipt> {
  ReceiptNotifier(this.saleId);

  final int saleId;

  @override
  Future<Receipt> build() async {
    final repository = ref.watch(receiptRepositoryProvider);
    final receipt = await repository.getById(saleId);
    if (receipt == null) throw StateError('Receipt $saleId not found.');
    return receipt;
  }

  Future<bool> print() async {
    if (!state.hasValue) return false;
    final db = ref.read(databaseProvider);
    final storeInfo = await db.storeInfoDao.getStoreInfo();
    return PrintService.printReceipt(
      state.requireValue,
      currency: (storeInfo?.currency.isNotEmpty ?? false) ? storeInfo!.currency : 'PHP',
      storeFooter:
          (storeInfo?.receiptFooter.isNotEmpty ?? false) ? storeInfo!.receiptFooter : 'Thank you!',
      storeName: storeInfo?.storeName,
      storeAddress: storeInfo?.address,
      storeTin: storeInfo?.tin,
      terminalName: storeInfo?.terminalName,
    );
  }

  Future<void> void_(String reason) async {
    final voidSale = ref.read(voidSaleProvider);
    await voidSale(saleId: saleId, reason: reason);
    ref.invalidateSelf();
    await future;
  }
}
