// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'device_token_doc.dart';

class DeviceTokenDocMapper extends ClassMapperBase<DeviceTokenDoc> {
  DeviceTokenDocMapper._();

  static DeviceTokenDocMapper? _instance;
  static DeviceTokenDocMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeviceTokenDocMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DeviceTokenDoc';

  static String _$merchantId(DeviceTokenDoc v) => v.merchantId;
  static const Field<DeviceTokenDoc, String> _f$merchantId = Field(
    'merchantId',
    _$merchantId,
  );
  static String _$token(DeviceTokenDoc v) => v.token;
  static const Field<DeviceTokenDoc, String> _f$token = Field('token', _$token);
  static DateTime _$expiresAt(DeviceTokenDoc v) => v.expiresAt;
  static const Field<DeviceTokenDoc, DateTime> _f$expiresAt = Field(
    'expiresAt',
    _$expiresAt,
  );

  @override
  final MappableFields<DeviceTokenDoc> fields = const {
    #merchantId: _f$merchantId,
    #token: _f$token,
    #expiresAt: _f$expiresAt,
  };

  static DeviceTokenDoc _instantiate(DecodingData data) {
    return DeviceTokenDoc(
      merchantId: data.dec(_f$merchantId),
      token: data.dec(_f$token),
      expiresAt: data.dec(_f$expiresAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DeviceTokenDoc fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeviceTokenDoc>(map);
  }

  static DeviceTokenDoc fromJson(String json) {
    return ensureInitialized().decodeJson<DeviceTokenDoc>(json);
  }
}

mixin DeviceTokenDocMappable {
  String toJson() {
    return DeviceTokenDocMapper.ensureInitialized().encodeJson<DeviceTokenDoc>(
      this as DeviceTokenDoc,
    );
  }

  Map<String, dynamic> toMap() {
    return DeviceTokenDocMapper.ensureInitialized().encodeMap<DeviceTokenDoc>(
      this as DeviceTokenDoc,
    );
  }

  DeviceTokenDocCopyWith<DeviceTokenDoc, DeviceTokenDoc, DeviceTokenDoc>
  get copyWith => _DeviceTokenDocCopyWithImpl<DeviceTokenDoc, DeviceTokenDoc>(
    this as DeviceTokenDoc,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return DeviceTokenDocMapper.ensureInitialized().stringifyValue(
      this as DeviceTokenDoc,
    );
  }

  @override
  bool operator ==(Object other) {
    return DeviceTokenDocMapper.ensureInitialized().equalsValue(
      this as DeviceTokenDoc,
      other,
    );
  }

  @override
  int get hashCode {
    return DeviceTokenDocMapper.ensureInitialized().hashValue(
      this as DeviceTokenDoc,
    );
  }
}

extension DeviceTokenDocValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeviceTokenDoc, $Out> {
  DeviceTokenDocCopyWith<$R, DeviceTokenDoc, $Out> get $asDeviceTokenDoc =>
      $base.as((v, t, t2) => _DeviceTokenDocCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DeviceTokenDocCopyWith<$R, $In extends DeviceTokenDoc, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? merchantId, String? token, DateTime? expiresAt});
  DeviceTokenDocCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DeviceTokenDocCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeviceTokenDoc, $Out>
    implements DeviceTokenDocCopyWith<$R, DeviceTokenDoc, $Out> {
  _DeviceTokenDocCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeviceTokenDoc> $mapper =
      DeviceTokenDocMapper.ensureInitialized();
  @override
  $R call({String? merchantId, String? token, DateTime? expiresAt}) => $apply(
    FieldCopyWithData({
      if (merchantId != null) #merchantId: merchantId,
      if (token != null) #token: token,
      if (expiresAt != null) #expiresAt: expiresAt,
    }),
  );
  @override
  DeviceTokenDoc $make(CopyWithData data) => DeviceTokenDoc(
    merchantId: data.get(#merchantId, or: $value.merchantId),
    token: data.get(#token, or: $value.token),
    expiresAt: data.get(#expiresAt, or: $value.expiresAt),
  );

  @override
  DeviceTokenDocCopyWith<$R2, DeviceTokenDoc, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DeviceTokenDocCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

