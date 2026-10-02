// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'cartivo_products_page_dto.dart';

class CartivoProductsPageDtoMapper
    extends ClassMapperBase<CartivoProductsPageDto> {
  CartivoProductsPageDtoMapper._();

  static CartivoProductsPageDtoMapper? _instance;
  static CartivoProductsPageDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CartivoProductsPageDtoMapper._());
      CartivoProductDtoMapper.ensureInitialized();
      CartivoPageMetaDtoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CartivoProductsPageDto';

  static String _$merchantId(CartivoProductsPageDto v) => v.merchantId;
  static const Field<CartivoProductsPageDto, String> _f$merchantId = Field(
    'merchantId',
    _$merchantId,
    key: r'merchant_id',
  );
  static String _$currency(CartivoProductsPageDto v) => v.currency;
  static const Field<CartivoProductsPageDto, String> _f$currency = Field(
    'currency',
    _$currency,
  );
  static DateTime _$generatedAt(CartivoProductsPageDto v) => v.generatedAt;
  static const Field<CartivoProductsPageDto, DateTime> _f$generatedAt = Field(
    'generatedAt',
    _$generatedAt,
    key: r'generated_at',
  );
  static List<CartivoProductDto> _$data(CartivoProductsPageDto v) => v.data;
  static const Field<CartivoProductsPageDto, List<CartivoProductDto>> _f$data =
      Field('data', _$data);
  static CartivoPageMetaDto _$meta(CartivoProductsPageDto v) => v.meta;
  static const Field<CartivoProductsPageDto, CartivoPageMetaDto> _f$meta =
      Field('meta', _$meta);

  @override
  final MappableFields<CartivoProductsPageDto> fields = const {
    #merchantId: _f$merchantId,
    #currency: _f$currency,
    #generatedAt: _f$generatedAt,
    #data: _f$data,
    #meta: _f$meta,
  };

  static CartivoProductsPageDto _instantiate(DecodingData data) {
    return CartivoProductsPageDto(
      merchantId: data.dec(_f$merchantId),
      currency: data.dec(_f$currency),
      generatedAt: data.dec(_f$generatedAt),
      data: data.dec(_f$data),
      meta: data.dec(_f$meta),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CartivoProductsPageDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CartivoProductsPageDto>(map);
  }

  static CartivoProductsPageDto fromJson(String json) {
    return ensureInitialized().decodeJson<CartivoProductsPageDto>(json);
  }
}

mixin CartivoProductsPageDtoMappable {
  String toJson() {
    return CartivoProductsPageDtoMapper.ensureInitialized()
        .encodeJson<CartivoProductsPageDto>(this as CartivoProductsPageDto);
  }

  Map<String, dynamic> toMap() {
    return CartivoProductsPageDtoMapper.ensureInitialized()
        .encodeMap<CartivoProductsPageDto>(this as CartivoProductsPageDto);
  }

  CartivoProductsPageDtoCopyWith<
    CartivoProductsPageDto,
    CartivoProductsPageDto,
    CartivoProductsPageDto
  >
  get copyWith =>
      _CartivoProductsPageDtoCopyWithImpl<
        CartivoProductsPageDto,
        CartivoProductsPageDto
      >(this as CartivoProductsPageDto, $identity, $identity);
  @override
  String toString() {
    return CartivoProductsPageDtoMapper.ensureInitialized().stringifyValue(
      this as CartivoProductsPageDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return CartivoProductsPageDtoMapper.ensureInitialized().equalsValue(
      this as CartivoProductsPageDto,
      other,
    );
  }

  @override
  int get hashCode {
    return CartivoProductsPageDtoMapper.ensureInitialized().hashValue(
      this as CartivoProductsPageDto,
    );
  }
}

extension CartivoProductsPageDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CartivoProductsPageDto, $Out> {
  CartivoProductsPageDtoCopyWith<$R, CartivoProductsPageDto, $Out>
  get $asCartivoProductsPageDto => $base.as(
    (v, t, t2) => _CartivoProductsPageDtoCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CartivoProductsPageDtoCopyWith<
  $R,
  $In extends CartivoProductsPageDto,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    CartivoProductDto,
    CartivoProductDtoCopyWith<$R, CartivoProductDto, CartivoProductDto>
  >
  get data;
  CartivoPageMetaDtoCopyWith<$R, CartivoPageMetaDto, CartivoPageMetaDto>
  get meta;
  $R call({
    String? merchantId,
    String? currency,
    DateTime? generatedAt,
    List<CartivoProductDto>? data,
    CartivoPageMetaDto? meta,
  });
  CartivoProductsPageDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CartivoProductsPageDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CartivoProductsPageDto, $Out>
    implements
        CartivoProductsPageDtoCopyWith<$R, CartivoProductsPageDto, $Out> {
  _CartivoProductsPageDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CartivoProductsPageDto> $mapper =
      CartivoProductsPageDtoMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    CartivoProductDto,
    CartivoProductDtoCopyWith<$R, CartivoProductDto, CartivoProductDto>
  >
  get data => ListCopyWith(
    $value.data,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(data: v),
  );
  @override
  CartivoPageMetaDtoCopyWith<$R, CartivoPageMetaDto, CartivoPageMetaDto>
  get meta => $value.meta.copyWith.$chain((v) => call(meta: v));
  @override
  $R call({
    String? merchantId,
    String? currency,
    DateTime? generatedAt,
    List<CartivoProductDto>? data,
    CartivoPageMetaDto? meta,
  }) => $apply(
    FieldCopyWithData({
      if (merchantId != null) #merchantId: merchantId,
      if (currency != null) #currency: currency,
      if (generatedAt != null) #generatedAt: generatedAt,
      if (data != null) #data: data,
      if (meta != null) #meta: meta,
    }),
  );
  @override
  CartivoProductsPageDto $make(CopyWithData data) => CartivoProductsPageDto(
    merchantId: data.get(#merchantId, or: $value.merchantId),
    currency: data.get(#currency, or: $value.currency),
    generatedAt: data.get(#generatedAt, or: $value.generatedAt),
    data: data.get(#data, or: $value.data),
    meta: data.get(#meta, or: $value.meta),
  );

  @override
  CartivoProductsPageDtoCopyWith<$R2, CartivoProductsPageDto, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CartivoProductsPageDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CartivoProductDtoMapper extends ClassMapperBase<CartivoProductDto> {
  CartivoProductDtoMapper._();

  static CartivoProductDtoMapper? _instance;
  static CartivoProductDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CartivoProductDtoMapper._());
      CartivoVariantDtoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CartivoProductDto';

  static int _$productId(CartivoProductDto v) => v.productId;
  static const Field<CartivoProductDto, int> _f$productId = Field(
    'productId',
    _$productId,
    key: r'product_id',
  );
  static String _$name(CartivoProductDto v) => v.name;
  static const Field<CartivoProductDto, String> _f$name = Field('name', _$name);
  static DateTime _$updatedAt(CartivoProductDto v) => v.updatedAt;
  static const Field<CartivoProductDto, DateTime> _f$updatedAt = Field(
    'updatedAt',
    _$updatedAt,
    key: r'updated_at',
  );
  static List<CartivoVariantDto> _$variants(CartivoProductDto v) => v.variants;
  static const Field<CartivoProductDto, List<CartivoVariantDto>> _f$variants =
      Field('variants', _$variants);
  static String? _$category(CartivoProductDto v) => v.category;
  static const Field<CartivoProductDto, String> _f$category = Field(
    'category',
    _$category,
    opt: true,
  );
  static String? _$imageUrl(CartivoProductDto v) => v.imageUrl;
  static const Field<CartivoProductDto, String> _f$imageUrl = Field(
    'imageUrl',
    _$imageUrl,
    key: r'image_url',
    opt: true,
  );

  @override
  final MappableFields<CartivoProductDto> fields = const {
    #productId: _f$productId,
    #name: _f$name,
    #updatedAt: _f$updatedAt,
    #variants: _f$variants,
    #category: _f$category,
    #imageUrl: _f$imageUrl,
  };

  static CartivoProductDto _instantiate(DecodingData data) {
    return CartivoProductDto(
      productId: data.dec(_f$productId),
      name: data.dec(_f$name),
      updatedAt: data.dec(_f$updatedAt),
      variants: data.dec(_f$variants),
      category: data.dec(_f$category),
      imageUrl: data.dec(_f$imageUrl),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CartivoProductDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CartivoProductDto>(map);
  }

  static CartivoProductDto fromJson(String json) {
    return ensureInitialized().decodeJson<CartivoProductDto>(json);
  }
}

mixin CartivoProductDtoMappable {
  String toJson() {
    return CartivoProductDtoMapper.ensureInitialized()
        .encodeJson<CartivoProductDto>(this as CartivoProductDto);
  }

  Map<String, dynamic> toMap() {
    return CartivoProductDtoMapper.ensureInitialized()
        .encodeMap<CartivoProductDto>(this as CartivoProductDto);
  }

  CartivoProductDtoCopyWith<
    CartivoProductDto,
    CartivoProductDto,
    CartivoProductDto
  >
  get copyWith =>
      _CartivoProductDtoCopyWithImpl<CartivoProductDto, CartivoProductDto>(
        this as CartivoProductDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CartivoProductDtoMapper.ensureInitialized().stringifyValue(
      this as CartivoProductDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return CartivoProductDtoMapper.ensureInitialized().equalsValue(
      this as CartivoProductDto,
      other,
    );
  }

  @override
  int get hashCode {
    return CartivoProductDtoMapper.ensureInitialized().hashValue(
      this as CartivoProductDto,
    );
  }
}

extension CartivoProductDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CartivoProductDto, $Out> {
  CartivoProductDtoCopyWith<$R, CartivoProductDto, $Out>
  get $asCartivoProductDto => $base.as(
    (v, t, t2) => _CartivoProductDtoCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CartivoProductDtoCopyWith<
  $R,
  $In extends CartivoProductDto,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    CartivoVariantDto,
    CartivoVariantDtoCopyWith<$R, CartivoVariantDto, CartivoVariantDto>
  >
  get variants;
  $R call({
    int? productId,
    String? name,
    DateTime? updatedAt,
    List<CartivoVariantDto>? variants,
    String? category,
    String? imageUrl,
  });
  CartivoProductDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CartivoProductDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CartivoProductDto, $Out>
    implements CartivoProductDtoCopyWith<$R, CartivoProductDto, $Out> {
  _CartivoProductDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CartivoProductDto> $mapper =
      CartivoProductDtoMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    CartivoVariantDto,
    CartivoVariantDtoCopyWith<$R, CartivoVariantDto, CartivoVariantDto>
  >
  get variants => ListCopyWith(
    $value.variants,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(variants: v),
  );
  @override
  $R call({
    int? productId,
    String? name,
    DateTime? updatedAt,
    List<CartivoVariantDto>? variants,
    Object? category = $none,
    Object? imageUrl = $none,
  }) => $apply(
    FieldCopyWithData({
      if (productId != null) #productId: productId,
      if (name != null) #name: name,
      if (updatedAt != null) #updatedAt: updatedAt,
      if (variants != null) #variants: variants,
      if (category != $none) #category: category,
      if (imageUrl != $none) #imageUrl: imageUrl,
    }),
  );
  @override
  CartivoProductDto $make(CopyWithData data) => CartivoProductDto(
    productId: data.get(#productId, or: $value.productId),
    name: data.get(#name, or: $value.name),
    updatedAt: data.get(#updatedAt, or: $value.updatedAt),
    variants: data.get(#variants, or: $value.variants),
    category: data.get(#category, or: $value.category),
    imageUrl: data.get(#imageUrl, or: $value.imageUrl),
  );

  @override
  CartivoProductDtoCopyWith<$R2, CartivoProductDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CartivoProductDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CartivoVariantDtoMapper extends ClassMapperBase<CartivoVariantDto> {
  CartivoVariantDtoMapper._();

  static CartivoVariantDtoMapper? _instance;
  static CartivoVariantDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CartivoVariantDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CartivoVariantDto';

  static int _$variantId(CartivoVariantDto v) => v.variantId;
  static const Field<CartivoVariantDto, int> _f$variantId = Field(
    'variantId',
    _$variantId,
    key: r'variant_id',
  );
  static String _$sku(CartivoVariantDto v) => v.sku;
  static const Field<CartivoVariantDto, String> _f$sku = Field('sku', _$sku);
  static String _$variantName(CartivoVariantDto v) => v.variantName;
  static const Field<CartivoVariantDto, String> _f$variantName = Field(
    'variantName',
    _$variantName,
    key: r'variant_name',
  );
  static double _$price(CartivoVariantDto v) => v.price;
  static const Field<CartivoVariantDto, double> _f$price = Field(
    'price',
    _$price,
  );
  static int _$availableQuantity(CartivoVariantDto v) => v.availableQuantity;
  static const Field<CartivoVariantDto, int> _f$availableQuantity = Field(
    'availableQuantity',
    _$availableQuantity,
    key: r'available_quantity',
  );
  static bool _$isAvailable(CartivoVariantDto v) => v.isAvailable;
  static const Field<CartivoVariantDto, bool> _f$isAvailable = Field(
    'isAvailable',
    _$isAvailable,
    key: r'is_available',
  );
  static DateTime _$updatedAt(CartivoVariantDto v) => v.updatedAt;
  static const Field<CartivoVariantDto, DateTime> _f$updatedAt = Field(
    'updatedAt',
    _$updatedAt,
    key: r'updated_at',
  );

  @override
  final MappableFields<CartivoVariantDto> fields = const {
    #variantId: _f$variantId,
    #sku: _f$sku,
    #variantName: _f$variantName,
    #price: _f$price,
    #availableQuantity: _f$availableQuantity,
    #isAvailable: _f$isAvailable,
    #updatedAt: _f$updatedAt,
  };

  static CartivoVariantDto _instantiate(DecodingData data) {
    return CartivoVariantDto(
      variantId: data.dec(_f$variantId),
      sku: data.dec(_f$sku),
      variantName: data.dec(_f$variantName),
      price: data.dec(_f$price),
      availableQuantity: data.dec(_f$availableQuantity),
      isAvailable: data.dec(_f$isAvailable),
      updatedAt: data.dec(_f$updatedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CartivoVariantDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CartivoVariantDto>(map);
  }

  static CartivoVariantDto fromJson(String json) {
    return ensureInitialized().decodeJson<CartivoVariantDto>(json);
  }
}

mixin CartivoVariantDtoMappable {
  String toJson() {
    return CartivoVariantDtoMapper.ensureInitialized()
        .encodeJson<CartivoVariantDto>(this as CartivoVariantDto);
  }

  Map<String, dynamic> toMap() {
    return CartivoVariantDtoMapper.ensureInitialized()
        .encodeMap<CartivoVariantDto>(this as CartivoVariantDto);
  }

  CartivoVariantDtoCopyWith<
    CartivoVariantDto,
    CartivoVariantDto,
    CartivoVariantDto
  >
  get copyWith =>
      _CartivoVariantDtoCopyWithImpl<CartivoVariantDto, CartivoVariantDto>(
        this as CartivoVariantDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CartivoVariantDtoMapper.ensureInitialized().stringifyValue(
      this as CartivoVariantDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return CartivoVariantDtoMapper.ensureInitialized().equalsValue(
      this as CartivoVariantDto,
      other,
    );
  }

  @override
  int get hashCode {
    return CartivoVariantDtoMapper.ensureInitialized().hashValue(
      this as CartivoVariantDto,
    );
  }
}

extension CartivoVariantDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CartivoVariantDto, $Out> {
  CartivoVariantDtoCopyWith<$R, CartivoVariantDto, $Out>
  get $asCartivoVariantDto => $base.as(
    (v, t, t2) => _CartivoVariantDtoCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CartivoVariantDtoCopyWith<
  $R,
  $In extends CartivoVariantDto,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? variantId,
    String? sku,
    String? variantName,
    double? price,
    int? availableQuantity,
    bool? isAvailable,
    DateTime? updatedAt,
  });
  CartivoVariantDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CartivoVariantDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CartivoVariantDto, $Out>
    implements CartivoVariantDtoCopyWith<$R, CartivoVariantDto, $Out> {
  _CartivoVariantDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CartivoVariantDto> $mapper =
      CartivoVariantDtoMapper.ensureInitialized();
  @override
  $R call({
    int? variantId,
    String? sku,
    String? variantName,
    double? price,
    int? availableQuantity,
    bool? isAvailable,
    DateTime? updatedAt,
  }) => $apply(
    FieldCopyWithData({
      if (variantId != null) #variantId: variantId,
      if (sku != null) #sku: sku,
      if (variantName != null) #variantName: variantName,
      if (price != null) #price: price,
      if (availableQuantity != null) #availableQuantity: availableQuantity,
      if (isAvailable != null) #isAvailable: isAvailable,
      if (updatedAt != null) #updatedAt: updatedAt,
    }),
  );
  @override
  CartivoVariantDto $make(CopyWithData data) => CartivoVariantDto(
    variantId: data.get(#variantId, or: $value.variantId),
    sku: data.get(#sku, or: $value.sku),
    variantName: data.get(#variantName, or: $value.variantName),
    price: data.get(#price, or: $value.price),
    availableQuantity: data.get(
      #availableQuantity,
      or: $value.availableQuantity,
    ),
    isAvailable: data.get(#isAvailable, or: $value.isAvailable),
    updatedAt: data.get(#updatedAt, or: $value.updatedAt),
  );

  @override
  CartivoVariantDtoCopyWith<$R2, CartivoVariantDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CartivoVariantDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CartivoPageMetaDtoMapper extends ClassMapperBase<CartivoPageMetaDto> {
  CartivoPageMetaDtoMapper._();

  static CartivoPageMetaDtoMapper? _instance;
  static CartivoPageMetaDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CartivoPageMetaDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CartivoPageMetaDto';

  static int _$page(CartivoPageMetaDto v) => v.page;
  static const Field<CartivoPageMetaDto, int> _f$page = Field('page', _$page);
  static int _$limit(CartivoPageMetaDto v) => v.limit;
  static const Field<CartivoPageMetaDto, int> _f$limit = Field(
    'limit',
    _$limit,
  );
  static int _$total(CartivoPageMetaDto v) => v.total;
  static const Field<CartivoPageMetaDto, int> _f$total = Field(
    'total',
    _$total,
  );
  static bool _$hasNext(CartivoPageMetaDto v) => v.hasNext;
  static const Field<CartivoPageMetaDto, bool> _f$hasNext = Field(
    'hasNext',
    _$hasNext,
    key: r'has_next',
  );

  @override
  final MappableFields<CartivoPageMetaDto> fields = const {
    #page: _f$page,
    #limit: _f$limit,
    #total: _f$total,
    #hasNext: _f$hasNext,
  };

  static CartivoPageMetaDto _instantiate(DecodingData data) {
    return CartivoPageMetaDto(
      page: data.dec(_f$page),
      limit: data.dec(_f$limit),
      total: data.dec(_f$total),
      hasNext: data.dec(_f$hasNext),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CartivoPageMetaDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CartivoPageMetaDto>(map);
  }

  static CartivoPageMetaDto fromJson(String json) {
    return ensureInitialized().decodeJson<CartivoPageMetaDto>(json);
  }
}

mixin CartivoPageMetaDtoMappable {
  String toJson() {
    return CartivoPageMetaDtoMapper.ensureInitialized()
        .encodeJson<CartivoPageMetaDto>(this as CartivoPageMetaDto);
  }

  Map<String, dynamic> toMap() {
    return CartivoPageMetaDtoMapper.ensureInitialized()
        .encodeMap<CartivoPageMetaDto>(this as CartivoPageMetaDto);
  }

  CartivoPageMetaDtoCopyWith<
    CartivoPageMetaDto,
    CartivoPageMetaDto,
    CartivoPageMetaDto
  >
  get copyWith =>
      _CartivoPageMetaDtoCopyWithImpl<CartivoPageMetaDto, CartivoPageMetaDto>(
        this as CartivoPageMetaDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CartivoPageMetaDtoMapper.ensureInitialized().stringifyValue(
      this as CartivoPageMetaDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return CartivoPageMetaDtoMapper.ensureInitialized().equalsValue(
      this as CartivoPageMetaDto,
      other,
    );
  }

  @override
  int get hashCode {
    return CartivoPageMetaDtoMapper.ensureInitialized().hashValue(
      this as CartivoPageMetaDto,
    );
  }
}

extension CartivoPageMetaDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CartivoPageMetaDto, $Out> {
  CartivoPageMetaDtoCopyWith<$R, CartivoPageMetaDto, $Out>
  get $asCartivoPageMetaDto => $base.as(
    (v, t, t2) => _CartivoPageMetaDtoCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CartivoPageMetaDtoCopyWith<
  $R,
  $In extends CartivoPageMetaDto,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? page, int? limit, int? total, bool? hasNext});
  CartivoPageMetaDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CartivoPageMetaDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CartivoPageMetaDto, $Out>
    implements CartivoPageMetaDtoCopyWith<$R, CartivoPageMetaDto, $Out> {
  _CartivoPageMetaDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CartivoPageMetaDto> $mapper =
      CartivoPageMetaDtoMapper.ensureInitialized();
  @override
  $R call({int? page, int? limit, int? total, bool? hasNext}) => $apply(
    FieldCopyWithData({
      if (page != null) #page: page,
      if (limit != null) #limit: limit,
      if (total != null) #total: total,
      if (hasNext != null) #hasNext: hasNext,
    }),
  );
  @override
  CartivoPageMetaDto $make(CopyWithData data) => CartivoPageMetaDto(
    page: data.get(#page, or: $value.page),
    limit: data.get(#limit, or: $value.limit),
    total: data.get(#total, or: $value.total),
    hasNext: data.get(#hasNext, or: $value.hasNext),
  );

  @override
  CartivoPageMetaDtoCopyWith<$R2, CartivoPageMetaDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CartivoPageMetaDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

