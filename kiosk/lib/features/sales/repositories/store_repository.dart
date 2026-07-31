import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../entities/store.dart';

abstract class StoreRepository {
  Future<Store> getCurrent();
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final api = ref.watch(posTerminalsApiProvider);
  return StoreRepositoryImpl(api);
});

class StoreRepositoryImpl implements StoreRepository {
  const StoreRepositoryImpl(this._posTerminalsApi);

  final PosTerminalsApi _posTerminalsApi;

  @override
  Future<Store> getCurrent() async {
    final terminal = await _posTerminalsApi.getMyTerminal();
    return _storeFromPosTerminal(terminal);
  }

  Store _storeFromPosTerminal(PosTerminalDto terminal) {
    return Store(
      legalName: terminal.legalName ?? '',
      tin: terminal.tinNumber,
      addressLine1: terminal.address,
      addressLine2: '',
    );
  }
}
