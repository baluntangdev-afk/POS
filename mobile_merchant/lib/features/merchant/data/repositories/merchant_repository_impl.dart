import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/storage/merchant_device_storage.dart';
import '../../domain/entities/device_registration.dart';
import '../../domain/entities/merchant.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../use_cases/device_identity.dart';
import '../merchant_api.dart';
import '../models/device_registration_dto.dart';
import '../models/webhook_token_dto.dart';

@LazySingleton(as: MerchantRepository)
class MerchantRepositoryImpl implements MerchantRepository {
  const MerchantRepositoryImpl(this._db, this._storage, this._merchantApi);

  final AppDatabase _db;
  final MerchantDeviceStorage _storage;
  final MerchantApi _merchantApi;

  @override
  Future<Merchant?> getMerchant() async {
    final row = await _db.merchantDao.getMerchant();
    if (row == null) return null;
    return Merchant(
      id: row.id,
      merchantId: row.merchantId,
      merchantName: row.merchantName,
    );
  }

  @override
  Future<void> createMerchant({
    required String merchantId,
    required String merchantName,
  }) => _db.merchantDao.insertMerchant(
    MerchantTableCompanion.insert(
      merchantId: merchantId,
      merchantName: merchantName,
    ),
  );

  @override
  Future<void> updateMerchant({
    required int id,
    required String merchantId,
    required String merchantName,
  }) async {
    final db = _db;
    await (db.update(db.merchantTable)..where((t) => t.id.equals(id))).write(
      MerchantTableCompanion(
        merchantId: Value(merchantId),
        merchantName: Value(merchantName),
      ),
    );
  }

  @override
  Future<DeviceRegistration> activateDevice(String merchantId) async {
    // Mint a webhook JWT scoped to this merchant, then enroll the device.
    final tokenDto = await _merchantApi.fetchToken(merchantId);
    final token = tokenDto.toDomain();
    await _storage.writeToken(token.token, token.exp, token.merchantId);
    return _registerAndPersist(
      token: token.token,
      merchantId: merchantId,
      merchantName: token.merchantName,
    );
  }

  @override
  Future<String> ensureWebhookToken(String merchantId) async {
    final token = await _storage.token;
    final tokenMerchantId = await _storage.tokenMerchantId;
    final exp = await _storage.tokenExp;
    final stillValid = token != null &&
        token.isNotEmpty &&
        tokenMerchantId == merchantId &&
        exp != null &&
        DateTime.fromMillisecondsSinceEpoch(exp * 1000)
            .isAfter(DateTime.now().add(const Duration(minutes: 1)));
    if (stillValid) return token;

    await refreshToken(merchantId);
    final refreshed = await _storage.token;
    if (refreshed == null || refreshed.isEmpty) {
      throw StateError('webhook token unavailable after refresh for $merchantId');
    }
    return refreshed;
  }

  @override
  Future<DeviceRegistration> syncDeviceRegistration() async {
    final merchantId = await _storage.registeredMerchantId;
    if (merchantId == null || merchantId.isEmpty) {
      throw StateError(
        'syncDeviceRegistration called with no registered merchant',
      );
    }
    // Re-mint if the stored token is for a different merchant — the device may
    // have been re-enrolled under a new merchant since it was last written.
    final token = await ensureWebhookToken(merchantId);
    final row = await _db.merchantDao.getMerchant();
    return _registerAndPersist(
      token: token,
      merchantId: merchantId,
      merchantName: row?.merchantName ?? '',
    );
  }

  /// Builds the device fingerprint, calls `POST /devices/register`, and
  /// persists the resulting credentials + status. `device_secret` is returned
  /// only on 202 — never overwrite the stored one with null.
  Future<DeviceRegistration> _registerAndPersist({
    required String token,
    required String merchantId,
    required String merchantName,
  }) async {
    final request = await DeviceIdentity(_storage).describe(name: merchantName);

    final registrationDto = await _merchantApi.registerDevice(
      request: request,
      token: token,
    );
    final registration = registrationDto.toDomain();

    await _storage.writeDeviceId(registration.deviceId);
    final secret = registration.deviceSecret;
    if (secret != null && secret.isNotEmpty) {
      await _storage.writeDeviceSecret(secret);
    }
    await _storage.writeRegisteredMerchantId(merchantId);
    await _storage.writeDeviceStatus(registration.status);

    final name = registration.merchantName ?? merchantName;
    if (name.isNotEmpty) await _syncMerchantName(name);

    return registration;
  }

  @override
  Future<void> refreshToken(String merchantId) async {
    final tokenDto = await _merchantApi.fetchToken(merchantId);
    final token = tokenDto.toDomain();
    await _storage.writeToken(token.token, token.exp, token.merchantId);
    await _syncMerchantName(token.merchantName);
  }

  Future<void> _syncMerchantName(String merchantName) async {
    final row = await _db.merchantDao.getMerchant();
    if (row == null || row.merchantName == merchantName) return;
    await (_db.update(_db.merchantTable)..where((t) => t.id.equals(row.id)))
        .write(MerchantTableCompanion(merchantName: Value(merchantName)));
  }

  @override
  Future<void> clearDeviceCredentials() => _storage.clearForMerchantChange();
}
