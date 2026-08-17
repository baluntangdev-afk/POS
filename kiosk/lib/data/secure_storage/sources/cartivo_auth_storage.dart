import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/environment/app_env.dart';
import '../../../exceptions/missing_record_exception.dart';
import '../schemas/cartivo_auth_doc.dart';
import '../secure_storage.dart';

final cartivoAuthStorageProvider = Provider<CartivoAuthStorage>((ref) {
  final env = ref.watch(appEnvProvider);
  final storage = CartivoAuthStorage(ref.watch(secureStorageProvider), '${env.secureStorageKey}_cartivo');
  ref.onDispose(storage.dispose);
  return storage;
});

class CartivoAuthStorage {
  CartivoAuthStorage(this._storage, this._key) {
    _notify();
  }

  final FlutterSecureStorage _storage;
  final String _key;

  final _controller = StreamController<CartivoAuthDoc?>.broadcast();

  Stream<CartivoAuthDoc?> get stored => _controller.stream;

  Future<void> _notify() async {
    _controller.add(await latestOrNull);
  }

  Future<CartivoAuthDoc> get latest async {
    final stored = await _storage.read(key: _key);
    if (stored == null) throw MissingRecordException('No saved credential.');
    return CartivoAuthDoc.fromJson(stored);
  }

  Future<CartivoAuthDoc?> get latestOrNull async {
    try {
      return await latest;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(CartivoAuthDoc document) async {
    await _storage.write(key: _key, value: document.toJson());
    await _notify();
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _notify();
  }

  void dispose() {
    _controller.close();
  }
}
