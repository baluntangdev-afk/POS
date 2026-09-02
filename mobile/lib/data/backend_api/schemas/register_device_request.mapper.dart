// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'register_device_request.dart';

class RegisterDeviceRequestMapper
    extends ClassMapperBase<RegisterDeviceRequest> {
  RegisterDeviceRequestMapper._();

  static RegisterDeviceRequestMapper? _instance;
  static RegisterDeviceRequestMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RegisterDeviceRequestMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'RegisterDeviceRequest';

  static String _$platform(RegisterDeviceRequest v) => v.platform;
  static const Field<RegisterDeviceRequest, String> _f$platform = Field(
    'platform',
    _$platform,
  );
  static String _$installId(RegisterDeviceRequest v) => v.installId;
  static const Field<RegisterDeviceRequest, String> _f$installId = Field(
    'installId',
    _$installId,
    key: r'install_id',
  );
  static String _$name(RegisterDeviceRequest v) => v.name;
  static const Field<RegisterDeviceRequest, String> _f$name = Field(
    'name',
    _$name,
  );
  static String _$appVersion(RegisterDeviceRequest v) => v.appVersion;
  static const Field<RegisterDeviceRequest, String> _f$appVersion = Field(
    'appVersion',
    _$appVersion,
    key: r'app_version',
  );
  static String _$platformVersion(RegisterDeviceRequest v) => v.platformVersion;
  static const Field<RegisterDeviceRequest, String> _f$platformVersion = Field(
    'platformVersion',
    _$platformVersion,
    key: r'platform_version',
  );
  static String _$deviceModel(RegisterDeviceRequest v) => v.deviceModel;
  static const Field<RegisterDeviceRequest, String> _f$deviceModel = Field(
    'deviceModel',
    _$deviceModel,
    key: r'device_model',
  );
  static Map<String, dynamic> _$platformDetails(RegisterDeviceRequest v) =>
      v.platformDetails;
  static const Field<RegisterDeviceRequest, Map<String, dynamic>>
  _f$platformDetails = Field(
    'platformDetails',
    _$platformDetails,
    key: r'platform_details',
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<RegisterDeviceRequest> fields = const {
    #platform: _f$platform,
    #installId: _f$installId,
    #name: _f$name,
    #appVersion: _f$appVersion,
    #platformVersion: _f$platformVersion,
    #deviceModel: _f$deviceModel,
    #platformDetails: _f$platformDetails,
  };

  static RegisterDeviceRequest _instantiate(DecodingData data) {
    return RegisterDeviceRequest(
      platform: data.dec(_f$platform),
      installId: data.dec(_f$installId),
      name: data.dec(_f$name),
      appVersion: data.dec(_f$appVersion),
      platformVersion: data.dec(_f$platformVersion),
      deviceModel: data.dec(_f$deviceModel),
      platformDetails: data.dec(_f$platformDetails),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RegisterDeviceRequest fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RegisterDeviceRequest>(map);
  }

  static RegisterDeviceRequest fromJson(String json) {
    return ensureInitialized().decodeJson<RegisterDeviceRequest>(json);
  }
}

mixin RegisterDeviceRequestMappable {
  String toJson() {
    return RegisterDeviceRequestMapper.ensureInitialized()
        .encodeJson<RegisterDeviceRequest>(this as RegisterDeviceRequest);
  }

  Map<String, dynamic> toMap() {
    return RegisterDeviceRequestMapper.ensureInitialized()
        .encodeMap<RegisterDeviceRequest>(this as RegisterDeviceRequest);
  }

  RegisterDeviceRequestCopyWith<
    RegisterDeviceRequest,
    RegisterDeviceRequest,
    RegisterDeviceRequest
  >
  get copyWith =>
      _RegisterDeviceRequestCopyWithImpl<
        RegisterDeviceRequest,
        RegisterDeviceRequest
      >(this as RegisterDeviceRequest, $identity, $identity);
  @override
  String toString() {
    return RegisterDeviceRequestMapper.ensureInitialized().stringifyValue(
      this as RegisterDeviceRequest,
    );
  }

  @override
  bool operator ==(Object other) {
    return RegisterDeviceRequestMapper.ensureInitialized().equalsValue(
      this as RegisterDeviceRequest,
      other,
    );
  }

  @override
  int get hashCode {
    return RegisterDeviceRequestMapper.ensureInitialized().hashValue(
      this as RegisterDeviceRequest,
    );
  }
}

extension RegisterDeviceRequestValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RegisterDeviceRequest, $Out> {
  RegisterDeviceRequestCopyWith<$R, RegisterDeviceRequest, $Out>
  get $asRegisterDeviceRequest => $base.as(
    (v, t, t2) => _RegisterDeviceRequestCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class RegisterDeviceRequestCopyWith<
  $R,
  $In extends RegisterDeviceRequest,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get platformDetails;
  $R call({
    String? platform,
    String? installId,
    String? name,
    String? appVersion,
    String? platformVersion,
    String? deviceModel,
    Map<String, dynamic>? platformDetails,
  });
  RegisterDeviceRequestCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _RegisterDeviceRequestCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RegisterDeviceRequest, $Out>
    implements RegisterDeviceRequestCopyWith<$R, RegisterDeviceRequest, $Out> {
  _RegisterDeviceRequestCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RegisterDeviceRequest> $mapper =
      RegisterDeviceRequestMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get platformDetails => MapCopyWith(
    $value.platformDetails,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(platformDetails: v),
  );
  @override
  $R call({
    String? platform,
    String? installId,
    String? name,
    String? appVersion,
    String? platformVersion,
    String? deviceModel,
    Map<String, dynamic>? platformDetails,
  }) => $apply(
    FieldCopyWithData({
      if (platform != null) #platform: platform,
      if (installId != null) #installId: installId,
      if (name != null) #name: name,
      if (appVersion != null) #appVersion: appVersion,
      if (platformVersion != null) #platformVersion: platformVersion,
      if (deviceModel != null) #deviceModel: deviceModel,
      if (platformDetails != null) #platformDetails: platformDetails,
    }),
  );
  @override
  RegisterDeviceRequest $make(CopyWithData data) => RegisterDeviceRequest(
    platform: data.get(#platform, or: $value.platform),
    installId: data.get(#installId, or: $value.installId),
    name: data.get(#name, or: $value.name),
    appVersion: data.get(#appVersion, or: $value.appVersion),
    platformVersion: data.get(#platformVersion, or: $value.platformVersion),
    deviceModel: data.get(#deviceModel, or: $value.deviceModel),
    platformDetails: data.get(#platformDetails, or: $value.platformDetails),
  );

  @override
  RegisterDeviceRequestCopyWith<$R2, RegisterDeviceRequest, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _RegisterDeviceRequestCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

