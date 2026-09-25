/// Response of the orders service's `POST /merchant/transactions/sync`.
///
/// Kiosk sales are keyed by UUID (sent as `local_id`), refunds by integer, so
/// ids are normalised on the way in rather than trusting one wire type.
class TransactionSyncResultDto {
  const TransactionSyncResultDto({
    required this.acceptedSaleIds,
    required this.acceptedRefundIds,
  });

  factory TransactionSyncResultDto.fromMap(Map<String, dynamic> json) {
    final sales = json['accepted_sale_ids'] as List<dynamic>? ?? const [];
    final refunds = json['accepted_refund_ids'] as List<dynamic>? ?? const [];
    return TransactionSyncResultDto(
      acceptedSaleIds: sales.map((id) => id.toString()).toList(),
      acceptedRefundIds: refunds
          .map((id) => id is int ? id : int.tryParse(id.toString()))
          .whereType<int>()
          .toList(),
    );
  }

  /// `local_id`s from the request the server durably stored. Anything sent
  /// but not listed here — rejected or lost to a whole-request failure —
  /// stays unsynced and is retried next run.
  final List<String> acceptedSaleIds;

  /// Same semantics as [acceptedSaleIds].
  final List<int> acceptedRefundIds;
}
