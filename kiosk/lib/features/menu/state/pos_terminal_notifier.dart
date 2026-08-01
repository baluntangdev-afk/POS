import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
import '../../../data/backend_api/sources/pos_terminals_api.dart';

final posTerminalProvider = FutureProvider.autoDispose<PosTerminalDto>((ref) {
  final api = ref.watch(posTerminalsApiProvider);
  return api.getMyTerminal();
});
