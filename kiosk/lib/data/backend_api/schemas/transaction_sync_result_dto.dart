/// Response of the orders service's `POST /merchant/transactions/sync`.
///
/// Both id lists are the integer `local_id`s we sent: a sale's `syncId` and a
/// refund's id. Ids are parsed leniently rather than trusting one wire type.
class TransactionSyncResultDto {
  const TransactionSyncResultDto({required this.acceptedSaleIds, required this.acceptedRefundIds});

  factory TransactionSyncResultDto.fromMap(Map<String, dynamic> json) {
    final sales = json['accepted_sale_ids'] as List<dynamic>? ?? const [];
    final refunds = json['accepted_refund_ids'] as List<dynamic>? ?? const [];
    return TransactionSyncResultDto(
      acceptedSaleIds: _ints(sales),
      acceptedRefundIds: _ints(refunds),
    );
  }

  static List<int> _ints(List<dynamic> ids) =>
      ids.map((id) => id is int ? id : int.tryParse(id.toString())).whereType<int>().toList();

  /// `local_id`s from the request the server durably stored. Anything sent
  /// but not listed here — rejected or lost to a whole-request failure —
  /// stays unsynced and is retried next run.
  final List<int> acceptedSaleIds;

  /// Same semantics as [acceptedSaleIds].
  final List<int> acceptedRefundIds;
}
