import '../entities/order_event.dart';

/// Whether a REST-sourced [incoming] order should overwrite [existing] (the
/// currently stored order state for the same `orderId`, or `null` if none is
/// stored yet). `null` always replaces; otherwise only when [incoming] isn't
/// older than [existing] — ties go to [incoming] since re-writing identical
/// data is harmless.
bool shouldReplaceStoredOrder({required OrderData? existing, required OrderData incoming}) {
  if (existing == null) return true;
  return !incoming.updatedAt.isBefore(existing.updatedAt);
}
