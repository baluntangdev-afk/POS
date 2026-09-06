import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/storage/merchant_device_storage.dart';
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
  Future<void> activateDevice(String merchantId) async {
    // 1. Mint a webhook JWT scoped to this merchant.
    final tokenDto = await _merchantApi.fetchToken(merchantId);
    final token = tokenDto.toDomain();
    await _storage.writeToken(token.token, token.exp);

    // 2. Build the device fingerprint.
    final request = await DeviceIdentity(
      _storage,
    ).describe(name: token.merchantName);

    // 3. Register (or replay) device enrollment.
    final registrationDto = await _merchantApi.registerDevice(
      request: request,
      token: token.token,
    );
    final registration = registrationDto.toDomain();

    // 4. Persist — device_secret is returned only on 202, never overwrite with null.
    await _storage.writeDeviceId(registration.deviceId);
    final secret = registration.deviceSecret;
    if (secret != null && secret.isNotEmpty) {
      await _storage.writeDeviceSecret(secret);
    }
    await _storage.writeRegisteredMerchantId(merchantId);
    await _syncMerchantName(token.merchantName);
  }

  @override
  Future<void> refreshToken(String merchantId) async {
    final tokenDto = await _merchantApi.fetchToken(merchantId);
    final token = tokenDto.toDomain();
    await _storage.writeToken(token.token, token.exp);
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
