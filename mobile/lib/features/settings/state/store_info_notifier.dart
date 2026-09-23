import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/feature_flags.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../live_orders/repositories/webhook_auth_repository.dart';
import '../../live_orders/state/merchant_device_notifier.dart';
import '../../live_orders/state/webhook_auth_status_provider.dart';
import '../../live_orders/use_cases/webhook_auth_error.dart';

class VerifiedMerchantLockedException implements Exception {
  const VerifiedMerchantLockedException();

  String get message =>
      'This device is linked to a verified merchant and can\'t be '
      'reassigned to a different store. Use Backup & Transfer instead.';

  @override
  String toString() => 'VerifiedMerchantLockedException()';
}

class StoreInfoNotifier extends AsyncNotifier<StoreInfoTableData?> {
  @override
  Future<StoreInfoTableData?> build() async {
    final db = ref.watch(databaseProvider);
    await db.storeInfoDao.ensureStoreInfoExists();
    return db.storeInfoDao.getStoreInfo();
  }

  // [bypassVerifiedLock] skips the [VerifiedMerchantLockedException] guard
  // once the caller has already confirmed the reassignment. Each sale is
  // stamped with its own store_id at creation time (see
  // `SalesDao.insertPendingSale`), so switching stores here doesn't touch
  // pre-existing local data or its future sync eligibility.
  Future<bool> save({
    required String storeId,
    required String storeName,
    required String address,
    required double taxRate,
    required String currency,
    required String receiptFooter,
    required String tin,
    required String terminalName,
    bool allowOfflineSetup = false,
    bool bypassVerifiedLock = false,
  }) async {
    final existing = state.value;
    final previousStoreId = existing?.storeId.trim() ?? '';
    final newStoreId = storeId.trim();
    final storeIdChanged = newStoreId != previousStoreId;

    if (storeIdChanged &&
        previousStoreId.isNotEmpty &&
        !bypassVerifiedLock &&
        await _isVerified(previousStoreId)) {
      throw const VerifiedMerchantLockedException();
    }

    var resolvedStoreName = storeName.trim();
    var resolvedTerminalName = terminalName;
    var verifiedOnline = true;

    // With device registration skipped there's no merchant to verify
    // against, so the store ID is saved locally as-is.
    if (storeIdChanged && newStoreId.isNotEmpty && !kSkipDeviceRegistration) {
      try {
        final merchantName = (await _refreshToken(newStoreId))?.trim() ?? '';
        if (merchantName.isNotEmpty) {
          resolvedStoreName = merchantName;
          resolvedTerminalName = merchantName;
        }
      } catch (error, stackTrace) {
        final isUnreachable =
            error is WebhookAuthException &&
            error.reason == WebhookAuthError.network;
        if (!allowOfflineSetup || !isUnreachable) {
          debugPrint(
            '[StoreInfo] store verification failed for $newStoreId: '
            '$error\n$stackTrace',
          );
          rethrow;
        }
        debugPrint(
          '[StoreInfo] backend unreachable, deferring verification for '
          '$newStoreId until setup can be completed later',
        );
        verifiedOnline = false;
      }
    }

    final db = ref.read(databaseProvider);
    await db.storeInfoDao.upsertStoreInfo(
      StoreInfoTableCompanion(
        id: existing != null ? Value(existing.id) : const Value.absent(),
        storeId: Value(newStoreId),
        storeName: Value(resolvedStoreName),
        address: Value(address),
        taxRate: Value(taxRate),
        currency: Value(currency),
        receiptFooter: Value(receiptFooter),
        tin: Value(tin),
        terminalName: Value(resolvedTerminalName),
      ),
    );

    state = await AsyncValue.guard(build);

    if (storeIdChanged && verifiedOnline) {
      unawaited(
        _registerDeviceForStore(
          storeId: newStoreId,
          deviceName:
              resolvedStoreName.isNotEmpty
                  ? resolvedStoreName
                  : storeName.trim(),
        ),
      );
    }
    return verifiedOnline;
  }

  /// Applies the `merchant_name` the backend resolves on `/auth/token` to the
  /// local store info, overwriting both the store name and the terminal name.
  /// No-op when [merchantName] is blank or already matches. Writes straight to
  /// the DB so it does not re-trigger device provisioning.
  Future<void> applyMerchantName(String merchantName) async {
    final name = merchantName.trim();
    if (name.isEmpty) return;

    final existing = state.value;
    if (existing != null &&
        existing.storeName == name &&
        existing.terminalName == name) {
      return;
    }

    final db = ref.read(databaseProvider);
    await db.storeInfoDao.upsertStoreInfo(
      StoreInfoTableCompanion(
        id: existing != null ? Value(existing.id) : const Value.absent(),
        storeName: Value(name),
        terminalName: Value(name),
      ),
    );
    state = await AsyncValue.guard(build);
  }

  /// Registers this device against [storeId] with the backend. Only called
  /// once `/auth/token` has already confirmed the store/merchant exists (see
  /// [save]), so a rejected ID never reaches this step.
  Future<void> _registerDeviceForStore({
    required String storeId,
    required String deviceName,
  }) async {
    if (kSkipDeviceRegistration || storeId.isEmpty) return;

    try {
      await ref
          .read(merchantDeviceNotifierProvider.notifier)
          .registerIfNeeded(name: deviceName);

      final registeredName =
          ref
              .read(merchantDeviceNotifierProvider)
              .value
              ?.registration
              ?.merchantName
              ?.trim() ??
          '';
      if (registeredName.isNotEmpty && registeredName != deviceName) {
        await applyMerchantName(registeredName);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      debugPrint(
        '[StoreInfo] device registration failed for $storeId: '
        '$error\n$stackTrace',
      );
    }
  }

  /// Mirrors `merchantVerificationProvider` but is called directly against
  /// [webhookAuthRepositoryProvider] instead of reading that provider —
  /// which watches `storeInfoProvider.future` and would create a circular
  /// dependency if read from inside this notifier.
  Future<bool> _isVerified(String storeId) async {
    try {
      await ref.read(webhookAuthRepositoryProvider).ensureToken(storeId);
      return true;
    } on WebhookAuthException {
      return false;
    }
  }

  Future<String?> _refreshToken(String storeId) async {
    final status = ref.read(webhookAuthStatusProvider.notifier);
    try {
      final merchantName = await ref
          .read(webhookAuthRepositoryProvider)
          .refreshToken(storeId);
      status.clear();
      return merchantName;
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
