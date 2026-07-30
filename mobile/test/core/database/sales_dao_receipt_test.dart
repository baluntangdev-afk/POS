import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/entities/sale.dart';
import 'package:mobile/features/ordering/entities/sale_payment.dart';

void main() {
  late AppDatabase db;
  late int cashierId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final groupId = await db.into(db.productGroupsTable).insert(
          ProductGroupsTableCompanion.insert(name: 'Mains'),
        );
    await db.into(db.productsTable).insert(
          ProductsTableCompanion.insert(groupId: groupId, name: 'Burger'),
        );
  });

  tearDown(() => db.close());

  test('insertPendingSale persists items, modifiers and payment as status pending', () async {
    final sale = Sale(
      type: 'dine_in',
      createdAt: DateTime(2026, 7, 30),
      payment: const SalePayment(method: 'cash', amountPaid: 60, cashReceived: 100),
      items: [
        LineItem(
          id: 'a',
          productId: 1,
          productName: 'Burger',
          groupName: 'Mains',
          imageUrl: null,
          basePrice: 50,
          quantity: 1,
          modifiers: [
            SelectedModifierGroup(
              groupId: 1,
              groupName: 'Extras',
              selected: [
                const SelectedModifierOption(optionId: 1, name: 'Cheese', additionalPrice: 10),
              ],
            ),
          ],
        ),
      ],
    );

    final saleId = await db.salesDao.insertPendingSale(cashierId: cashierId, sale: sale);
    final row = await db.salesDao.getSaleById(saleId);

    expect(row!.status, 'pending');
    expect(row.soNumber, 'SO-${saleId.toString().padLeft(6, '0')}');
    final items = await db.salesDao.getItemsForSale(saleId);
    expect(items, hasLength(1));
    final payments = await db.salesDao.getPaymentsForSale(saleId);
    expect(payments.single.amount, 60);
  });

  test('completeSale flips status to completed and getReceiptById builds a full Receipt', () async {
    final sale = Sale(
      type: 'dine_in',
      createdAt: DateTime(2026, 7, 30),
      payment: const SalePayment(method: 'cash', amountPaid: 60, cashReceived: 60),
      items: [
        LineItem(
          id: 'a',
          productId: 1,
          productName: 'Burger',
          groupName: 'Mains',
          imageUrl: null,
          basePrice: 50,
          quantity: 1,
          modifiers: [
            SelectedModifierGroup(
              groupId: 1,
              groupName: 'Extras',
              selected: [
                const SelectedModifierOption(optionId: 1, name: 'Cheese', additionalPrice: 10),
              ],
            ),
          ],
        ),
      ],
    );
    final saleId = await db.salesDao.insertPendingSale(cashierId: cashierId, sale: sale);

    await db.salesDao.completeSale(saleId);
    final receipt = await db.salesDao.getReceiptById(saleId);

    expect(receipt, isNotNull);
    expect(receipt!.isVoided, isFalse);
    expect(receipt.items, hasLength(2)); // main item + 1 modifier add-on
    expect(receipt.items.where((i) => i.isMain).single.description, 'Burger');
    expect(receipt.items.where((i) => !i.isMain).single.id, isNegative);
    expect(receipt.docNumber, 'SO-${saleId.toString().padLeft(6, '0')}');
  });

  test('voidSale records reason and voidedAt', () async {
    final saleId = await db.salesDao.insertSale(SalesTableCompanion.insert(
      cashierId: cashierId,
      total: 50,
      status: 'completed',
      type: 'dine_in',
      createdAt: DateTime.now(),
    ));
    await db.salesDao.voidSale(saleId, reason: 'Customer changed mind');
    final receipt = await db.salesDao.getReceiptById(saleId);
    expect(receipt!.isVoided, isTrue);
    expect(receipt.voidReason, 'Customer changed mind');
  });

  test('insertRefundRecord assigns a refund_number and records items', () async {
    final saleId = await db.salesDao.insertSale(SalesTableCompanion.insert(
      cashierId: cashierId,
      total: 50,
      status: 'completed',
      type: 'dine_in',
      createdAt: DateTime.now(),
    ));
    final itemId = await db.salesDao.insertSaleItem(SaleItemsTableCompanion.insert(
      saleId: saleId, productId: 1, variantName: '', qty: 1, unitPrice: 50,
    ));

    final refundId = await db.salesDao.insertRefundRecord(
      saleId: saleId,
      reason: 'Wrong item',
      method: 'Cash Refund',
      total: 50,
      items: [(saleItemId: itemId, qty: 1, amount: 50.0)],
    );

    final refunds = await (db.select(db.refundsTable)
          ..where((t) => t.id.equals(refundId)))
        .get();
    expect(refunds.single.refundNumber, 'RF-${refundId.toString().padLeft(6, '0')}');
    expect(refunds.single.method, 'Cash Refund');
  });
}
