// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'device_token_dto.dart';

class DeviceTokenDtoMapper extends ClassMapperBase<DeviceTokenDto> {
  DeviceTokenDtoMapper._();

  static DeviceTokenDtoMapper? _instance;
  static DeviceTokenDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeviceTokenDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DeviceTokenDto';

  static String _$deviceId(DeviceTokenDto v) => v.deviceId;
  static const Field<DeviceTokenDto, String> _f$deviceId = Field(
    'deviceId',
    _$deviceId,
    key: r'device_id',
  );
  static String _$merchantId(DeviceTokenDto v) => v.merchantId;
  static const Field<DeviceTokenDto, String> _f$merchantId = Field(
    'merchantId',
    _$merchantId,
    key: r'merchant_id',
  );
  static String _$token(DeviceTokenDto v) => v.token;
  static const Field<DeviceTokenDto, String> _f$token = Field('token', _$token);
  static int _$exp(DeviceTokenDto v) => v.exp;
  static const Field<DeviceTokenDto, int> _f$exp = Field('exp', _$exp);

  @override
  final MappableFields<DeviceTokenDto> fields = const {
    #deviceId: _f$deviceId,
    #merchantId: _f$merchantId,
    #token: _f$token,
    #exp: _f$exp,
  };

  static DeviceTokenDto _instantiate(DecodingData data) {
    return DeviceTokenDto(
      deviceId: data.dec(_f$deviceId),
      merchantId: data.dec(_f$merchantId),
      token: data.dec(_f$token),
      exp: data.dec(_f$exp),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DeviceTokenDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeviceTokenDto>(map);
  }

  static DeviceTokenDto fromJson(String json) {
    return ensureInitialized().decodeJson<DeviceTokenDto>(json);
  }
}

mixin DeviceTokenDtoMappable {
  String toJson() {
    return DeviceTokenDtoMapper.ensureInitialized().encodeJson<DeviceTokenDto>(
      this as DeviceTokenDto,
    );
  }

  Map<String, dynamic> toMap() {
    return DeviceTokenDtoMapper.ensureInitialized().encodeMap<DeviceTokenDto>(
      this as DeviceTokenDto,
    );
  }

  DeviceTokenDtoCopyWith<DeviceTokenDto, DeviceTokenDto, DeviceTokenDto>
  get copyWith => _DeviceTokenDtoCopyWithImpl<DeviceTokenDto, DeviceTokenDto>(
    this as DeviceTokenDto,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return DeviceTokenDtoMapper.ensureInitialized().stringifyValue(
      this as DeviceTokenDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return DeviceTokenDtoMapper.ensureInitialized().equalsValue(
      this as DeviceTokenDto,
      other,
    );
  }

  @override
  int get hashCode {
    return DeviceTokenDtoMapper.ensureInitialized().hashValue(
      this as DeviceTokenDto,
    );
  }
}

extension DeviceTokenDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeviceTokenDto, $Out> {
  DeviceTokenDtoCopyWith<$R, DeviceTokenDto, $Out> get $asDeviceTokenDto =>
      $base.as((v, t, t2) => _DeviceTokenDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DeviceTokenDtoCopyWith<$R, $In extends DeviceTokenDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? deviceId, String? merchantId, String? token, int? exp});
  DeviceTokenDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DeviceTokenDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeviceTokenDto, $Out>
    implements DeviceTokenDtoCopyWith<$R, DeviceTokenDto, $Out> {
  _DeviceTokenDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeviceTokenDto> $mapper =
      DeviceTokenDtoMapper.ensureInitialized();
  @override
  $R call({String? deviceId, String? merchantId, String? token, int? exp}) =>
      $apply(
        FieldCopyWithData({
          if (deviceId != null) #deviceId: deviceId,
          if (merchantId != null) #merchantId: merchantId,
          if (token != null) #token: token,
          if (exp != null) #exp: exp,
        }),
      );
  @override
  DeviceTokenDto $make(CopyWithData data) => DeviceTokenDto(
    deviceId: data.get(#deviceId, or: $value.deviceId),
    merchantId: data.get(#merchantId, or: $value.merchantId),
    token: data.get(#token, or: $value.token),
    exp: data.get(#exp, or: $value.exp),
  );

  @override
  DeviceTokenDtoCopyWith<$R2, DeviceTokenDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DeviceTokenDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

