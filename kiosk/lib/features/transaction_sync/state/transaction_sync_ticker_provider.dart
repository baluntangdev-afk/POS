import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/state/login_state_notifier.dart';

/// How often pending transactions are pushed while a cashier is signed in —
/// the kiosk's stand-in for the mobile app's 15-minute WorkManager task.
const kTransactionSyncInterval = Duration(minutes: 15);

/// Ticks every [kTransactionSyncInterval] while someone is logged in (our
/// backend's sync-state endpoints need a session), and not at all otherwise.
final transactionSyncTickerProvider = StreamProvider<int>((ref) {
  final loggedIn = ref.watch(loginStateProvider.select((auth) => auth.value != null));
  if (!loggedIn) return const Stream.empty();
  return Stream.periodic(kTransactionSyncInterval, (tick) => tick);
});
