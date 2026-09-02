// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'device_registration_dto.dart';

class DeviceRegistrationDtoMapper
    extends ClassMapperBase<DeviceRegistrationDto> {
  DeviceRegistrationDtoMapper._();

  static DeviceRegistrationDtoMapper? _instance;
  static DeviceRegistrationDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeviceRegistrationDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DeviceRegistrationDto';

  static String _$deviceId(DeviceRegistrationDto v) => v.deviceId;
  static const Field<DeviceRegistrationDto, String> _f$deviceId = Field(
    'deviceId',
    _$deviceId,
    key: r'device_id',
  );
  static String _$status(DeviceRegistrationDto v) => v.status;
  static const Field<DeviceRegistrationDto, String> _f$status = Field(
    'status',
    _$status,
  );
  static String? _$deviceSecret(DeviceRegistrationDto v) => v.deviceSecret;
  static const Field<DeviceRegistrationDto, String> _f$deviceSecret = Field(
    'deviceSecret',
    _$deviceSecret,
    key: r'device_secret',
    opt: true,
  );
  static String? _$merchantId(DeviceRegistrationDto v) => v.merchantId;
  static const Field<DeviceRegistrationDto, String> _f$merchantId = Field(
    'merchantId',
    _$merchantId,
    key: r'merchant_id',
    opt: true,
  );
  static DateTime? _$requestedAt(DeviceRegistrationDto v) => v.requestedAt;
  static const Field<DeviceRegistrationDto, DateTime> _f$requestedAt = Field(
    'requestedAt',
    _$requestedAt,
    key: r'requested_at',
    opt: true,
  );
  static DateTime? _$reviewedAt(DeviceRegistrationDto v) => v.reviewedAt;
  static const Field<DeviceRegistrationDto, DateTime> _f$reviewedAt = Field(
    'reviewedAt',
    _$reviewedAt,
    key: r'reviewed_at',
    opt: true,
  );
  static String? _$reviewNote(DeviceRegistrationDto v) => v.reviewNote;
  static const Field<DeviceRegistrationDto, String> _f$reviewNote = Field(
    'reviewNote',
    _$reviewNote,
    key: r'review_note',
    opt: true,
  );

  @override
  final MappableFields<DeviceRegistrationDto> fields = const {
    #deviceId: _f$deviceId,
    #status: _f$status,
    #deviceSecret: _f$deviceSecret,
    #merchantId: _f$merchantId,
    #requestedAt: _f$requestedAt,
    #reviewedAt: _f$reviewedAt,
    #reviewNote: _f$reviewNote,
  };

  static DeviceRegistrationDto _instantiate(DecodingData data) {
    return DeviceRegistrationDto(
      deviceId: data.dec(_f$deviceId),
      status: data.dec(_f$status),
      deviceSecret: data.dec(_f$deviceSecret),
      merchantId: data.dec(_f$merchantId),
      requestedAt: data.dec(_f$requestedAt),
      reviewedAt: data.dec(_f$reviewedAt),
      reviewNote: data.dec(_f$reviewNote),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DeviceRegistrationDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeviceRegistrationDto>(map);
  }

  static DeviceRegistrationDto fromJson(String json) {
    return ensureInitialized().decodeJson<DeviceRegistrationDto>(json);
  }
}

mixin DeviceRegistrationDtoMappable {
  String toJson() {
    return DeviceRegistrationDtoMapper.ensureInitialized()
        .encodeJson<DeviceRegistrationDto>(this as DeviceRegistrationDto);
  }

  Map<String, dynamic> toMap() {
    return DeviceRegistrationDtoMapper.ensureInitialized()
        .encodeMap<DeviceRegistrationDto>(this as DeviceRegistrationDto);
  }

  DeviceRegistrationDtoCopyWith<
    DeviceRegistrationDto,
    DeviceRegistrationDto,
    DeviceRegistrationDto
  >
  get copyWith =>
      _DeviceRegistrationDtoCopyWithImpl<
        DeviceRegistrationDto,
        DeviceRegistrationDto
      >(this as DeviceRegistrationDto, $identity, $identity);
  @override
  String toString() {
    return DeviceRegistrationDtoMapper.ensureInitialized().stringifyValue(
      this as DeviceRegistrationDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return DeviceRegistrationDtoMapper.ensureInitialized().equalsValue(
      this as DeviceRegistrationDto,
      other,
    );
  }

  @override
  int get hashCode {
    return DeviceRegistrationDtoMapper.ensureInitialized().hashValue(
      this as DeviceRegistrationDto,
    );
  }
}

extension DeviceRegistrationDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeviceRegistrationDto, $Out> {
  DeviceRegistrationDtoCopyWith<$R, DeviceRegistrationDto, $Out>
  get $asDeviceRegistrationDto => $base.as(
    (v, t, t2) => _DeviceRegistrationDtoCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class DeviceRegistrationDtoCopyWith<
  $R,
  $In extends DeviceRegistrationDto,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? deviceId,
    String? status,
    String? deviceSecret,
    String? merchantId,
    DateTime? requestedAt,
    DateTime? reviewedAt,
    String? reviewNote,
  });
  DeviceRegistrationDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DeviceRegistrationDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeviceRegistrationDto, $Out>
    implements DeviceRegistrationDtoCopyWith<$R, DeviceRegistrationDto, $Out> {
  _DeviceRegistrationDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeviceRegistrationDto> $mapper =
      DeviceRegistrationDtoMapper.ensureInitialized();
  @override
  $R call({
    String? deviceId,
    String? status,
    Object? deviceSecret = $none,
    Object? merchantId = $none,
    Object? requestedAt = $none,
    Object? reviewedAt = $none,
    Object? reviewNote = $none,
  }) => $apply(
    FieldCopyWithData({
      if (deviceId != null) #deviceId: deviceId,
      if (status != null) #status: status,
      if (deviceSecret != $none) #deviceSecret: deviceSecret,
      if (merchantId != $none) #merchantId: merchantId,
      if (requestedAt != $none) #requestedAt: requestedAt,
      if (reviewedAt != $none) #reviewedAt: reviewedAt,
      if (reviewNote != $none) #reviewNote: reviewNote,
    }),
  );
  @override
  DeviceRegistrationDto $make(CopyWithData data) => DeviceRegistrationDto(
    deviceId: data.get(#deviceId, or: $value.deviceId),
    status: data.get(#status, or: $value.status),
    deviceSecret: data.get(#deviceSecret, or: $value.deviceSecret),
    merchantId: data.get(#merchantId, or: $value.merchantId),
    requestedAt: data.get(#requestedAt, or: $value.requestedAt),
    reviewedAt: data.get(#reviewedAt, or: $value.reviewedAt),
    reviewNote: data.get(#reviewNote, or: $value.reviewNote),
  );

  @override
  DeviceRegistrationDtoCopyWith<$R2, DeviceRegistrationDto, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DeviceRegistrationDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

