import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_order_status_request.mapper.dart';

/// Request body of the webhook-receiver's `POST /pos/orders/{order_number}/status`.
@MappableClass(caseStyle: CaseStyle.snakeCase)
class CartivoOrderStatusRequest with CartivoOrderStatusRequestMappable {
  const CartivoOrderStatusRequest({
    required this.eventId,
    required this.status,
    required this.occurredAt,
    this.reason,
  });

  /// Unique per call, `evt_<uuid>`.
  final String eventId;

  /// A Cartivo status name (`confirmed`, `processing`, ...). The route does
  /// no translation or validation.
  final String status;

  final DateTime occurredAt;

  /// Required by Cartivo when [status] is `cancelled`; omitted otherwise.
  final String? reason;

  static const fromJson = CartivoOrderStatusRequestMapper.fromJson;
}
