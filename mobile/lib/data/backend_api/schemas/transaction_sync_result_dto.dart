import 'package:dart_mappable/dart_mappable.dart';

part 'transaction_sync_result_dto.mapper.dart';

/// Response of `POST /merchant/transactions/sync`.
@MappableClass(caseStyle: CaseStyle.snakeCase)
class TransactionSyncResultDto with TransactionSyncResultDtoMappable {
  const TransactionSyncResultDto({
    required this.acceptedSaleIds,
    required this.acceptedRefundIds,
  });

  /// `local_id`s from the request the server durably stored. Anything sent
  /// but not listed here — rejected or lost to a whole-request failure —
  /// stays unsynced and is retried next tick.
  final List<int> acceptedSaleIds;

  /// Same semantics as [acceptedSaleIds].
  final List<int> acceptedRefundIds;

  static const fromJson = TransactionSyncResultDtoMapper.fromJson;
}
