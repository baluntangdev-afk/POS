import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../live_orders/repositories/webhook_auth_repository.dart';
import '../../live_orders/state/merchant_device_notifier.dart';
import '../../live_orders/state/webhook_auth_status_provider.dart';
import '../../live_orders/use_cases/webhook_auth_error.dart';

class StoreInfoNotifier extends AsyncNotifier<StoreInfoTableData?> {
  @override
  Future<StoreInfoTableData?> build() async {
    final db = ref.watch(databaseProvider);
    await db.storeInfoDao.ensureStoreInfoExists();
    return db.storeInfoDao.getStoreInfo();
  }

  Future<void> save({
    required String storeId,
    required String storeName,
    required String address,
    required double taxRate,
    required String currency,
    required String receiptFooter,
    required String tin,
    required String terminalName,
  }) async {
    final db = ref.read(databaseProvider);
    final existing = state.value;
    final previousStoreId = existing?.storeId.trim() ?? '';
    await db.storeInfoDao.upsertStoreInfo(
      StoreInfoTableCompanion(
        id: existing != null ? Value(existing.id) : const Value.absent(),
        storeId: Value(storeId),
        storeName: Value(storeName),
        address: Value(address),
        taxRate: Value(taxRate),
        currency: Value(currency),
        receiptFooter: Value(receiptFooter),
        tin: Value(tin),
        terminalName: Value(terminalName),
      ),
    );
    // Reload without dropping the current value, so the screen keeps showing
    // the form (with its own inline saving indicator) instead of flashing a
    // full-screen spinner during this quick local re-read.
    state = await AsyncValue.guard(build);

    final deviceName =
        terminalName.trim().isNotEmpty ? terminalName.trim() : storeName.trim();
    final newStoreId = storeId.trim();
    final storeIdChanged = newStoreId != previousStoreId;

    unawaited(
      _provisionForStore(
        storeId: newStoreId,
        deviceName: deviceName,
        storeIdChanged: storeIdChanged,
      ),
    );
  }

  Future<void> _provisionForStore({
    required String storeId,
    required String deviceName,
    required bool storeIdChanged,
  }) async {
    if (storeId.isEmpty) return;

    try {
      if (storeIdChanged) {
        await _refreshToken(storeId);
        await ref
            .read(merchantDeviceNotifierProvider.notifier)
            .registerIfNeeded(name: deviceName);
      }
      return;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      debugPrint(
        '[StoreInfo] store provisioning failed for $storeId: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _refreshToken(String storeId) async {
    final status = ref.read(webhookAuthStatusProvider.notifier);
    try {
      await ref.read(webhookAuthRepositoryProvider).refreshToken(storeId);
      status.clear();
    } on WebhookAuthException catch (error) {
      status.reportFailure(error.reason, error.message);
      rethrow;
    }
  }
}

final storeInfoProvider =
    AsyncNotifierProvider<StoreInfoNotifier, StoreInfoTableData?>(
      StoreInfoNotifier.new,
    );

class PaymentMethodsNotifier
    extends AsyncNotifier<List<PaymentMethodsTableData>> {
  @override
  Future<List<PaymentMethodsTableData>> build() {
    final db = ref.watch(databaseProvider);
    return db.storeInfoDao.getAllPaymentMethods();
  }

  Future<void> create({
    required String label,
    String? accountName,
    String? accountNumber,
  }) async {
    final db = ref.read(databaseProvider);
    await db.storeInfoDao.insertPaymentMethod(
      PaymentMethodsTableCompanion.insert(
        label: label,
        accountName: Value(accountName),
        accountNumber: Value(accountNumber),
      ),
    );
    await refresh();
  }

  Future<void> edit({
    required int id,
    required String label,
    String? accountName,
    String? accountNumber,
  }) async {
    final db = ref.read(databaseProvider);
    await db.storeInfoDao.updatePaymentMethod(
      id,
      PaymentMethodsTableCompanion(
        label: Value(label),
        accountName: Value(accountName),
        accountNumber: Value(accountNumber),
      ),
    );
    await refresh();
  }

  Future<void> delete(int id) async {
    final db = ref.read(databaseProvider);
    await db.storeInfoDao.deletePaymentMethod(id);
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

final paymentMethodsProvider = AsyncNotifierProvider<
  PaymentMethodsNotifier,
  List<PaymentMethodsTableData>
>(PaymentMethodsNotifier.new);
