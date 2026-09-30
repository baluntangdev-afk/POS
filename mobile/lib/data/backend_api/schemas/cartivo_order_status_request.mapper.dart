// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'cartivo_order_status_request.dart';

class CartivoOrderStatusRequestMapper
    extends ClassMapperBase<CartivoOrderStatusRequest> {
  CartivoOrderStatusRequestMapper._();

  static CartivoOrderStatusRequestMapper? _instance;
  static CartivoOrderStatusRequestMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = CartivoOrderStatusRequestMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'CartivoOrderStatusRequest';

  static String _$eventId(CartivoOrderStatusRequest v) => v.eventId;
  static const Field<CartivoOrderStatusRequest, String> _f$eventId = Field(
    'eventId',
    _$eventId,
    key: r'event_id',
  );
  static String _$status(CartivoOrderStatusRequest v) => v.status;
  static const Field<CartivoOrderStatusRequest, String> _f$status = Field(
    'status',
    _$status,
  );
  static DateTime _$occurredAt(CartivoOrderStatusRequest v) => v.occurredAt;
  static const Field<CartivoOrderStatusRequest, DateTime> _f$occurredAt = Field(
    'occurredAt',
    _$occurredAt,
    key: r'occurred_at',
  );

  @override
  final MappableFields<CartivoOrderStatusRequest> fields = const {
    #eventId: _f$eventId,
    #status: _f$status,
    #occurredAt: _f$occurredAt,
  };

  static CartivoOrderStatusRequest _instantiate(DecodingData data) {
    return CartivoOrderStatusRequest(
      eventId: data.dec(_f$eventId),
      status: data.dec(_f$status),
      occurredAt: data.dec(_f$occurredAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CartivoOrderStatusRequest fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CartivoOrderStatusRequest>(map);
  }

  static CartivoOrderStatusRequest fromJson(String json) {
    return ensureInitialized().decodeJson<CartivoOrderStatusRequest>(json);
  }
}

mixin CartivoOrderStatusRequestMappable {
  String toJson() {
    return CartivoOrderStatusRequestMapper.ensureInitialized()
        .encodeJson<CartivoOrderStatusRequest>(
          this as CartivoOrderStatusRequest,
        );
  }

  Map<String, dynamic> toMap() {
    return CartivoOrderStatusRequestMapper.ensureInitialized()
        .encodeMap<CartivoOrderStatusRequest>(
          this as CartivoOrderStatusRequest,
        );
  }

  CartivoOrderStatusRequestCopyWith<
    CartivoOrderStatusRequest,
    CartivoOrderStatusRequest,
    CartivoOrderStatusRequest
  >
  get copyWith =>
      _CartivoOrderStatusRequestCopyWithImpl<
        CartivoOrderStatusRequest,
        CartivoOrderStatusRequest
      >(this as CartivoOrderStatusRequest, $identity, $identity);
  @override
  String toString() {
    return CartivoOrderStatusRequestMapper.ensureInitialized().stringifyValue(
      this as CartivoOrderStatusRequest,
    );
  }

  @override
  bool operator ==(Object other) {
    return CartivoOrderStatusRequestMapper.ensureInitialized().equalsValue(
      this as CartivoOrderStatusRequest,
      other,
    );
  }

  @override
  int get hashCode {
    return CartivoOrderStatusRequestMapper.ensureInitialized().hashValue(
      this as CartivoOrderStatusRequest,
    );
  }
}

extension CartivoOrderStatusRequestValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CartivoOrderStatusRequest, $Out> {
  CartivoOrderStatusRequestCopyWith<$R, CartivoOrderStatusRequest, $Out>
  get $asCartivoOrderStatusRequest => $base.as(
    (v, t, t2) => _CartivoOrderStatusRequestCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CartivoOrderStatusRequestCopyWith<
  $R,
  $In extends CartivoOrderStatusRequest,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? eventId, String? status, DateTime? occurredAt});
  CartivoOrderStatusRequestCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CartivoOrderStatusRequestCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CartivoOrderStatusRequest, $Out>
    implements
        CartivoOrderStatusRequestCopyWith<$R, CartivoOrderStatusRequest, $Out> {
  _CartivoOrderStatusRequestCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CartivoOrderStatusRequest> $mapper =
      CartivoOrderStatusRequestMapper.ensureInitialized();
  @override
  $R call({String? eventId, String? status, DateTime? occurredAt}) => $apply(
    FieldCopyWithData({
      if (eventId != null) #eventId: eventId,
      if (status != null) #status: status,
      if (occurredAt != null) #occurredAt: occurredAt,
    }),
  );
  @override
  CartivoOrderStatusRequest $make(CopyWithData data) =>
      CartivoOrderStatusRequest(
        eventId: data.get(#eventId, or: $value.eventId),
        status: data.get(#status, or: $value.status),
        occurredAt: data.get(#occurredAt, or: $value.occurredAt),
      );

  @override
  CartivoOrderStatusRequestCopyWith<$R2, CartivoOrderStatusRequest, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CartivoOrderStatusRequestCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

