// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTableTable extends UsersTable
    with TableInfo<$UsersTableTable, UsersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPinChangedMeta = const VerificationMeta(
    'isPinChanged',
  );
  @override
  late final GeneratedColumn<bool> isPinChanged = GeneratedColumn<bool>(
    'is_pin_changed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pin_changed" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    role,
    pinHash,
    isActive,
    employeeId,
    phone,
    avatarUrl,
    isPinChanged,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    } else if (isInserting) {
      context.missing(_pinHashMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('is_pin_changed')) {
      context.handle(
        _isPinChangedMeta,
        isPinChanged.isAcceptableOrUnknown(
          data['is_pin_changed']!,
          _isPinChangedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsersTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      role:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}role'],
          )!,
      pinHash:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}pin_hash'],
          )!,
      isActive:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_active'],
          )!,
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      isPinChanged:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_pin_changed'],
          )!,
    );
  }

  @override
  $UsersTableTable createAlias(String alias) {
    return $UsersTableTable(attachedDatabase, alias);
  }
}

class UsersTableData extends DataClass implements Insertable<UsersTableData> {
  final int id;
  final String name;
  final String role;
  final String pinHash;
  final bool isActive;
  final String? employeeId;
  final String? phone;
  final String? avatarUrl;
  final bool isPinChanged;
  const UsersTableData({
    required this.id,
    required this.name,
    required this.role,
    required this.pinHash,
    required this.isActive,
    this.employeeId,
    this.phone,
    this.avatarUrl,
    required this.isPinChanged,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['pin_hash'] = Variable<String>(pinHash);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<String>(employeeId);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    map['is_pin_changed'] = Variable<bool>(isPinChanged);
    return map;
  }

  UsersTableCompanion toCompanion(bool nullToAbsent) {
    return UsersTableCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      pinHash: Value(pinHash),
      isActive: Value(isActive),
      employeeId:
          employeeId == null && nullToAbsent
              ? const Value.absent()
              : Value(employeeId),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      avatarUrl:
          avatarUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(avatarUrl),
      isPinChanged: Value(isPinChanged),
    );
  }

  factory UsersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsersTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      pinHash: serializer.fromJson<String>(json['pinHash']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      employeeId: serializer.fromJson<String?>(json['employeeId']),
      phone: serializer.fromJson<String?>(json['phone']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      isPinChanged: serializer.fromJson<bool>(json['isPinChanged']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'pinHash': serializer.toJson<String>(pinHash),
      'isActive': serializer.toJson<bool>(isActive),
      'employeeId': serializer.toJson<String?>(employeeId),
      'phone': serializer.toJson<String?>(phone),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'isPinChanged': serializer.toJson<bool>(isPinChanged),
    };
  }

  UsersTableData copyWith({
    int? id,
    String? name,
    String? role,
    String? pinHash,
    bool? isActive,
    Value<String?> employeeId = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    bool? isPinChanged,
  }) => UsersTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    pinHash: pinHash ?? this.pinHash,
    isActive: isActive ?? this.isActive,
    employeeId: employeeId.present ? employeeId.value : this.employeeId,
    phone: phone.present ? phone.value : this.phone,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    isPinChanged: isPinChanged ?? this.isPinChanged,
  );
  UsersTableData copyWithCompanion(UsersTableCompanion data) {
    return UsersTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      phone: data.phone.present ? data.phone.value : this.phone,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      isPinChanged:
          data.isPinChanged.present
              ? data.isPinChanged.value
              : this.isPinChanged,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('pinHash: $pinHash, ')
          ..write('isActive: $isActive, ')
          ..write('employeeId: $employeeId, ')
          ..write('phone: $phone, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isPinChanged: $isPinChanged')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    role,
    pinHash,
    isActive,
    employeeId,
    phone,
    avatarUrl,
    isPinChanged,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsersTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.pinHash == this.pinHash &&
          other.isActive == this.isActive &&
          other.employeeId == this.employeeId &&
          other.phone == this.phone &&
          other.avatarUrl == this.avatarUrl &&
          other.isPinChanged == this.isPinChanged);
}

class UsersTableCompanion extends UpdateCompanion<UsersTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> role;
  final Value<String> pinHash;
  final Value<bool> isActive;
  final Value<String?> employeeId;
  final Value<String?> phone;
  final Value<String?> avatarUrl;
  final Value<bool> isPinChanged;
  const UsersTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.isActive = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.phone = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isPinChanged = const Value.absent(),
  });
  UsersTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String role,
    required String pinHash,
    this.isActive = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.phone = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isPinChanged = const Value.absent(),
  }) : name = Value(name),
       role = Value(role),
       pinHash = Value(pinHash);
  static Insertable<UsersTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? pinHash,
    Expression<bool>? isActive,
    Expression<String>? employeeId,
    Expression<String>? phone,
    Expression<String>? avatarUrl,
    Expression<bool>? isPinChanged,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (pinHash != null) 'pin_hash': pinHash,
      if (isActive != null) 'is_active': isActive,
      if (employeeId != null) 'employee_id': employeeId,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (isPinChanged != null) 'is_pin_changed': isPinChanged,
    });
  }

  UsersTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? role,
    Value<String>? pinHash,
    Value<bool>? isActive,
    Value<String?>? employeeId,
    Value<String?>? phone,
    Value<String?>? avatarUrl,
    Value<bool>? isPinChanged,
  }) {
    return UsersTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      pinHash: pinHash ?? this.pinHash,
      isActive: isActive ?? this.isActive,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPinChanged: isPinChanged ?? this.isPinChanged,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (isPinChanged.present) {
      map['is_pin_changed'] = Variable<bool>(isPinChanged.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('pinHash: $pinHash, ')
          ..write('isActive: $isActive, ')
          ..write('employeeId: $employeeId, ')
          ..write('phone: $phone, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isPinChanged: $isPinChanged')
          ..write(')'))
        .toString();
  }
}

class $ProductGroupsTableTable extends ProductGroupsTable
    with TableInfo<$ProductGroupsTableTable, ProductGroupsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductGroupsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductGroupsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductGroupsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductGroupsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
      isActive:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_active'],
          )!,
    );
  }

  @override
  $ProductGroupsTableTable createAlias(String alias) {
    return $ProductGroupsTableTable(attachedDatabase, alias);
  }
}

class ProductGroupsTableData extends DataClass
    implements Insertable<ProductGroupsTableData> {
  final int id;
  final String name;
  final int sortOrder;
  final bool isActive;
  const ProductGroupsTableData({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ProductGroupsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductGroupsTableCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
    );
  }

  factory ProductGroupsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductGroupsTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  ProductGroupsTableData copyWith({
    int? id,
    String? name,
    int? sortOrder,
    bool? isActive,
  }) => ProductGroupsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
  );
  ProductGroupsTableData copyWithCompanion(ProductGroupsTableCompanion data) {
    return ProductGroupsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductGroupsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductGroupsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive);
}

class ProductGroupsTableCompanion
    extends UpdateCompanion<ProductGroupsTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  const ProductGroupsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  ProductGroupsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : name = Value(name);
  static Insertable<ProductGroupsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
    });
  }

  ProductGroupsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<bool>? isActive,
  }) {
    return ProductGroupsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductGroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, ProductsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES product_groups (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    name,
    isAvailable,
    imageUrl,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      groupId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}group_id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      isAvailable:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_available'],
          )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
    );
  }

  @override
  $ProductsTableTable createAlias(String alias) {
    return $ProductsTableTable(attachedDatabase, alias);
  }
}

class ProductsTableData extends DataClass
    implements Insertable<ProductsTableData> {
  final int id;
  final int groupId;
  final String name;
  final bool isAvailable;
  final String? imageUrl;
  final int sortOrder;
  const ProductsTableData({
    required this.id,
    required this.groupId,
    required this.name,
    required this.isAvailable,
    this.imageUrl,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<int>(groupId);
    map['name'] = Variable<String>(name);
    map['is_available'] = Variable<bool>(isAvailable);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      isAvailable: Value(isAvailable),
      imageUrl:
          imageUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(imageUrl),
      sortOrder: Value(sortOrder),
    );
  }

  factory ProductsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsTableData(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<int>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<int>(groupId),
      'name': serializer.toJson<String>(name),
      'isAvailable': serializer.toJson<bool>(isAvailable),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ProductsTableData copyWith({
    int? id,
    int? groupId,
    String? name,
    bool? isAvailable,
    Value<String?> imageUrl = const Value.absent(),
    int? sortOrder,
  }) => ProductsTableData(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    isAvailable: isAvailable ?? this.isAvailable,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ProductsTableData copyWithCompanion(ProductsTableCompanion data) {
    return ProductsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      isAvailable:
          data.isAvailable.present ? data.isAvailable.value : this.isAvailable,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, groupId, name, isAvailable, imageUrl, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.isAvailable == this.isAvailable &&
          other.imageUrl == this.imageUrl &&
          other.sortOrder == this.sortOrder);
}

class ProductsTableCompanion extends UpdateCompanion<ProductsTableData> {
  final Value<int> id;
  final Value<int> groupId;
  final Value<String> name;
  final Value<bool> isAvailable;
  final Value<String?> imageUrl;
  final Value<int> sortOrder;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    this.id = const Value.absent(),
    required int groupId,
    required String name,
    this.isAvailable = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : groupId = Value(groupId),
       name = Value(name);
  static Insertable<ProductsTableData> custom({
    Expression<int>? id,
    Expression<int>? groupId,
    Expression<String>? name,
    Expression<bool>? isAvailable,
    Expression<String>? imageUrl,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (isAvailable != null) 'is_available': isAvailable,
      if (imageUrl != null) 'image_url': imageUrl,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ProductsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? groupId,
    Value<String>? name,
    Value<bool>? isAvailable,
    Value<String?>? imageUrl,
    Value<int>? sortOrder,
  }) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ProductVariantsTableTable extends ProductVariantsTable
    with TableInfo<$ProductVariantsTableTable, ProductVariantsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductVariantsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    name,
    price,
    isDefault,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductVariantsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductVariantsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductVariantsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      productId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}product_id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      price:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}price'],
          )!,
      isDefault:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_default'],
          )!,
      isActive:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_active'],
          )!,
    );
  }

  @override
  $ProductVariantsTableTable createAlias(String alias) {
    return $ProductVariantsTableTable(attachedDatabase, alias);
  }
}

class ProductVariantsTableData extends DataClass
    implements Insertable<ProductVariantsTableData> {
  final int id;
  final int productId;
  final String name;
  final double price;
  final bool isDefault;
  final bool isActive;
  const ProductVariantsTableData({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.isDefault,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<double>(price);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ProductVariantsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductVariantsTableCompanion(
      id: Value(id),
      productId: Value(productId),
      name: Value(name),
      price: Value(price),
      isDefault: Value(isDefault),
      isActive: Value(isActive),
    );
  }

  factory ProductVariantsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductVariantsTableData(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<double>(json['price']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<double>(price),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  ProductVariantsTableData copyWith({
    int? id,
    int? productId,
    String? name,
    double? price,
    bool? isDefault,
    bool? isActive,
  }) => ProductVariantsTableData(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    name: name ?? this.name,
    price: price ?? this.price,
    isDefault: isDefault ?? this.isDefault,
    isActive: isActive ?? this.isActive,
  );
  ProductVariantsTableData copyWithCompanion(
    ProductVariantsTableCompanion data,
  ) {
    return ProductVariantsTableData(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductVariantsTableData(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, name, price, isDefault, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductVariantsTableData &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.name == this.name &&
          other.price == this.price &&
          other.isDefault == this.isDefault &&
          other.isActive == this.isActive);
}

class ProductVariantsTableCompanion
    extends UpdateCompanion<ProductVariantsTableData> {
  final Value<int> id;
  final Value<int> productId;
  final Value<String> name;
  final Value<double> price;
  final Value<bool> isDefault;
  final Value<bool> isActive;
  const ProductVariantsTableCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  ProductVariantsTableCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required String name,
    required double price,
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : productId = Value(productId),
       name = Value(name),
       price = Value(price);
  static Insertable<ProductVariantsTableData> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<String>? name,
    Expression<double>? price,
    Expression<bool>? isDefault,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (isDefault != null) 'is_default': isDefault,
      if (isActive != null) 'is_active': isActive,
    });
  }

  ProductVariantsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<String>? name,
    Value<double>? price,
    Value<bool>? isDefault,
    Value<bool>? isActive,
  }) {
    return ProductVariantsTableCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductVariantsTableCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $ModifierGroupsTableTable extends ModifierGroupsTable
    with TableInfo<$ModifierGroupsTableTable, ModifierGroupsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModifierGroupsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRequiredMeta = const VerificationMeta(
    'isRequired',
  );
  @override
  late final GeneratedColumn<bool> isRequired = GeneratedColumn<bool>(
    'is_required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_required" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _maxSelectionsMeta = const VerificationMeta(
    'maxSelections',
  );
  @override
  late final GeneratedColumn<int> maxSelections = GeneratedColumn<int>(
    'max_selections',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    isRequired,
    maxSelections,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'modifier_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModifierGroupsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_required')) {
      context.handle(
        _isRequiredMeta,
        isRequired.isAcceptableOrUnknown(data['is_required']!, _isRequiredMeta),
      );
    }
    if (data.containsKey('max_selections')) {
      context.handle(
        _maxSelectionsMeta,
        maxSelections.isAcceptableOrUnknown(
          data['max_selections']!,
          _maxSelectionsMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModifierGroupsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModifierGroupsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      isRequired:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_required'],
          )!,
      maxSelections:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}max_selections'],
          )!,
      isActive:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_active'],
          )!,
    );
  }

  @override
  $ModifierGroupsTableTable createAlias(String alias) {
    return $ModifierGroupsTableTable(attachedDatabase, alias);
  }
}

class ModifierGroupsTableData extends DataClass
    implements Insertable<ModifierGroupsTableData> {
  final int id;
  final String name;
  final bool isRequired;
  final int maxSelections;
  final bool isActive;
  const ModifierGroupsTableData({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.maxSelections,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['is_required'] = Variable<bool>(isRequired);
    map['max_selections'] = Variable<int>(maxSelections);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ModifierGroupsTableCompanion toCompanion(bool nullToAbsent) {
    return ModifierGroupsTableCompanion(
      id: Value(id),
      name: Value(name),
      isRequired: Value(isRequired),
      maxSelections: Value(maxSelections),
      isActive: Value(isActive),
    );
  }

  factory ModifierGroupsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModifierGroupsTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isRequired: serializer.fromJson<bool>(json['isRequired']),
      maxSelections: serializer.fromJson<int>(json['maxSelections']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isRequired': serializer.toJson<bool>(isRequired),
      'maxSelections': serializer.toJson<int>(maxSelections),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  ModifierGroupsTableData copyWith({
    int? id,
    String? name,
    bool? isRequired,
    int? maxSelections,
    bool? isActive,
  }) => ModifierGroupsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    isRequired: isRequired ?? this.isRequired,
    maxSelections: maxSelections ?? this.maxSelections,
    isActive: isActive ?? this.isActive,
  );
  ModifierGroupsTableData copyWithCompanion(ModifierGroupsTableCompanion data) {
    return ModifierGroupsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isRequired:
          data.isRequired.present ? data.isRequired.value : this.isRequired,
      maxSelections:
          data.maxSelections.present
              ? data.maxSelections.value
              : this.maxSelections,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModifierGroupsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isRequired: $isRequired, ')
          ..write('maxSelections: $maxSelections, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, isRequired, maxSelections, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModifierGroupsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.isRequired == this.isRequired &&
          other.maxSelections == this.maxSelections &&
          other.isActive == this.isActive);
}

class ModifierGroupsTableCompanion
    extends UpdateCompanion<ModifierGroupsTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> isRequired;
  final Value<int> maxSelections;
  final Value<bool> isActive;
  const ModifierGroupsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.maxSelections = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  ModifierGroupsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.isRequired = const Value.absent(),
    this.maxSelections = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : name = Value(name);
  static Insertable<ModifierGroupsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isRequired,
    Expression<int>? maxSelections,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isRequired != null) 'is_required': isRequired,
      if (maxSelections != null) 'max_selections': maxSelections,
      if (isActive != null) 'is_active': isActive,
    });
  }

  ModifierGroupsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? isRequired,
    Value<int>? maxSelections,
    Value<bool>? isActive,
  }) {
    return ModifierGroupsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isRequired: isRequired ?? this.isRequired,
      maxSelections: maxSelections ?? this.maxSelections,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isRequired.present) {
      map['is_required'] = Variable<bool>(isRequired.value);
    }
    if (maxSelections.present) {
      map['max_selections'] = Variable<int>(maxSelections.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModifierGroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isRequired: $isRequired, ')
          ..write('maxSelections: $maxSelections, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $ModifierOptionsTableTable extends ModifierOptionsTable
    with TableInfo<$ModifierOptionsTableTable, ModifierOptionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModifierOptionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES modifier_groups (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _additionalPriceMeta = const VerificationMeta(
    'additionalPrice',
  );
  @override
  late final GeneratedColumn<double> additionalPrice = GeneratedColumn<double>(
    'additional_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    name,
    additionalPrice,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'modifier_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModifierOptionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('additional_price')) {
      context.handle(
        _additionalPriceMeta,
        additionalPrice.isAcceptableOrUnknown(
          data['additional_price']!,
          _additionalPriceMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModifierOptionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModifierOptionsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      groupId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}group_id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      additionalPrice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}additional_price'],
          )!,
      isActive:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_active'],
          )!,
    );
  }

  @override
  $ModifierOptionsTableTable createAlias(String alias) {
    return $ModifierOptionsTableTable(attachedDatabase, alias);
  }
}

class ModifierOptionsTableData extends DataClass
    implements Insertable<ModifierOptionsTableData> {
  final int id;
  final int groupId;
  final String name;
  final double additionalPrice;
  final bool isActive;
  const ModifierOptionsTableData({
    required this.id,
    required this.groupId,
    required this.name,
    required this.additionalPrice,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<int>(groupId);
    map['name'] = Variable<String>(name);
    map['additional_price'] = Variable<double>(additionalPrice);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ModifierOptionsTableCompanion toCompanion(bool nullToAbsent) {
    return ModifierOptionsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      additionalPrice: Value(additionalPrice),
      isActive: Value(isActive),
    );
  }

  factory ModifierOptionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModifierOptionsTableData(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<int>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      additionalPrice: serializer.fromJson<double>(json['additionalPrice']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<int>(groupId),
      'name': serializer.toJson<String>(name),
      'additionalPrice': serializer.toJson<double>(additionalPrice),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  ModifierOptionsTableData copyWith({
    int? id,
    int? groupId,
    String? name,
    double? additionalPrice,
    bool? isActive,
  }) => ModifierOptionsTableData(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    additionalPrice: additionalPrice ?? this.additionalPrice,
    isActive: isActive ?? this.isActive,
  );
  ModifierOptionsTableData copyWithCompanion(
    ModifierOptionsTableCompanion data,
  ) {
    return ModifierOptionsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      additionalPrice:
          data.additionalPrice.present
              ? data.additionalPrice.value
              : this.additionalPrice,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModifierOptionsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('additionalPrice: $additionalPrice, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, name, additionalPrice, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModifierOptionsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.additionalPrice == this.additionalPrice &&
          other.isActive == this.isActive);
}

class ModifierOptionsTableCompanion
    extends UpdateCompanion<ModifierOptionsTableData> {
  final Value<int> id;
  final Value<int> groupId;
  final Value<String> name;
  final Value<double> additionalPrice;
  final Value<bool> isActive;
  const ModifierOptionsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.additionalPrice = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  ModifierOptionsTableCompanion.insert({
    this.id = const Value.absent(),
    required int groupId,
    required String name,
    this.additionalPrice = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : groupId = Value(groupId),
       name = Value(name);
  static Insertable<ModifierOptionsTableData> custom({
    Expression<int>? id,
    Expression<int>? groupId,
    Expression<String>? name,
    Expression<double>? additionalPrice,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (additionalPrice != null) 'additional_price': additionalPrice,
      if (isActive != null) 'is_active': isActive,
    });
  }

  ModifierOptionsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? groupId,
    Value<String>? name,
    Value<double>? additionalPrice,
    Value<bool>? isActive,
  }) {
    return ModifierOptionsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      additionalPrice: additionalPrice ?? this.additionalPrice,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (additionalPrice.present) {
      map['additional_price'] = Variable<double>(additionalPrice.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModifierOptionsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('additionalPrice: $additionalPrice, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $ProductModifierGroupsTableTable extends ProductModifierGroupsTable
    with
        TableInfo<
          $ProductModifierGroupsTableTable,
          ProductModifierGroupsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductModifierGroupsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _modifierGroupIdMeta = const VerificationMeta(
    'modifierGroupId',
  );
  @override
  late final GeneratedColumn<int> modifierGroupId = GeneratedColumn<int>(
    'modifier_group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES modifier_groups (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, productId, modifierGroupId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_modifier_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductModifierGroupsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('modifier_group_id')) {
      context.handle(
        _modifierGroupIdMeta,
        modifierGroupId.isAcceptableOrUnknown(
          data['modifier_group_id']!,
          _modifierGroupIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modifierGroupIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {productId, modifierGroupId},
  ];
  @override
  ProductModifierGroupsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductModifierGroupsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      productId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}product_id'],
          )!,
      modifierGroupId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}modifier_group_id'],
          )!,
    );
  }

  @override
  $ProductModifierGroupsTableTable createAlias(String alias) {
    return $ProductModifierGroupsTableTable(attachedDatabase, alias);
  }
}

class ProductModifierGroupsTableData extends DataClass
    implements Insertable<ProductModifierGroupsTableData> {
  final int id;
  final int productId;
  final int modifierGroupId;
  const ProductModifierGroupsTableData({
    required this.id,
    required this.productId,
    required this.modifierGroupId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['modifier_group_id'] = Variable<int>(modifierGroupId);
    return map;
  }

  ProductModifierGroupsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductModifierGroupsTableCompanion(
      id: Value(id),
      productId: Value(productId),
      modifierGroupId: Value(modifierGroupId),
    );
  }

  factory ProductModifierGroupsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductModifierGroupsTableData(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      modifierGroupId: serializer.fromJson<int>(json['modifierGroupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'modifierGroupId': serializer.toJson<int>(modifierGroupId),
    };
  }

  ProductModifierGroupsTableData copyWith({
    int? id,
    int? productId,
    int? modifierGroupId,
  }) => ProductModifierGroupsTableData(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    modifierGroupId: modifierGroupId ?? this.modifierGroupId,
  );
  ProductModifierGroupsTableData copyWithCompanion(
    ProductModifierGroupsTableCompanion data,
  ) {
    return ProductModifierGroupsTableData(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      modifierGroupId:
          data.modifierGroupId.present
              ? data.modifierGroupId.value
              : this.modifierGroupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductModifierGroupsTableData(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('modifierGroupId: $modifierGroupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, modifierGroupId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductModifierGroupsTableData &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.modifierGroupId == this.modifierGroupId);
}

class ProductModifierGroupsTableCompanion
    extends UpdateCompanion<ProductModifierGroupsTableData> {
  final Value<int> id;
  final Value<int> productId;
  final Value<int> modifierGroupId;
  const ProductModifierGroupsTableCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.modifierGroupId = const Value.absent(),
  });
  ProductModifierGroupsTableCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required int modifierGroupId,
  }) : productId = Value(productId),
       modifierGroupId = Value(modifierGroupId);
  static Insertable<ProductModifierGroupsTableData> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<int>? modifierGroupId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (modifierGroupId != null) 'modifier_group_id': modifierGroupId,
    });
  }

  ProductModifierGroupsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<int>? modifierGroupId,
  }) {
    return ProductModifierGroupsTableCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      modifierGroupId: modifierGroupId ?? this.modifierGroupId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (modifierGroupId.present) {
      map['modifier_group_id'] = Variable<int>(modifierGroupId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductModifierGroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('modifierGroupId: $modifierGroupId')
          ..write(')'))
        .toString();
  }
}

class $SalesTableTable extends SalesTable
    with TableInfo<$SalesTableTable, SalesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<int> cashierId = GeneratedColumn<int>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountMeta = const VerificationMeta(
    'discount',
  );
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
    'discount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _soNumberMeta = const VerificationMeta(
    'soNumber',
  );
  @override
  late final GeneratedColumn<String> soNumber = GeneratedColumn<String>(
    'so_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidReasonMeta = const VerificationMeta(
    'voidReason',
  );
  @override
  late final GeneratedColumn<String> voidReason = GeneratedColumn<String>(
    'void_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidedAtMeta = const VerificationMeta(
    'voidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> voidedAt = GeneratedColumn<DateTime>(
    'voided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cashierId,
    total,
    discount,
    status,
    type,
    createdAt,
    soNumber,
    voidReason,
    voidedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<SalesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('discount')) {
      context.handle(
        _discountMeta,
        discount.isAcceptableOrUnknown(data['discount']!, _discountMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('so_number')) {
      context.handle(
        _soNumberMeta,
        soNumber.isAcceptableOrUnknown(data['so_number']!, _soNumberMeta),
      );
    }
    if (data.containsKey('void_reason')) {
      context.handle(
        _voidReasonMeta,
        voidReason.isAcceptableOrUnknown(data['void_reason']!, _voidReasonMeta),
      );
    }
    if (data.containsKey('voided_at')) {
      context.handle(
        _voidedAtMeta,
        voidedAt.isAcceptableOrUnknown(data['voided_at']!, _voidedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalesTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      cashierId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}cashier_id'],
          )!,
      total:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}total'],
          )!,
      discount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}discount'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}type'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      soNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}so_number'],
      ),
      voidReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason'],
      ),
      voidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}voided_at'],
      ),
    );
  }

  @override
  $SalesTableTable createAlias(String alias) {
    return $SalesTableTable(attachedDatabase, alias);
  }
}

class SalesTableData extends DataClass implements Insertable<SalesTableData> {
  final int id;
  final int cashierId;
  final double total;
  final double discount;
  final String status;
  final String type;
  final DateTime createdAt;
  final String? soNumber;
  final String? voidReason;
  final DateTime? voidedAt;
  const SalesTableData({
    required this.id,
    required this.cashierId,
    required this.total,
    required this.discount,
    required this.status,
    required this.type,
    required this.createdAt,
    this.soNumber,
    this.voidReason,
    this.voidedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cashier_id'] = Variable<int>(cashierId);
    map['total'] = Variable<double>(total);
    map['discount'] = Variable<double>(discount);
    map['status'] = Variable<String>(status);
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || soNumber != null) {
      map['so_number'] = Variable<String>(soNumber);
    }
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<DateTime>(voidedAt);
    }
    return map;
  }

  SalesTableCompanion toCompanion(bool nullToAbsent) {
    return SalesTableCompanion(
      id: Value(id),
      cashierId: Value(cashierId),
      total: Value(total),
      discount: Value(discount),
      status: Value(status),
      type: Value(type),
      createdAt: Value(createdAt),
      soNumber:
          soNumber == null && nullToAbsent
              ? const Value.absent()
              : Value(soNumber),
      voidReason:
          voidReason == null && nullToAbsent
              ? const Value.absent()
              : Value(voidReason),
      voidedAt:
          voidedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(voidedAt),
    );
  }

  factory SalesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalesTableData(
      id: serializer.fromJson<int>(json['id']),
      cashierId: serializer.fromJson<int>(json['cashierId']),
      total: serializer.fromJson<double>(json['total']),
      discount: serializer.fromJson<double>(json['discount']),
      status: serializer.fromJson<String>(json['status']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      soNumber: serializer.fromJson<String?>(json['soNumber']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      voidedAt: serializer.fromJson<DateTime?>(json['voidedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cashierId': serializer.toJson<int>(cashierId),
      'total': serializer.toJson<double>(total),
      'discount': serializer.toJson<double>(discount),
      'status': serializer.toJson<String>(status),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'soNumber': serializer.toJson<String?>(soNumber),
      'voidReason': serializer.toJson<String?>(voidReason),
      'voidedAt': serializer.toJson<DateTime?>(voidedAt),
    };
  }

  SalesTableData copyWith({
    int? id,
    int? cashierId,
    double? total,
    double? discount,
    String? status,
    String? type,
    DateTime? createdAt,
    Value<String?> soNumber = const Value.absent(),
    Value<String?> voidReason = const Value.absent(),
    Value<DateTime?> voidedAt = const Value.absent(),
  }) => SalesTableData(
    id: id ?? this.id,
    cashierId: cashierId ?? this.cashierId,
    total: total ?? this.total,
    discount: discount ?? this.discount,
    status: status ?? this.status,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    soNumber: soNumber.present ? soNumber.value : this.soNumber,
    voidReason: voidReason.present ? voidReason.value : this.voidReason,
    voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
  );
  SalesTableData copyWithCompanion(SalesTableCompanion data) {
    return SalesTableData(
      id: data.id.present ? data.id.value : this.id,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      total: data.total.present ? data.total.value : this.total,
      discount: data.discount.present ? data.discount.value : this.discount,
      status: data.status.present ? data.status.value : this.status,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      soNumber: data.soNumber.present ? data.soNumber.value : this.soNumber,
      voidReason:
          data.voidReason.present ? data.voidReason.value : this.voidReason,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalesTableData(')
          ..write('id: $id, ')
          ..write('cashierId: $cashierId, ')
          ..write('total: $total, ')
          ..write('discount: $discount, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('soNumber: $soNumber, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidedAt: $voidedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cashierId,
    total,
    discount,
    status,
    type,
    createdAt,
    soNumber,
    voidReason,
    voidedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalesTableData &&
          other.id == this.id &&
          other.cashierId == this.cashierId &&
          other.total == this.total &&
          other.discount == this.discount &&
          other.status == this.status &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.soNumber == this.soNumber &&
          other.voidReason == this.voidReason &&
          other.voidedAt == this.voidedAt);
}

class SalesTableCompanion extends UpdateCompanion<SalesTableData> {
  final Value<int> id;
  final Value<int> cashierId;
  final Value<double> total;
  final Value<double> discount;
  final Value<String> status;
  final Value<String> type;
  final Value<DateTime> createdAt;
  final Value<String?> soNumber;
  final Value<String?> voidReason;
  final Value<DateTime?> voidedAt;
  const SalesTableCompanion({
    this.id = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.total = const Value.absent(),
    this.discount = const Value.absent(),
    this.status = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.soNumber = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidedAt = const Value.absent(),
  });
  SalesTableCompanion.insert({
    this.id = const Value.absent(),
    required int cashierId,
    required double total,
    this.discount = const Value.absent(),
    required String status,
    required String type,
    required DateTime createdAt,
    this.soNumber = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidedAt = const Value.absent(),
  }) : cashierId = Value(cashierId),
       total = Value(total),
       status = Value(status),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<SalesTableData> custom({
    Expression<int>? id,
    Expression<int>? cashierId,
    Expression<double>? total,
    Expression<double>? discount,
    Expression<String>? status,
    Expression<String>? type,
    Expression<DateTime>? createdAt,
    Expression<String>? soNumber,
    Expression<String>? voidReason,
    Expression<DateTime>? voidedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cashierId != null) 'cashier_id': cashierId,
      if (total != null) 'total': total,
      if (discount != null) 'discount': discount,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (soNumber != null) 'so_number': soNumber,
      if (voidReason != null) 'void_reason': voidReason,
      if (voidedAt != null) 'voided_at': voidedAt,
    });
  }

  SalesTableCompanion copyWith({
    Value<int>? id,
    Value<int>? cashierId,
    Value<double>? total,
    Value<double>? discount,
    Value<String>? status,
    Value<String>? type,
    Value<DateTime>? createdAt,
    Value<String?>? soNumber,
    Value<String?>? voidReason,
    Value<DateTime?>? voidedAt,
  }) {
    return SalesTableCompanion(
      id: id ?? this.id,
      cashierId: cashierId ?? this.cashierId,
      total: total ?? this.total,
      discount: discount ?? this.discount,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      soNumber: soNumber ?? this.soNumber,
      voidReason: voidReason ?? this.voidReason,
      voidedAt: voidedAt ?? this.voidedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<int>(cashierId.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (soNumber.present) {
      map['so_number'] = Variable<String>(soNumber.value);
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<DateTime>(voidedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesTableCompanion(')
          ..write('id: $id, ')
          ..write('cashierId: $cashierId, ')
          ..write('total: $total, ')
          ..write('discount: $discount, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('soNumber: $soNumber, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidedAt: $voidedAt')
          ..write(')'))
        .toString();
  }
}

class $SaleItemsTableTable extends SaleItemsTable
    with TableInfo<$SaleItemsTableTable, SaleItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<int> saleId = GeneratedColumn<int>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountTypeMeta = const VerificationMeta(
    'discountType',
  );
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
    'discount_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discountBeneficiaryIdMeta =
      const VerificationMeta('discountBeneficiaryId');
  @override
  late final GeneratedColumn<String> discountBeneficiaryId =
      GeneratedColumn<String>(
        'discount_beneficiary_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _discountBeneficiaryNameMeta =
      const VerificationMeta('discountBeneficiaryName');
  @override
  late final GeneratedColumn<String> discountBeneficiaryName =
      GeneratedColumn<String>(
        'discount_beneficiary_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vatExemptAmountMeta = const VerificationMeta(
    'vatExemptAmount',
  );
  @override
  late final GeneratedColumn<double> vatExemptAmount = GeneratedColumn<double>(
    'vat_exempt_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    productId,
    variantName,
    qty,
    unitPrice,
    discountType,
    discountBeneficiaryId,
    discountBeneficiaryName,
    discountAmount,
    vatExemptAmount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleItemsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_variantNameMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('discount_type')) {
      context.handle(
        _discountTypeMeta,
        discountType.isAcceptableOrUnknown(
          data['discount_type']!,
          _discountTypeMeta,
        ),
      );
    }
    if (data.containsKey('discount_beneficiary_id')) {
      context.handle(
        _discountBeneficiaryIdMeta,
        discountBeneficiaryId.isAcceptableOrUnknown(
          data['discount_beneficiary_id']!,
          _discountBeneficiaryIdMeta,
        ),
      );
    }
    if (data.containsKey('discount_beneficiary_name')) {
      context.handle(
        _discountBeneficiaryNameMeta,
        discountBeneficiaryName.isAcceptableOrUnknown(
          data['discount_beneficiary_name']!,
          _discountBeneficiaryNameMeta,
        ),
      );
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('vat_exempt_amount')) {
      context.handle(
        _vatExemptAmountMeta,
        vatExemptAmount.isAcceptableOrUnknown(
          data['vat_exempt_amount']!,
          _vatExemptAmountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleItemsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      saleId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sale_id'],
          )!,
      productId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}product_id'],
          )!,
      variantName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}variant_name'],
          )!,
      qty:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}qty'],
          )!,
      unitPrice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}unit_price'],
          )!,
      discountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_type'],
      ),
      discountBeneficiaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_beneficiary_id'],
      ),
      discountBeneficiaryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_beneficiary_name'],
      ),
      discountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_amount'],
      ),
      vatExemptAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vat_exempt_amount'],
      ),
    );
  }

  @override
  $SaleItemsTableTable createAlias(String alias) {
    return $SaleItemsTableTable(attachedDatabase, alias);
  }
}

class SaleItemsTableData extends DataClass
    implements Insertable<SaleItemsTableData> {
  final int id;
  final int saleId;
  final int productId;
  final String variantName;
  final int qty;
  final double unitPrice;
  final String? discountType;
  final String? discountBeneficiaryId;
  final String? discountBeneficiaryName;
  final double? discountAmount;
  final double? vatExemptAmount;
  const SaleItemsTableData({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
    this.discountType,
    this.discountBeneficiaryId,
    this.discountBeneficiaryName,
    this.discountAmount,
    this.vatExemptAmount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_id'] = Variable<int>(saleId);
    map['product_id'] = Variable<int>(productId);
    map['variant_name'] = Variable<String>(variantName);
    map['qty'] = Variable<int>(qty);
    map['unit_price'] = Variable<double>(unitPrice);
    if (!nullToAbsent || discountType != null) {
      map['discount_type'] = Variable<String>(discountType);
    }
    if (!nullToAbsent || discountBeneficiaryId != null) {
      map['discount_beneficiary_id'] = Variable<String>(discountBeneficiaryId);
    }
    if (!nullToAbsent || discountBeneficiaryName != null) {
      map['discount_beneficiary_name'] = Variable<String>(
        discountBeneficiaryName,
      );
    }
    if (!nullToAbsent || discountAmount != null) {
      map['discount_amount'] = Variable<double>(discountAmount);
    }
    if (!nullToAbsent || vatExemptAmount != null) {
      map['vat_exempt_amount'] = Variable<double>(vatExemptAmount);
    }
    return map;
  }

  SaleItemsTableCompanion toCompanion(bool nullToAbsent) {
    return SaleItemsTableCompanion(
      id: Value(id),
      saleId: Value(saleId),
      productId: Value(productId),
      variantName: Value(variantName),
      qty: Value(qty),
      unitPrice: Value(unitPrice),
      discountType:
          discountType == null && nullToAbsent
              ? const Value.absent()
              : Value(discountType),
      discountBeneficiaryId:
          discountBeneficiaryId == null && nullToAbsent
              ? const Value.absent()
              : Value(discountBeneficiaryId),
      discountBeneficiaryName:
          discountBeneficiaryName == null && nullToAbsent
              ? const Value.absent()
              : Value(discountBeneficiaryName),
      discountAmount:
          discountAmount == null && nullToAbsent
              ? const Value.absent()
              : Value(discountAmount),
      vatExemptAmount:
          vatExemptAmount == null && nullToAbsent
              ? const Value.absent()
              : Value(vatExemptAmount),
    );
  }

  factory SaleItemsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleItemsTableData(
      id: serializer.fromJson<int>(json['id']),
      saleId: serializer.fromJson<int>(json['saleId']),
      productId: serializer.fromJson<int>(json['productId']),
      variantName: serializer.fromJson<String>(json['variantName']),
      qty: serializer.fromJson<int>(json['qty']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      discountType: serializer.fromJson<String?>(json['discountType']),
      discountBeneficiaryId: serializer.fromJson<String?>(
        json['discountBeneficiaryId'],
      ),
      discountBeneficiaryName: serializer.fromJson<String?>(
        json['discountBeneficiaryName'],
      ),
      discountAmount: serializer.fromJson<double?>(json['discountAmount']),
      vatExemptAmount: serializer.fromJson<double?>(json['vatExemptAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleId': serializer.toJson<int>(saleId),
      'productId': serializer.toJson<int>(productId),
      'variantName': serializer.toJson<String>(variantName),
      'qty': serializer.toJson<int>(qty),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'discountType': serializer.toJson<String?>(discountType),
      'discountBeneficiaryId': serializer.toJson<String?>(
        discountBeneficiaryId,
      ),
      'discountBeneficiaryName': serializer.toJson<String?>(
        discountBeneficiaryName,
      ),
      'discountAmount': serializer.toJson<double?>(discountAmount),
      'vatExemptAmount': serializer.toJson<double?>(vatExemptAmount),
    };
  }

  SaleItemsTableData copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? variantName,
    int? qty,
    double? unitPrice,
    Value<String?> discountType = const Value.absent(),
    Value<String?> discountBeneficiaryId = const Value.absent(),
    Value<String?> discountBeneficiaryName = const Value.absent(),
    Value<double?> discountAmount = const Value.absent(),
    Value<double?> vatExemptAmount = const Value.absent(),
  }) => SaleItemsTableData(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    productId: productId ?? this.productId,
    variantName: variantName ?? this.variantName,
    qty: qty ?? this.qty,
    unitPrice: unitPrice ?? this.unitPrice,
    discountType: discountType.present ? discountType.value : this.discountType,
    discountBeneficiaryId:
        discountBeneficiaryId.present
            ? discountBeneficiaryId.value
            : this.discountBeneficiaryId,
    discountBeneficiaryName:
        discountBeneficiaryName.present
            ? discountBeneficiaryName.value
            : this.discountBeneficiaryName,
    discountAmount:
        discountAmount.present ? discountAmount.value : this.discountAmount,
    vatExemptAmount:
        vatExemptAmount.present ? vatExemptAmount.value : this.vatExemptAmount,
  );
  SaleItemsTableData copyWithCompanion(SaleItemsTableCompanion data) {
    return SaleItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      variantName:
          data.variantName.present ? data.variantName.value : this.variantName,
      qty: data.qty.present ? data.qty.value : this.qty,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      discountType:
          data.discountType.present
              ? data.discountType.value
              : this.discountType,
      discountBeneficiaryId:
          data.discountBeneficiaryId.present
              ? data.discountBeneficiaryId.value
              : this.discountBeneficiaryId,
      discountBeneficiaryName:
          data.discountBeneficiaryName.present
              ? data.discountBeneficiaryName.value
              : this.discountBeneficiaryName,
      discountAmount:
          data.discountAmount.present
              ? data.discountAmount.value
              : this.discountAmount,
      vatExemptAmount:
          data.vatExemptAmount.present
              ? data.vatExemptAmount.value
              : this.vatExemptAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemsTableData(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('variantName: $variantName, ')
          ..write('qty: $qty, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('discountType: $discountType, ')
          ..write('discountBeneficiaryId: $discountBeneficiaryId, ')
          ..write('discountBeneficiaryName: $discountBeneficiaryName, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('vatExemptAmount: $vatExemptAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    productId,
    variantName,
    qty,
    unitPrice,
    discountType,
    discountBeneficiaryId,
    discountBeneficiaryName,
    discountAmount,
    vatExemptAmount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleItemsTableData &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.productId == this.productId &&
          other.variantName == this.variantName &&
          other.qty == this.qty &&
          other.unitPrice == this.unitPrice &&
          other.discountType == this.discountType &&
          other.discountBeneficiaryId == this.discountBeneficiaryId &&
          other.discountBeneficiaryName == this.discountBeneficiaryName &&
          other.discountAmount == this.discountAmount &&
          other.vatExemptAmount == this.vatExemptAmount);
}

class SaleItemsTableCompanion extends UpdateCompanion<SaleItemsTableData> {
  final Value<int> id;
  final Value<int> saleId;
  final Value<int> productId;
  final Value<String> variantName;
  final Value<int> qty;
  final Value<double> unitPrice;
  final Value<String?> discountType;
  final Value<String?> discountBeneficiaryId;
  final Value<String?> discountBeneficiaryName;
  final Value<double?> discountAmount;
  final Value<double?> vatExemptAmount;
  const SaleItemsTableCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.variantName = const Value.absent(),
    this.qty = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.discountType = const Value.absent(),
    this.discountBeneficiaryId = const Value.absent(),
    this.discountBeneficiaryName = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.vatExemptAmount = const Value.absent(),
  });
  SaleItemsTableCompanion.insert({
    this.id = const Value.absent(),
    required int saleId,
    required int productId,
    required String variantName,
    required int qty,
    required double unitPrice,
    this.discountType = const Value.absent(),
    this.discountBeneficiaryId = const Value.absent(),
    this.discountBeneficiaryName = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.vatExemptAmount = const Value.absent(),
  }) : saleId = Value(saleId),
       productId = Value(productId),
       variantName = Value(variantName),
       qty = Value(qty),
       unitPrice = Value(unitPrice);
  static Insertable<SaleItemsTableData> custom({
    Expression<int>? id,
    Expression<int>? saleId,
    Expression<int>? productId,
    Expression<String>? variantName,
    Expression<int>? qty,
    Expression<double>? unitPrice,
    Expression<String>? discountType,
    Expression<String>? discountBeneficiaryId,
    Expression<String>? discountBeneficiaryName,
    Expression<double>? discountAmount,
    Expression<double>? vatExemptAmount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      if (variantName != null) 'variant_name': variantName,
      if (qty != null) 'qty': qty,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (discountType != null) 'discount_type': discountType,
      if (discountBeneficiaryId != null)
        'discount_beneficiary_id': discountBeneficiaryId,
      if (discountBeneficiaryName != null)
        'discount_beneficiary_name': discountBeneficiaryName,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (vatExemptAmount != null) 'vat_exempt_amount': vatExemptAmount,
    });
  }

  SaleItemsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? saleId,
    Value<int>? productId,
    Value<String>? variantName,
    Value<int>? qty,
    Value<double>? unitPrice,
    Value<String?>? discountType,
    Value<String?>? discountBeneficiaryId,
    Value<String?>? discountBeneficiaryName,
    Value<double?>? discountAmount,
    Value<double?>? vatExemptAmount,
  }) {
    return SaleItemsTableCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      variantName: variantName ?? this.variantName,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      discountType: discountType ?? this.discountType,
      discountBeneficiaryId:
          discountBeneficiaryId ?? this.discountBeneficiaryId,
      discountBeneficiaryName:
          discountBeneficiaryName ?? this.discountBeneficiaryName,
      discountAmount: discountAmount ?? this.discountAmount,
      vatExemptAmount: vatExemptAmount ?? this.vatExemptAmount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<int>(saleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (discountBeneficiaryId.present) {
      map['discount_beneficiary_id'] = Variable<String>(
        discountBeneficiaryId.value,
      );
    }
    if (discountBeneficiaryName.present) {
      map['discount_beneficiary_name'] = Variable<String>(
        discountBeneficiaryName.value,
      );
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (vatExemptAmount.present) {
      map['vat_exempt_amount'] = Variable<double>(vatExemptAmount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('variantName: $variantName, ')
          ..write('qty: $qty, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('discountType: $discountType, ')
          ..write('discountBeneficiaryId: $discountBeneficiaryId, ')
          ..write('discountBeneficiaryName: $discountBeneficiaryName, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('vatExemptAmount: $vatExemptAmount')
          ..write(')'))
        .toString();
  }
}

class $SaleItemModifiersTableTable extends SaleItemModifiersTable
    with TableInfo<$SaleItemModifiersTableTable, SaleItemModifiersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleItemModifiersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sale_items (id)',
    ),
  );
  static const VerificationMeta _modifierNameMeta = const VerificationMeta(
    'modifierName',
  );
  @override
  late final GeneratedColumn<String> modifierName = GeneratedColumn<String>(
    'modifier_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _additionalPriceMeta = const VerificationMeta(
    'additionalPrice',
  );
  @override
  late final GeneratedColumn<double> additionalPrice = GeneratedColumn<double>(
    'additional_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    modifierName,
    additionalPrice,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_item_modifiers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleItemModifiersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('modifier_name')) {
      context.handle(
        _modifierNameMeta,
        modifierName.isAcceptableOrUnknown(
          data['modifier_name']!,
          _modifierNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modifierNameMeta);
    }
    if (data.containsKey('additional_price')) {
      context.handle(
        _additionalPriceMeta,
        additionalPrice.isAcceptableOrUnknown(
          data['additional_price']!,
          _additionalPriceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleItemModifiersTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleItemModifiersTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      itemId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}item_id'],
          )!,
      modifierName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}modifier_name'],
          )!,
      additionalPrice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}additional_price'],
          )!,
    );
  }

  @override
  $SaleItemModifiersTableTable createAlias(String alias) {
    return $SaleItemModifiersTableTable(attachedDatabase, alias);
  }
}

class SaleItemModifiersTableData extends DataClass
    implements Insertable<SaleItemModifiersTableData> {
  final int id;
  final int itemId;
  final String modifierName;
  final double additionalPrice;
  const SaleItemModifiersTableData({
    required this.id,
    required this.itemId,
    required this.modifierName,
    required this.additionalPrice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['modifier_name'] = Variable<String>(modifierName);
    map['additional_price'] = Variable<double>(additionalPrice);
    return map;
  }

  SaleItemModifiersTableCompanion toCompanion(bool nullToAbsent) {
    return SaleItemModifiersTableCompanion(
      id: Value(id),
      itemId: Value(itemId),
      modifierName: Value(modifierName),
      additionalPrice: Value(additionalPrice),
    );
  }

  factory SaleItemModifiersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleItemModifiersTableData(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      modifierName: serializer.fromJson<String>(json['modifierName']),
      additionalPrice: serializer.fromJson<double>(json['additionalPrice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'modifierName': serializer.toJson<String>(modifierName),
      'additionalPrice': serializer.toJson<double>(additionalPrice),
    };
  }

  SaleItemModifiersTableData copyWith({
    int? id,
    int? itemId,
    String? modifierName,
    double? additionalPrice,
  }) => SaleItemModifiersTableData(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    modifierName: modifierName ?? this.modifierName,
    additionalPrice: additionalPrice ?? this.additionalPrice,
  );
  SaleItemModifiersTableData copyWithCompanion(
    SaleItemModifiersTableCompanion data,
  ) {
    return SaleItemModifiersTableData(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      modifierName:
          data.modifierName.present
              ? data.modifierName.value
              : this.modifierName,
      additionalPrice:
          data.additionalPrice.present
              ? data.additionalPrice.value
              : this.additionalPrice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemModifiersTableData(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('modifierName: $modifierName, ')
          ..write('additionalPrice: $additionalPrice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, modifierName, additionalPrice);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleItemModifiersTableData &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.modifierName == this.modifierName &&
          other.additionalPrice == this.additionalPrice);
}

class SaleItemModifiersTableCompanion
    extends UpdateCompanion<SaleItemModifiersTableData> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> modifierName;
  final Value<double> additionalPrice;
  const SaleItemModifiersTableCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.modifierName = const Value.absent(),
    this.additionalPrice = const Value.absent(),
  });
  SaleItemModifiersTableCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required String modifierName,
    this.additionalPrice = const Value.absent(),
  }) : itemId = Value(itemId),
       modifierName = Value(modifierName);
  static Insertable<SaleItemModifiersTableData> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? modifierName,
    Expression<double>? additionalPrice,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (modifierName != null) 'modifier_name': modifierName,
      if (additionalPrice != null) 'additional_price': additionalPrice,
    });
  }

  SaleItemModifiersTableCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<String>? modifierName,
    Value<double>? additionalPrice,
  }) {
    return SaleItemModifiersTableCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      modifierName: modifierName ?? this.modifierName,
      additionalPrice: additionalPrice ?? this.additionalPrice,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (modifierName.present) {
      map['modifier_name'] = Variable<String>(modifierName.value);
    }
    if (additionalPrice.present) {
      map['additional_price'] = Variable<double>(additionalPrice.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemModifiersTableCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('modifierName: $modifierName, ')
          ..write('additionalPrice: $additionalPrice')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTableTable extends PaymentsTable
    with TableInfo<$PaymentsTableTable, PaymentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<int> saleId = GeneratedColumn<int>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id)',
    ),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashReceivedMeta = const VerificationMeta(
    'cashReceived',
  );
  @override
  late final GeneratedColumn<double> cashReceived = GeneratedColumn<double>(
    'cash_received',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    method,
    amount,
    cashReceived,
    reference,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('cash_received')) {
      context.handle(
        _cashReceivedMeta,
        cashReceived.isAcceptableOrUnknown(
          data['cash_received']!,
          _cashReceivedMeta,
        ),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      saleId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sale_id'],
          )!,
      method:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}method'],
          )!,
      amount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}amount'],
          )!,
      cashReceived: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_received'],
      ),
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $PaymentsTableTable createAlias(String alias) {
    return $PaymentsTableTable(attachedDatabase, alias);
  }
}

class PaymentsTableData extends DataClass
    implements Insertable<PaymentsTableData> {
  final int id;
  final int saleId;
  final String method;
  final double amount;
  final double? cashReceived;
  final String? reference;
  final DateTime createdAt;
  const PaymentsTableData({
    required this.id,
    required this.saleId,
    required this.method,
    required this.amount,
    this.cashReceived,
    this.reference,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_id'] = Variable<int>(saleId);
    map['method'] = Variable<String>(method);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || cashReceived != null) {
      map['cash_received'] = Variable<double>(cashReceived);
    }
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PaymentsTableCompanion toCompanion(bool nullToAbsent) {
    return PaymentsTableCompanion(
      id: Value(id),
      saleId: Value(saleId),
      method: Value(method),
      amount: Value(amount),
      cashReceived:
          cashReceived == null && nullToAbsent
              ? const Value.absent()
              : Value(cashReceived),
      reference:
          reference == null && nullToAbsent
              ? const Value.absent()
              : Value(reference),
      createdAt: Value(createdAt),
    );
  }

  factory PaymentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentsTableData(
      id: serializer.fromJson<int>(json['id']),
      saleId: serializer.fromJson<int>(json['saleId']),
      method: serializer.fromJson<String>(json['method']),
      amount: serializer.fromJson<double>(json['amount']),
      cashReceived: serializer.fromJson<double?>(json['cashReceived']),
      reference: serializer.fromJson<String?>(json['reference']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleId': serializer.toJson<int>(saleId),
      'method': serializer.toJson<String>(method),
      'amount': serializer.toJson<double>(amount),
      'cashReceived': serializer.toJson<double?>(cashReceived),
      'reference': serializer.toJson<String?>(reference),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PaymentsTableData copyWith({
    int? id,
    int? saleId,
    String? method,
    double? amount,
    Value<double?> cashReceived = const Value.absent(),
    Value<String?> reference = const Value.absent(),
    DateTime? createdAt,
  }) => PaymentsTableData(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    method: method ?? this.method,
    amount: amount ?? this.amount,
    cashReceived: cashReceived.present ? cashReceived.value : this.cashReceived,
    reference: reference.present ? reference.value : this.reference,
    createdAt: createdAt ?? this.createdAt,
  );
  PaymentsTableData copyWithCompanion(PaymentsTableCompanion data) {
    return PaymentsTableData(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      method: data.method.present ? data.method.value : this.method,
      amount: data.amount.present ? data.amount.value : this.amount,
      cashReceived:
          data.cashReceived.present
              ? data.cashReceived.value
              : this.cashReceived,
      reference: data.reference.present ? data.reference.value : this.reference,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsTableData(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('cashReceived: $cashReceived, ')
          ..write('reference: $reference, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    method,
    amount,
    cashReceived,
    reference,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentsTableData &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.method == this.method &&
          other.amount == this.amount &&
          other.cashReceived == this.cashReceived &&
          other.reference == this.reference &&
          other.createdAt == this.createdAt);
}

class PaymentsTableCompanion extends UpdateCompanion<PaymentsTableData> {
  final Value<int> id;
  final Value<int> saleId;
  final Value<String> method;
  final Value<double> amount;
  final Value<double?> cashReceived;
  final Value<String?> reference;
  final Value<DateTime> createdAt;
  const PaymentsTableCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.method = const Value.absent(),
    this.amount = const Value.absent(),
    this.cashReceived = const Value.absent(),
    this.reference = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PaymentsTableCompanion.insert({
    this.id = const Value.absent(),
    required int saleId,
    required String method,
    required double amount,
    this.cashReceived = const Value.absent(),
    this.reference = const Value.absent(),
    required DateTime createdAt,
  }) : saleId = Value(saleId),
       method = Value(method),
       amount = Value(amount),
       createdAt = Value(createdAt);
  static Insertable<PaymentsTableData> custom({
    Expression<int>? id,
    Expression<int>? saleId,
    Expression<String>? method,
    Expression<double>? amount,
    Expression<double>? cashReceived,
    Expression<String>? reference,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (method != null) 'method': method,
      if (amount != null) 'amount': amount,
      if (cashReceived != null) 'cash_received': cashReceived,
      if (reference != null) 'reference': reference,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PaymentsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? saleId,
    Value<String>? method,
    Value<double>? amount,
    Value<double?>? cashReceived,
    Value<String?>? reference,
    Value<DateTime>? createdAt,
  }) {
    return PaymentsTableCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      cashReceived: cashReceived ?? this.cashReceived,
      reference: reference ?? this.reference,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<int>(saleId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (cashReceived.present) {
      map['cash_received'] = Variable<double>(cashReceived.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsTableCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('cashReceived: $cashReceived, ')
          ..write('reference: $reference, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RefundsTableTable extends RefundsTable
    with TableInfo<$RefundsTableTable, RefundsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefundsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<int> saleId = GeneratedColumn<int>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id)',
    ),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refundNumberMeta = const VerificationMeta(
    'refundNumber',
  );
  @override
  late final GeneratedColumn<String> refundNumber = GeneratedColumn<String>(
    'refund_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Cash Refund'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    reason,
    total,
    createdAt,
    refundNumber,
    method,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'refunds';
  @override
  VerificationContext validateIntegrity(
    Insertable<RefundsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('refund_number')) {
      context.handle(
        _refundNumberMeta,
        refundNumber.isAcceptableOrUnknown(
          data['refund_number']!,
          _refundNumberMeta,
        ),
      );
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RefundsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RefundsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      saleId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sale_id'],
          )!,
      reason:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}reason'],
          )!,
      total:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}total'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      refundNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refund_number'],
      ),
      method:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}method'],
          )!,
    );
  }

  @override
  $RefundsTableTable createAlias(String alias) {
    return $RefundsTableTable(attachedDatabase, alias);
  }
}

class RefundsTableData extends DataClass
    implements Insertable<RefundsTableData> {
  final int id;
  final int saleId;
  final String reason;
  final double total;
  final DateTime createdAt;
  final String? refundNumber;
  final String method;
  const RefundsTableData({
    required this.id,
    required this.saleId,
    required this.reason,
    required this.total,
    required this.createdAt,
    this.refundNumber,
    required this.method,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_id'] = Variable<int>(saleId);
    map['reason'] = Variable<String>(reason);
    map['total'] = Variable<double>(total);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || refundNumber != null) {
      map['refund_number'] = Variable<String>(refundNumber);
    }
    map['method'] = Variable<String>(method);
    return map;
  }

  RefundsTableCompanion toCompanion(bool nullToAbsent) {
    return RefundsTableCompanion(
      id: Value(id),
      saleId: Value(saleId),
      reason: Value(reason),
      total: Value(total),
      createdAt: Value(createdAt),
      refundNumber:
          refundNumber == null && nullToAbsent
              ? const Value.absent()
              : Value(refundNumber),
      method: Value(method),
    );
  }

  factory RefundsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RefundsTableData(
      id: serializer.fromJson<int>(json['id']),
      saleId: serializer.fromJson<int>(json['saleId']),
      reason: serializer.fromJson<String>(json['reason']),
      total: serializer.fromJson<double>(json['total']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      refundNumber: serializer.fromJson<String?>(json['refundNumber']),
      method: serializer.fromJson<String>(json['method']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleId': serializer.toJson<int>(saleId),
      'reason': serializer.toJson<String>(reason),
      'total': serializer.toJson<double>(total),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'refundNumber': serializer.toJson<String?>(refundNumber),
      'method': serializer.toJson<String>(method),
    };
  }

  RefundsTableData copyWith({
    int? id,
    int? saleId,
    String? reason,
    double? total,
    DateTime? createdAt,
    Value<String?> refundNumber = const Value.absent(),
    String? method,
  }) => RefundsTableData(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    reason: reason ?? this.reason,
    total: total ?? this.total,
    createdAt: createdAt ?? this.createdAt,
    refundNumber: refundNumber.present ? refundNumber.value : this.refundNumber,
    method: method ?? this.method,
  );
  RefundsTableData copyWithCompanion(RefundsTableCompanion data) {
    return RefundsTableData(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      reason: data.reason.present ? data.reason.value : this.reason,
      total: data.total.present ? data.total.value : this.total,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      refundNumber:
          data.refundNumber.present
              ? data.refundNumber.value
              : this.refundNumber,
      method: data.method.present ? data.method.value : this.method,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RefundsTableData(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('reason: $reason, ')
          ..write('total: $total, ')
          ..write('createdAt: $createdAt, ')
          ..write('refundNumber: $refundNumber, ')
          ..write('method: $method')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, saleId, reason, total, createdAt, refundNumber, method);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefundsTableData &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.reason == this.reason &&
          other.total == this.total &&
          other.createdAt == this.createdAt &&
          other.refundNumber == this.refundNumber &&
          other.method == this.method);
}

class RefundsTableCompanion extends UpdateCompanion<RefundsTableData> {
  final Value<int> id;
  final Value<int> saleId;
  final Value<String> reason;
  final Value<double> total;
  final Value<DateTime> createdAt;
  final Value<String?> refundNumber;
  final Value<String> method;
  const RefundsTableCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.reason = const Value.absent(),
    this.total = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.refundNumber = const Value.absent(),
    this.method = const Value.absent(),
  });
  RefundsTableCompanion.insert({
    this.id = const Value.absent(),
    required int saleId,
    required String reason,
    required double total,
    required DateTime createdAt,
    this.refundNumber = const Value.absent(),
    this.method = const Value.absent(),
  }) : saleId = Value(saleId),
       reason = Value(reason),
       total = Value(total),
       createdAt = Value(createdAt);
  static Insertable<RefundsTableData> custom({
    Expression<int>? id,
    Expression<int>? saleId,
    Expression<String>? reason,
    Expression<double>? total,
    Expression<DateTime>? createdAt,
    Expression<String>? refundNumber,
    Expression<String>? method,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (reason != null) 'reason': reason,
      if (total != null) 'total': total,
      if (createdAt != null) 'created_at': createdAt,
      if (refundNumber != null) 'refund_number': refundNumber,
      if (method != null) 'method': method,
    });
  }

  RefundsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? saleId,
    Value<String>? reason,
    Value<double>? total,
    Value<DateTime>? createdAt,
    Value<String?>? refundNumber,
    Value<String>? method,
  }) {
    return RefundsTableCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      reason: reason ?? this.reason,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      refundNumber: refundNumber ?? this.refundNumber,
      method: method ?? this.method,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<int>(saleId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (refundNumber.present) {
      map['refund_number'] = Variable<String>(refundNumber.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefundsTableCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('reason: $reason, ')
          ..write('total: $total, ')
          ..write('createdAt: $createdAt, ')
          ..write('refundNumber: $refundNumber, ')
          ..write('method: $method')
          ..write(')'))
        .toString();
  }
}

class $RefundItemsTableTable extends RefundItemsTable
    with TableInfo<$RefundItemsTableTable, RefundItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefundItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _refundIdMeta = const VerificationMeta(
    'refundId',
  );
  @override
  late final GeneratedColumn<int> refundId = GeneratedColumn<int>(
    'refund_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES refunds (id)',
    ),
  );
  static const VerificationMeta _saleItemIdMeta = const VerificationMeta(
    'saleItemId',
  );
  @override
  late final GeneratedColumn<int> saleItemId = GeneratedColumn<int>(
    'sale_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sale_items (id)',
    ),
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, refundId, saleItemId, qty, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'refund_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<RefundItemsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('refund_id')) {
      context.handle(
        _refundIdMeta,
        refundId.isAcceptableOrUnknown(data['refund_id']!, _refundIdMeta),
      );
    } else if (isInserting) {
      context.missing(_refundIdMeta);
    }
    if (data.containsKey('sale_item_id')) {
      context.handle(
        _saleItemIdMeta,
        saleItemId.isAcceptableOrUnknown(
          data['sale_item_id']!,
          _saleItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saleItemIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RefundItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RefundItemsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      refundId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}refund_id'],
          )!,
      saleItemId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sale_item_id'],
          )!,
      qty:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}qty'],
          )!,
      amount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}amount'],
          )!,
    );
  }

  @override
  $RefundItemsTableTable createAlias(String alias) {
    return $RefundItemsTableTable(attachedDatabase, alias);
  }
}

class RefundItemsTableData extends DataClass
    implements Insertable<RefundItemsTableData> {
  final int id;
  final int refundId;
  final int saleItemId;
  final int qty;
  final double amount;
  const RefundItemsTableData({
    required this.id,
    required this.refundId,
    required this.saleItemId,
    required this.qty,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['refund_id'] = Variable<int>(refundId);
    map['sale_item_id'] = Variable<int>(saleItemId);
    map['qty'] = Variable<int>(qty);
    map['amount'] = Variable<double>(amount);
    return map;
  }

  RefundItemsTableCompanion toCompanion(bool nullToAbsent) {
    return RefundItemsTableCompanion(
      id: Value(id),
      refundId: Value(refundId),
      saleItemId: Value(saleItemId),
      qty: Value(qty),
      amount: Value(amount),
    );
  }

  factory RefundItemsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RefundItemsTableData(
      id: serializer.fromJson<int>(json['id']),
      refundId: serializer.fromJson<int>(json['refundId']),
      saleItemId: serializer.fromJson<int>(json['saleItemId']),
      qty: serializer.fromJson<int>(json['qty']),
      amount: serializer.fromJson<double>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'refundId': serializer.toJson<int>(refundId),
      'saleItemId': serializer.toJson<int>(saleItemId),
      'qty': serializer.toJson<int>(qty),
      'amount': serializer.toJson<double>(amount),
    };
  }

  RefundItemsTableData copyWith({
    int? id,
    int? refundId,
    int? saleItemId,
    int? qty,
    double? amount,
  }) => RefundItemsTableData(
    id: id ?? this.id,
    refundId: refundId ?? this.refundId,
    saleItemId: saleItemId ?? this.saleItemId,
    qty: qty ?? this.qty,
    amount: amount ?? this.amount,
  );
  RefundItemsTableData copyWithCompanion(RefundItemsTableCompanion data) {
    return RefundItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      refundId: data.refundId.present ? data.refundId.value : this.refundId,
      saleItemId:
          data.saleItemId.present ? data.saleItemId.value : this.saleItemId,
      qty: data.qty.present ? data.qty.value : this.qty,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RefundItemsTableData(')
          ..write('id: $id, ')
          ..write('refundId: $refundId, ')
          ..write('saleItemId: $saleItemId, ')
          ..write('qty: $qty, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, refundId, saleItemId, qty, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefundItemsTableData &&
          other.id == this.id &&
          other.refundId == this.refundId &&
          other.saleItemId == this.saleItemId &&
          other.qty == this.qty &&
          other.amount == this.amount);
}

class RefundItemsTableCompanion extends UpdateCompanion<RefundItemsTableData> {
  final Value<int> id;
  final Value<int> refundId;
  final Value<int> saleItemId;
  final Value<int> qty;
  final Value<double> amount;
  const RefundItemsTableCompanion({
    this.id = const Value.absent(),
    this.refundId = const Value.absent(),
    this.saleItemId = const Value.absent(),
    this.qty = const Value.absent(),
    this.amount = const Value.absent(),
  });
  RefundItemsTableCompanion.insert({
    this.id = const Value.absent(),
    required int refundId,
    required int saleItemId,
    required int qty,
    required double amount,
  }) : refundId = Value(refundId),
       saleItemId = Value(saleItemId),
       qty = Value(qty),
       amount = Value(amount);
  static Insertable<RefundItemsTableData> custom({
    Expression<int>? id,
    Expression<int>? refundId,
    Expression<int>? saleItemId,
    Expression<int>? qty,
    Expression<double>? amount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (refundId != null) 'refund_id': refundId,
      if (saleItemId != null) 'sale_item_id': saleItemId,
      if (qty != null) 'qty': qty,
      if (amount != null) 'amount': amount,
    });
  }

  RefundItemsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? refundId,
    Value<int>? saleItemId,
    Value<int>? qty,
    Value<double>? amount,
  }) {
    return RefundItemsTableCompanion(
      id: id ?? this.id,
      refundId: refundId ?? this.refundId,
      saleItemId: saleItemId ?? this.saleItemId,
      qty: qty ?? this.qty,
      amount: amount ?? this.amount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (refundId.present) {
      map['refund_id'] = Variable<int>(refundId.value);
    }
    if (saleItemId.present) {
      map['sale_item_id'] = Variable<int>(saleItemId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefundItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('refundId: $refundId, ')
          ..write('saleItemId: $saleItemId, ')
          ..write('qty: $qty, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }
}

class $StoreInfoTableTable extends StoreInfoTable
    with TableInfo<$StoreInfoTableTable, StoreInfoTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreInfoTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _taxRateMeta = const VerificationMeta(
    'taxRate',
  );
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
    'tax_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PHP'),
  );
  static const VerificationMeta _receiptFooterMeta = const VerificationMeta(
    'receiptFooter',
  );
  @override
  late final GeneratedColumn<String> receiptFooter = GeneratedColumn<String>(
    'receipt_footer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tinMeta = const VerificationMeta('tin');
  @override
  late final GeneratedColumn<String> tin = GeneratedColumn<String>(
    'tin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _terminalNameMeta = const VerificationMeta(
    'terminalName',
  );
  @override
  late final GeneratedColumn<String> terminalName = GeneratedColumn<String>(
    'terminal_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    storeName,
    address,
    taxRate,
    currency,
    receiptFooter,
    tin,
    terminalName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store_info';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoreInfoTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('tax_rate')) {
      context.handle(
        _taxRateMeta,
        taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('receipt_footer')) {
      context.handle(
        _receiptFooterMeta,
        receiptFooter.isAcceptableOrUnknown(
          data['receipt_footer']!,
          _receiptFooterMeta,
        ),
      );
    }
    if (data.containsKey('tin')) {
      context.handle(
        _tinMeta,
        tin.isAcceptableOrUnknown(data['tin']!, _tinMeta),
      );
    }
    if (data.containsKey('terminal_name')) {
      context.handle(
        _terminalNameMeta,
        terminalName.isAcceptableOrUnknown(
          data['terminal_name']!,
          _terminalNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoreInfoTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreInfoTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      storeId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}store_id'],
          )!,
      storeName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}store_name'],
          )!,
      address:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}address'],
          )!,
      taxRate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}tax_rate'],
          )!,
      currency:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}currency'],
          )!,
      receiptFooter:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}receipt_footer'],
          )!,
      tin:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}tin'],
          )!,
      terminalName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}terminal_name'],
          )!,
    );
  }

  @override
  $StoreInfoTableTable createAlias(String alias) {
    return $StoreInfoTableTable(attachedDatabase, alias);
  }
}

class StoreInfoTableData extends DataClass
    implements Insertable<StoreInfoTableData> {
  final int id;
  final String storeId;
  final String storeName;
  final String address;
  final double taxRate;
  final String currency;
  final String receiptFooter;
  final String tin;
  final String terminalName;
  const StoreInfoTableData({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.address,
    required this.taxRate,
    required this.currency,
    required this.receiptFooter,
    required this.tin,
    required this.terminalName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['store_id'] = Variable<String>(storeId);
    map['store_name'] = Variable<String>(storeName);
    map['address'] = Variable<String>(address);
    map['tax_rate'] = Variable<double>(taxRate);
    map['currency'] = Variable<String>(currency);
    map['receipt_footer'] = Variable<String>(receiptFooter);
    map['tin'] = Variable<String>(tin);
    map['terminal_name'] = Variable<String>(terminalName);
    return map;
  }

  StoreInfoTableCompanion toCompanion(bool nullToAbsent) {
    return StoreInfoTableCompanion(
      id: Value(id),
      storeId: Value(storeId),
      storeName: Value(storeName),
      address: Value(address),
      taxRate: Value(taxRate),
      currency: Value(currency),
      receiptFooter: Value(receiptFooter),
      tin: Value(tin),
      terminalName: Value(terminalName),
    );
  }

  factory StoreInfoTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreInfoTableData(
      id: serializer.fromJson<int>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      storeName: serializer.fromJson<String>(json['storeName']),
      address: serializer.fromJson<String>(json['address']),
      taxRate: serializer.fromJson<double>(json['taxRate']),
      currency: serializer.fromJson<String>(json['currency']),
      receiptFooter: serializer.fromJson<String>(json['receiptFooter']),
      tin: serializer.fromJson<String>(json['tin']),
      terminalName: serializer.fromJson<String>(json['terminalName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storeId': serializer.toJson<String>(storeId),
      'storeName': serializer.toJson<String>(storeName),
      'address': serializer.toJson<String>(address),
      'taxRate': serializer.toJson<double>(taxRate),
      'currency': serializer.toJson<String>(currency),
      'receiptFooter': serializer.toJson<String>(receiptFooter),
      'tin': serializer.toJson<String>(tin),
      'terminalName': serializer.toJson<String>(terminalName),
    };
  }

  StoreInfoTableData copyWith({
    int? id,
    String? storeId,
    String? storeName,
    String? address,
    double? taxRate,
    String? currency,
    String? receiptFooter,
    String? tin,
    String? terminalName,
  }) => StoreInfoTableData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    storeName: storeName ?? this.storeName,
    address: address ?? this.address,
    taxRate: taxRate ?? this.taxRate,
    currency: currency ?? this.currency,
    receiptFooter: receiptFooter ?? this.receiptFooter,
    tin: tin ?? this.tin,
    terminalName: terminalName ?? this.terminalName,
  );
  StoreInfoTableData copyWithCompanion(StoreInfoTableCompanion data) {
    return StoreInfoTableData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      address: data.address.present ? data.address.value : this.address,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      currency: data.currency.present ? data.currency.value : this.currency,
      receiptFooter:
          data.receiptFooter.present
              ? data.receiptFooter.value
              : this.receiptFooter,
      tin: data.tin.present ? data.tin.value : this.tin,
      terminalName:
          data.terminalName.present
              ? data.terminalName.value
              : this.terminalName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreInfoTableData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('address: $address, ')
          ..write('taxRate: $taxRate, ')
          ..write('currency: $currency, ')
          ..write('receiptFooter: $receiptFooter, ')
          ..write('tin: $tin, ')
          ..write('terminalName: $terminalName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    storeName,
    address,
    taxRate,
    currency,
    receiptFooter,
    tin,
    terminalName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreInfoTableData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.storeName == this.storeName &&
          other.address == this.address &&
          other.taxRate == this.taxRate &&
          other.currency == this.currency &&
          other.receiptFooter == this.receiptFooter &&
          other.tin == this.tin &&
          other.terminalName == this.terminalName);
}

class StoreInfoTableCompanion extends UpdateCompanion<StoreInfoTableData> {
  final Value<int> id;
  final Value<String> storeId;
  final Value<String> storeName;
  final Value<String> address;
  final Value<double> taxRate;
  final Value<String> currency;
  final Value<String> receiptFooter;
  final Value<String> tin;
  final Value<String> terminalName;
  const StoreInfoTableCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.address = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.currency = const Value.absent(),
    this.receiptFooter = const Value.absent(),
    this.tin = const Value.absent(),
    this.terminalName = const Value.absent(),
  });
  StoreInfoTableCompanion.insert({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.address = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.currency = const Value.absent(),
    this.receiptFooter = const Value.absent(),
    this.tin = const Value.absent(),
    this.terminalName = const Value.absent(),
  });
  static Insertable<StoreInfoTableData> custom({
    Expression<int>? id,
    Expression<String>? storeId,
    Expression<String>? storeName,
    Expression<String>? address,
    Expression<double>? taxRate,
    Expression<String>? currency,
    Expression<String>? receiptFooter,
    Expression<String>? tin,
    Expression<String>? terminalName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (storeName != null) 'store_name': storeName,
      if (address != null) 'address': address,
      if (taxRate != null) 'tax_rate': taxRate,
      if (currency != null) 'currency': currency,
      if (receiptFooter != null) 'receipt_footer': receiptFooter,
      if (tin != null) 'tin': tin,
      if (terminalName != null) 'terminal_name': terminalName,
    });
  }

  StoreInfoTableCompanion copyWith({
    Value<int>? id,
    Value<String>? storeId,
    Value<String>? storeName,
    Value<String>? address,
    Value<double>? taxRate,
    Value<String>? currency,
    Value<String>? receiptFooter,
    Value<String>? tin,
    Value<String>? terminalName,
  }) {
    return StoreInfoTableCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      taxRate: taxRate ?? this.taxRate,
      currency: currency ?? this.currency,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      tin: tin ?? this.tin,
      terminalName: terminalName ?? this.terminalName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (receiptFooter.present) {
      map['receipt_footer'] = Variable<String>(receiptFooter.value);
    }
    if (tin.present) {
      map['tin'] = Variable<String>(tin.value);
    }
    if (terminalName.present) {
      map['terminal_name'] = Variable<String>(terminalName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoreInfoTableCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('address: $address, ')
          ..write('taxRate: $taxRate, ')
          ..write('currency: $currency, ')
          ..write('receiptFooter: $receiptFooter, ')
          ..write('tin: $tin, ')
          ..write('terminalName: $terminalName')
          ..write(')'))
        .toString();
  }
}

class $XReadingsTableTable extends XReadingsTable
    with TableInfo<$XReadingsTableTable, XReadingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $XReadingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<int> cashierId = GeneratedColumn<int>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashierNameMeta = const VerificationMeta(
    'cashierName',
  );
  @override
  late final GeneratedColumn<String> cashierName = GeneratedColumn<String>(
    'cashier_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta(
    'periodStart',
  );
  @override
  late final GeneratedColumn<DateTime> periodStart = GeneratedColumn<DateTime>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodEndMeta = const VerificationMeta(
    'periodEnd',
  );
  @override
  late final GeneratedColumn<DateTime> periodEnd = GeneratedColumn<DateTime>(
    'period_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSalesMeta = const VerificationMeta(
    'totalSales',
  );
  @override
  late final GeneratedColumn<double> totalSales = GeneratedColumn<double>(
    'total_sales',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionCountMeta = const VerificationMeta(
    'transactionCount',
  );
  @override
  late final GeneratedColumn<int> transactionCount = GeneratedColumn<int>(
    'transaction_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voidedCountMeta = const VerificationMeta(
    'voidedCount',
  );
  @override
  late final GeneratedColumn<int> voidedCount = GeneratedColumn<int>(
    'voided_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refundedCountMeta = const VerificationMeta(
    'refundedCount',
  );
  @override
  late final GeneratedColumn<int> refundedCount = GeneratedColumn<int>(
    'refunded_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentBreakdownJsonMeta =
      const VerificationMeta('paymentBreakdownJson');
  @override
  late final GeneratedColumn<String> paymentBreakdownJson =
      GeneratedColumn<String>(
        'payment_breakdown_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _topProductsJsonMeta = const VerificationMeta(
    'topProductsJson',
  );
  @override
  late final GeneratedColumn<String> topProductsJson = GeneratedColumn<String>(
    'top_products_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountsJsonMeta = const VerificationMeta(
    'discountsJson',
  );
  @override
  late final GeneratedColumn<String> discountsJson = GeneratedColumn<String>(
    'discounts_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _totalDiscountsMeta = const VerificationMeta(
    'totalDiscounts',
  );
  @override
  late final GeneratedColumn<double> totalDiscounts = GeneratedColumn<double>(
    'total_discounts',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _vatableSalesMeta = const VerificationMeta(
    'vatableSales',
  );
  @override
  late final GeneratedColumn<double> vatableSales = GeneratedColumn<double>(
    'vatable_sales',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _vatAmountMeta = const VerificationMeta(
    'vatAmount',
  );
  @override
  late final GeneratedColumn<double> vatAmount = GeneratedColumn<double>(
    'vat_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _vatExemptSalesMeta = const VerificationMeta(
    'vatExemptSales',
  );
  @override
  late final GeneratedColumn<double> vatExemptSales = GeneratedColumn<double>(
    'vat_exempt_sales',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _averageSaleMeta = const VerificationMeta(
    'averageSale',
  );
  @override
  late final GeneratedColumn<double> averageSale = GeneratedColumn<double>(
    'average_sale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _highestSaleMeta = const VerificationMeta(
    'highestSale',
  );
  @override
  late final GeneratedColumn<double> highestSale = GeneratedColumn<double>(
    'highest_sale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _lowestSaleMeta = const VerificationMeta(
    'lowestSale',
  );
  @override
  late final GeneratedColumn<double> lowestSale = GeneratedColumn<double>(
    'lowest_sale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _cashCollectedMeta = const VerificationMeta(
    'cashCollected',
  );
  @override
  late final GeneratedColumn<double> cashCollected = GeneratedColumn<double>(
    'cash_collected',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _paymentLedgersJsonMeta =
      const VerificationMeta('paymentLedgersJson');
  @override
  late final GeneratedColumn<String> paymentLedgersJson =
      GeneratedColumn<String>(
        'payment_ledgers_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cashierId,
    cashierName,
    periodStart,
    periodEnd,
    generatedAt,
    totalSales,
    transactionCount,
    voidedCount,
    refundedCount,
    paymentBreakdownJson,
    topProductsJson,
    discountsJson,
    totalDiscounts,
    vatableSales,
    vatAmount,
    vatExemptSales,
    averageSale,
    highestSale,
    lowestSale,
    cashCollected,
    paymentLedgersJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'x_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<XReadingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('cashier_name')) {
      context.handle(
        _cashierNameMeta,
        cashierName.isAcceptableOrUnknown(
          data['cashier_name']!,
          _cashierNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashierNameMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
        _periodStartMeta,
        periodStart.isAcceptableOrUnknown(
          data['period_start']!,
          _periodStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_end')) {
      context.handle(
        _periodEndMeta,
        periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta),
      );
    } else if (isInserting) {
      context.missing(_periodEndMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('total_sales')) {
      context.handle(
        _totalSalesMeta,
        totalSales.isAcceptableOrUnknown(data['total_sales']!, _totalSalesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSalesMeta);
    }
    if (data.containsKey('transaction_count')) {
      context.handle(
        _transactionCountMeta,
        transactionCount.isAcceptableOrUnknown(
          data['transaction_count']!,
          _transactionCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionCountMeta);
    }
    if (data.containsKey('voided_count')) {
      context.handle(
        _voidedCountMeta,
        voidedCount.isAcceptableOrUnknown(
          data['voided_count']!,
          _voidedCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_voidedCountMeta);
    }
    if (data.containsKey('refunded_count')) {
      context.handle(
        _refundedCountMeta,
        refundedCount.isAcceptableOrUnknown(
          data['refunded_count']!,
          _refundedCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refundedCountMeta);
    }
    if (data.containsKey('payment_breakdown_json')) {
      context.handle(
        _paymentBreakdownJsonMeta,
        paymentBreakdownJson.isAcceptableOrUnknown(
          data['payment_breakdown_json']!,
          _paymentBreakdownJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentBreakdownJsonMeta);
    }
    if (data.containsKey('top_products_json')) {
      context.handle(
        _topProductsJsonMeta,
        topProductsJson.isAcceptableOrUnknown(
          data['top_products_json']!,
          _topProductsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_topProductsJsonMeta);
    }
    if (data.containsKey('discounts_json')) {
      context.handle(
        _discountsJsonMeta,
        discountsJson.isAcceptableOrUnknown(
          data['discounts_json']!,
          _discountsJsonMeta,
        ),
      );
    }
    if (data.containsKey('total_discounts')) {
      context.handle(
        _totalDiscountsMeta,
        totalDiscounts.isAcceptableOrUnknown(
          data['total_discounts']!,
          _totalDiscountsMeta,
        ),
      );
    }
    if (data.containsKey('vatable_sales')) {
      context.handle(
        _vatableSalesMeta,
        vatableSales.isAcceptableOrUnknown(
          data['vatable_sales']!,
          _vatableSalesMeta,
        ),
      );
    }
    if (data.containsKey('vat_amount')) {
      context.handle(
        _vatAmountMeta,
        vatAmount.isAcceptableOrUnknown(data['vat_amount']!, _vatAmountMeta),
      );
    }
    if (data.containsKey('vat_exempt_sales')) {
      context.handle(
        _vatExemptSalesMeta,
        vatExemptSales.isAcceptableOrUnknown(
          data['vat_exempt_sales']!,
          _vatExemptSalesMeta,
        ),
      );
    }
    if (data.containsKey('average_sale')) {
      context.handle(
        _averageSaleMeta,
        averageSale.isAcceptableOrUnknown(
          data['average_sale']!,
          _averageSaleMeta,
        ),
      );
    }
    if (data.containsKey('highest_sale')) {
      context.handle(
        _highestSaleMeta,
        highestSale.isAcceptableOrUnknown(
          data['highest_sale']!,
          _highestSaleMeta,
        ),
      );
    }
    if (data.containsKey('lowest_sale')) {
      context.handle(
        _lowestSaleMeta,
        lowestSale.isAcceptableOrUnknown(data['lowest_sale']!, _lowestSaleMeta),
      );
    }
    if (data.containsKey('cash_collected')) {
      context.handle(
        _cashCollectedMeta,
        cashCollected.isAcceptableOrUnknown(
          data['cash_collected']!,
          _cashCollectedMeta,
        ),
      );
    }
    if (data.containsKey('payment_ledgers_json')) {
      context.handle(
        _paymentLedgersJsonMeta,
        paymentLedgersJson.isAcceptableOrUnknown(
          data['payment_ledgers_json']!,
          _paymentLedgersJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  XReadingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return XReadingsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      cashierId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}cashier_id'],
          )!,
      cashierName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}cashier_name'],
          )!,
      periodStart:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}period_start'],
          )!,
      periodEnd:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}period_end'],
          )!,
      generatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}generated_at'],
          )!,
      totalSales:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}total_sales'],
          )!,
      transactionCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}transaction_count'],
          )!,
      voidedCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}voided_count'],
          )!,
      refundedCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}refunded_count'],
          )!,
      paymentBreakdownJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payment_breakdown_json'],
          )!,
      topProductsJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}top_products_json'],
          )!,
      discountsJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}discounts_json'],
          )!,
      totalDiscounts:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}total_discounts'],
          )!,
      vatableSales:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}vatable_sales'],
          )!,
      vatAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}vat_amount'],
          )!,
      vatExemptSales:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}vat_exempt_sales'],
          )!,
      averageSale:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}average_sale'],
          )!,
      highestSale:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}highest_sale'],
          )!,
      lowestSale:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}lowest_sale'],
          )!,
      cashCollected:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}cash_collected'],
          )!,
      paymentLedgersJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payment_ledgers_json'],
          )!,
    );
  }

  @override
  $XReadingsTableTable createAlias(String alias) {
    return $XReadingsTableTable(attachedDatabase, alias);
  }
}

class XReadingsTableData extends DataClass
    implements Insertable<XReadingsTableData> {
  final int id;
  final int cashierId;
  final String cashierName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime generatedAt;
  final double totalSales;
  final int transactionCount;
  final int voidedCount;
  final int refundedCount;
  final String paymentBreakdownJson;
  final String topProductsJson;
  final String discountsJson;
  final double totalDiscounts;
  final double vatableSales;
  final double vatAmount;
  final double vatExemptSales;
  final double averageSale;
  final double highestSale;
  final double lowestSale;
  final double cashCollected;
  final String paymentLedgersJson;
  const XReadingsTableData({
    required this.id,
    required this.cashierId,
    required this.cashierName,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.totalSales,
    required this.transactionCount,
    required this.voidedCount,
    required this.refundedCount,
    required this.paymentBreakdownJson,
    required this.topProductsJson,
    required this.discountsJson,
    required this.totalDiscounts,
    required this.vatableSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.averageSale,
    required this.highestSale,
    required this.lowestSale,
    required this.cashCollected,
    required this.paymentLedgersJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cashier_id'] = Variable<int>(cashierId);
    map['cashier_name'] = Variable<String>(cashierName);
    map['period_start'] = Variable<DateTime>(periodStart);
    map['period_end'] = Variable<DateTime>(periodEnd);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['total_sales'] = Variable<double>(totalSales);
    map['transaction_count'] = Variable<int>(transactionCount);
    map['voided_count'] = Variable<int>(voidedCount);
    map['refunded_count'] = Variable<int>(refundedCount);
    map['payment_breakdown_json'] = Variable<String>(paymentBreakdownJson);
    map['top_products_json'] = Variable<String>(topProductsJson);
    map['discounts_json'] = Variable<String>(discountsJson);
    map['total_discounts'] = Variable<double>(totalDiscounts);
    map['vatable_sales'] = Variable<double>(vatableSales);
    map['vat_amount'] = Variable<double>(vatAmount);
    map['vat_exempt_sales'] = Variable<double>(vatExemptSales);
    map['average_sale'] = Variable<double>(averageSale);
    map['highest_sale'] = Variable<double>(highestSale);
    map['lowest_sale'] = Variable<double>(lowestSale);
    map['cash_collected'] = Variable<double>(cashCollected);
    map['payment_ledgers_json'] = Variable<String>(paymentLedgersJson);
    return map;
  }

  XReadingsTableCompanion toCompanion(bool nullToAbsent) {
    return XReadingsTableCompanion(
      id: Value(id),
      cashierId: Value(cashierId),
      cashierName: Value(cashierName),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      generatedAt: Value(generatedAt),
      totalSales: Value(totalSales),
      transactionCount: Value(transactionCount),
      voidedCount: Value(voidedCount),
      refundedCount: Value(refundedCount),
      paymentBreakdownJson: Value(paymentBreakdownJson),
      topProductsJson: Value(topProductsJson),
      discountsJson: Value(discountsJson),
      totalDiscounts: Value(totalDiscounts),
      vatableSales: Value(vatableSales),
      vatAmount: Value(vatAmount),
      vatExemptSales: Value(vatExemptSales),
      averageSale: Value(averageSale),
      highestSale: Value(highestSale),
      lowestSale: Value(lowestSale),
      cashCollected: Value(cashCollected),
      paymentLedgersJson: Value(paymentLedgersJson),
    );
  }

  factory XReadingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return XReadingsTableData(
      id: serializer.fromJson<int>(json['id']),
      cashierId: serializer.fromJson<int>(json['cashierId']),
      cashierName: serializer.fromJson<String>(json['cashierName']),
      periodStart: serializer.fromJson<DateTime>(json['periodStart']),
      periodEnd: serializer.fromJson<DateTime>(json['periodEnd']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      totalSales: serializer.fromJson<double>(json['totalSales']),
      transactionCount: serializer.fromJson<int>(json['transactionCount']),
      voidedCount: serializer.fromJson<int>(json['voidedCount']),
      refundedCount: serializer.fromJson<int>(json['refundedCount']),
      paymentBreakdownJson: serializer.fromJson<String>(
        json['paymentBreakdownJson'],
      ),
      topProductsJson: serializer.fromJson<String>(json['topProductsJson']),
      discountsJson: serializer.fromJson<String>(json['discountsJson']),
      totalDiscounts: serializer.fromJson<double>(json['totalDiscounts']),
      vatableSales: serializer.fromJson<double>(json['vatableSales']),
      vatAmount: serializer.fromJson<double>(json['vatAmount']),
      vatExemptSales: serializer.fromJson<double>(json['vatExemptSales']),
      averageSale: serializer.fromJson<double>(json['averageSale']),
      highestSale: serializer.fromJson<double>(json['highestSale']),
      lowestSale: serializer.fromJson<double>(json['lowestSale']),
      cashCollected: serializer.fromJson<double>(json['cashCollected']),
      paymentLedgersJson: serializer.fromJson<String>(
        json['paymentLedgersJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cashierId': serializer.toJson<int>(cashierId),
      'cashierName': serializer.toJson<String>(cashierName),
      'periodStart': serializer.toJson<DateTime>(periodStart),
      'periodEnd': serializer.toJson<DateTime>(periodEnd),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'totalSales': serializer.toJson<double>(totalSales),
      'transactionCount': serializer.toJson<int>(transactionCount),
      'voidedCount': serializer.toJson<int>(voidedCount),
      'refundedCount': serializer.toJson<int>(refundedCount),
      'paymentBreakdownJson': serializer.toJson<String>(paymentBreakdownJson),
      'topProductsJson': serializer.toJson<String>(topProductsJson),
      'discountsJson': serializer.toJson<String>(discountsJson),
      'totalDiscounts': serializer.toJson<double>(totalDiscounts),
      'vatableSales': serializer.toJson<double>(vatableSales),
      'vatAmount': serializer.toJson<double>(vatAmount),
      'vatExemptSales': serializer.toJson<double>(vatExemptSales),
      'averageSale': serializer.toJson<double>(averageSale),
      'highestSale': serializer.toJson<double>(highestSale),
      'lowestSale': serializer.toJson<double>(lowestSale),
      'cashCollected': serializer.toJson<double>(cashCollected),
      'paymentLedgersJson': serializer.toJson<String>(paymentLedgersJson),
    };
  }

  XReadingsTableData copyWith({
    int? id,
    int? cashierId,
    String? cashierName,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? generatedAt,
    double? totalSales,
    int? transactionCount,
    int? voidedCount,
    int? refundedCount,
    String? paymentBreakdownJson,
    String? topProductsJson,
    String? discountsJson,
    double? totalDiscounts,
    double? vatableSales,
    double? vatAmount,
    double? vatExemptSales,
    double? averageSale,
    double? highestSale,
    double? lowestSale,
    double? cashCollected,
    String? paymentLedgersJson,
  }) => XReadingsTableData(
    id: id ?? this.id,
    cashierId: cashierId ?? this.cashierId,
    cashierName: cashierName ?? this.cashierName,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    generatedAt: generatedAt ?? this.generatedAt,
    totalSales: totalSales ?? this.totalSales,
    transactionCount: transactionCount ?? this.transactionCount,
    voidedCount: voidedCount ?? this.voidedCount,
    refundedCount: refundedCount ?? this.refundedCount,
    paymentBreakdownJson: paymentBreakdownJson ?? this.paymentBreakdownJson,
    topProductsJson: topProductsJson ?? this.topProductsJson,
    discountsJson: discountsJson ?? this.discountsJson,
    totalDiscounts: totalDiscounts ?? this.totalDiscounts,
    vatableSales: vatableSales ?? this.vatableSales,
    vatAmount: vatAmount ?? this.vatAmount,
    vatExemptSales: vatExemptSales ?? this.vatExemptSales,
    averageSale: averageSale ?? this.averageSale,
    highestSale: highestSale ?? this.highestSale,
    lowestSale: lowestSale ?? this.lowestSale,
    cashCollected: cashCollected ?? this.cashCollected,
    paymentLedgersJson: paymentLedgersJson ?? this.paymentLedgersJson,
  );
  XReadingsTableData copyWithCompanion(XReadingsTableCompanion data) {
    return XReadingsTableData(
      id: data.id.present ? data.id.value : this.id,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      cashierName:
          data.cashierName.present ? data.cashierName.value : this.cashierName,
      periodStart:
          data.periodStart.present ? data.periodStart.value : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      totalSales:
          data.totalSales.present ? data.totalSales.value : this.totalSales,
      transactionCount:
          data.transactionCount.present
              ? data.transactionCount.value
              : this.transactionCount,
      voidedCount:
          data.voidedCount.present ? data.voidedCount.value : this.voidedCount,
      refundedCount:
          data.refundedCount.present
              ? data.refundedCount.value
              : this.refundedCount,
      paymentBreakdownJson:
          data.paymentBreakdownJson.present
              ? data.paymentBreakdownJson.value
              : this.paymentBreakdownJson,
      topProductsJson:
          data.topProductsJson.present
              ? data.topProductsJson.value
              : this.topProductsJson,
      discountsJson:
          data.discountsJson.present
              ? data.discountsJson.value
              : this.discountsJson,
      totalDiscounts:
          data.totalDiscounts.present
              ? data.totalDiscounts.value
              : this.totalDiscounts,
      vatableSales:
          data.vatableSales.present
              ? data.vatableSales.value
              : this.vatableSales,
      vatAmount: data.vatAmount.present ? data.vatAmount.value : this.vatAmount,
      vatExemptSales:
          data.vatExemptSales.present
              ? data.vatExemptSales.value
              : this.vatExemptSales,
      averageSale:
          data.averageSale.present ? data.averageSale.value : this.averageSale,
      highestSale:
          data.highestSale.present ? data.highestSale.value : this.highestSale,
      lowestSale:
          data.lowestSale.present ? data.lowestSale.value : this.lowestSale,
      cashCollected:
          data.cashCollected.present
              ? data.cashCollected.value
              : this.cashCollected,
      paymentLedgersJson:
          data.paymentLedgersJson.present
              ? data.paymentLedgersJson.value
              : this.paymentLedgersJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('XReadingsTableData(')
          ..write('id: $id, ')
          ..write('cashierId: $cashierId, ')
          ..write('cashierName: $cashierName, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('totalSales: $totalSales, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('voidedCount: $voidedCount, ')
          ..write('refundedCount: $refundedCount, ')
          ..write('paymentBreakdownJson: $paymentBreakdownJson, ')
          ..write('topProductsJson: $topProductsJson, ')
          ..write('discountsJson: $discountsJson, ')
          ..write('totalDiscounts: $totalDiscounts, ')
          ..write('vatableSales: $vatableSales, ')
          ..write('vatAmount: $vatAmount, ')
          ..write('vatExemptSales: $vatExemptSales, ')
          ..write('averageSale: $averageSale, ')
          ..write('highestSale: $highestSale, ')
          ..write('lowestSale: $lowestSale, ')
          ..write('cashCollected: $cashCollected, ')
          ..write('paymentLedgersJson: $paymentLedgersJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    cashierId,
    cashierName,
    periodStart,
    periodEnd,
    generatedAt,
    totalSales,
    transactionCount,
    voidedCount,
    refundedCount,
    paymentBreakdownJson,
    topProductsJson,
    discountsJson,
    totalDiscounts,
    vatableSales,
    vatAmount,
    vatExemptSales,
    averageSale,
    highestSale,
    lowestSale,
    cashCollected,
    paymentLedgersJson,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is XReadingsTableData &&
          other.id == this.id &&
          other.cashierId == this.cashierId &&
          other.cashierName == this.cashierName &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.generatedAt == this.generatedAt &&
          other.totalSales == this.totalSales &&
          other.transactionCount == this.transactionCount &&
          other.voidedCount == this.voidedCount &&
          other.refundedCount == this.refundedCount &&
          other.paymentBreakdownJson == this.paymentBreakdownJson &&
          other.topProductsJson == this.topProductsJson &&
          other.discountsJson == this.discountsJson &&
          other.totalDiscounts == this.totalDiscounts &&
          other.vatableSales == this.vatableSales &&
          other.vatAmount == this.vatAmount &&
          other.vatExemptSales == this.vatExemptSales &&
          other.averageSale == this.averageSale &&
          other.highestSale == this.highestSale &&
          other.lowestSale == this.lowestSale &&
          other.cashCollected == this.cashCollected &&
          other.paymentLedgersJson == this.paymentLedgersJson);
}

class XReadingsTableCompanion extends UpdateCompanion<XReadingsTableData> {
  final Value<int> id;
  final Value<int> cashierId;
  final Value<String> cashierName;
  final Value<DateTime> periodStart;
  final Value<DateTime> periodEnd;
  final Value<DateTime> generatedAt;
  final Value<double> totalSales;
  final Value<int> transactionCount;
  final Value<int> voidedCount;
  final Value<int> refundedCount;
  final Value<String> paymentBreakdownJson;
  final Value<String> topProductsJson;
  final Value<String> discountsJson;
  final Value<double> totalDiscounts;
  final Value<double> vatableSales;
  final Value<double> vatAmount;
  final Value<double> vatExemptSales;
  final Value<double> averageSale;
  final Value<double> highestSale;
  final Value<double> lowestSale;
  final Value<double> cashCollected;
  final Value<String> paymentLedgersJson;
  const XReadingsTableCompanion({
    this.id = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.cashierName = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.totalSales = const Value.absent(),
    this.transactionCount = const Value.absent(),
    this.voidedCount = const Value.absent(),
    this.refundedCount = const Value.absent(),
    this.paymentBreakdownJson = const Value.absent(),
    this.topProductsJson = const Value.absent(),
    this.discountsJson = const Value.absent(),
    this.totalDiscounts = const Value.absent(),
    this.vatableSales = const Value.absent(),
    this.vatAmount = const Value.absent(),
    this.vatExemptSales = const Value.absent(),
    this.averageSale = const Value.absent(),
    this.highestSale = const Value.absent(),
    this.lowestSale = const Value.absent(),
    this.cashCollected = const Value.absent(),
    this.paymentLedgersJson = const Value.absent(),
  });
  XReadingsTableCompanion.insert({
    this.id = const Value.absent(),
    required int cashierId,
    required String cashierName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime generatedAt,
    required double totalSales,
    required int transactionCount,
    required int voidedCount,
    required int refundedCount,
    required String paymentBreakdownJson,
    required String topProductsJson,
    this.discountsJson = const Value.absent(),
    this.totalDiscounts = const Value.absent(),
    this.vatableSales = const Value.absent(),
    this.vatAmount = const Value.absent(),
    this.vatExemptSales = const Value.absent(),
    this.averageSale = const Value.absent(),
    this.highestSale = const Value.absent(),
    this.lowestSale = const Value.absent(),
    this.cashCollected = const Value.absent(),
    this.paymentLedgersJson = const Value.absent(),
  }) : cashierId = Value(cashierId),
       cashierName = Value(cashierName),
       periodStart = Value(periodStart),
       periodEnd = Value(periodEnd),
       generatedAt = Value(generatedAt),
       totalSales = Value(totalSales),
       transactionCount = Value(transactionCount),
       voidedCount = Value(voidedCount),
       refundedCount = Value(refundedCount),
       paymentBreakdownJson = Value(paymentBreakdownJson),
       topProductsJson = Value(topProductsJson);
  static Insertable<XReadingsTableData> custom({
    Expression<int>? id,
    Expression<int>? cashierId,
    Expression<String>? cashierName,
    Expression<DateTime>? periodStart,
    Expression<DateTime>? periodEnd,
    Expression<DateTime>? generatedAt,
    Expression<double>? totalSales,
    Expression<int>? transactionCount,
    Expression<int>? voidedCount,
    Expression<int>? refundedCount,
    Expression<String>? paymentBreakdownJson,
    Expression<String>? topProductsJson,
    Expression<String>? discountsJson,
    Expression<double>? totalDiscounts,
    Expression<double>? vatableSales,
    Expression<double>? vatAmount,
    Expression<double>? vatExemptSales,
    Expression<double>? averageSale,
    Expression<double>? highestSale,
    Expression<double>? lowestSale,
    Expression<double>? cashCollected,
    Expression<String>? paymentLedgersJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cashierId != null) 'cashier_id': cashierId,
      if (cashierName != null) 'cashier_name': cashierName,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (totalSales != null) 'total_sales': totalSales,
      if (transactionCount != null) 'transaction_count': transactionCount,
      if (voidedCount != null) 'voided_count': voidedCount,
      if (refundedCount != null) 'refunded_count': refundedCount,
      if (paymentBreakdownJson != null)
        'payment_breakdown_json': paymentBreakdownJson,
      if (topProductsJson != null) 'top_products_json': topProductsJson,
      if (discountsJson != null) 'discounts_json': discountsJson,
      if (totalDiscounts != null) 'total_discounts': totalDiscounts,
      if (vatableSales != null) 'vatable_sales': vatableSales,
      if (vatAmount != null) 'vat_amount': vatAmount,
      if (vatExemptSales != null) 'vat_exempt_sales': vatExemptSales,
      if (averageSale != null) 'average_sale': averageSale,
      if (highestSale != null) 'highest_sale': highestSale,
      if (lowestSale != null) 'lowest_sale': lowestSale,
      if (cashCollected != null) 'cash_collected': cashCollected,
      if (paymentLedgersJson != null)
        'payment_ledgers_json': paymentLedgersJson,
    });
  }

  XReadingsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? cashierId,
    Value<String>? cashierName,
    Value<DateTime>? periodStart,
    Value<DateTime>? periodEnd,
    Value<DateTime>? generatedAt,
    Value<double>? totalSales,
    Value<int>? transactionCount,
    Value<int>? voidedCount,
    Value<int>? refundedCount,
    Value<String>? paymentBreakdownJson,
    Value<String>? topProductsJson,
    Value<String>? discountsJson,
    Value<double>? totalDiscounts,
    Value<double>? vatableSales,
    Value<double>? vatAmount,
    Value<double>? vatExemptSales,
    Value<double>? averageSale,
    Value<double>? highestSale,
    Value<double>? lowestSale,
    Value<double>? cashCollected,
    Value<String>? paymentLedgersJson,
  }) {
    return XReadingsTableCompanion(
      id: id ?? this.id,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      generatedAt: generatedAt ?? this.generatedAt,
      totalSales: totalSales ?? this.totalSales,
      transactionCount: transactionCount ?? this.transactionCount,
      voidedCount: voidedCount ?? this.voidedCount,
      refundedCount: refundedCount ?? this.refundedCount,
      paymentBreakdownJson: paymentBreakdownJson ?? this.paymentBreakdownJson,
      topProductsJson: topProductsJson ?? this.topProductsJson,
      discountsJson: discountsJson ?? this.discountsJson,
      totalDiscounts: totalDiscounts ?? this.totalDiscounts,
      vatableSales: vatableSales ?? this.vatableSales,
      vatAmount: vatAmount ?? this.vatAmount,
      vatExemptSales: vatExemptSales ?? this.vatExemptSales,
      averageSale: averageSale ?? this.averageSale,
      highestSale: highestSale ?? this.highestSale,
      lowestSale: lowestSale ?? this.lowestSale,
      cashCollected: cashCollected ?? this.cashCollected,
      paymentLedgersJson: paymentLedgersJson ?? this.paymentLedgersJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<int>(cashierId.value);
    }
    if (cashierName.present) {
      map['cashier_name'] = Variable<String>(cashierName.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<DateTime>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<DateTime>(periodEnd.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (totalSales.present) {
      map['total_sales'] = Variable<double>(totalSales.value);
    }
    if (transactionCount.present) {
      map['transaction_count'] = Variable<int>(transactionCount.value);
    }
    if (voidedCount.present) {
      map['voided_count'] = Variable<int>(voidedCount.value);
    }
    if (refundedCount.present) {
      map['refunded_count'] = Variable<int>(refundedCount.value);
    }
    if (paymentBreakdownJson.present) {
      map['payment_breakdown_json'] = Variable<String>(
        paymentBreakdownJson.value,
      );
    }
    if (topProductsJson.present) {
      map['top_products_json'] = Variable<String>(topProductsJson.value);
    }
    if (discountsJson.present) {
      map['discounts_json'] = Variable<String>(discountsJson.value);
    }
    if (totalDiscounts.present) {
      map['total_discounts'] = Variable<double>(totalDiscounts.value);
    }
    if (vatableSales.present) {
      map['vatable_sales'] = Variable<double>(vatableSales.value);
    }
    if (vatAmount.present) {
      map['vat_amount'] = Variable<double>(vatAmount.value);
    }
    if (vatExemptSales.present) {
      map['vat_exempt_sales'] = Variable<double>(vatExemptSales.value);
    }
    if (averageSale.present) {
      map['average_sale'] = Variable<double>(averageSale.value);
    }
    if (highestSale.present) {
      map['highest_sale'] = Variable<double>(highestSale.value);
    }
    if (lowestSale.present) {
      map['lowest_sale'] = Variable<double>(lowestSale.value);
    }
    if (cashCollected.present) {
      map['cash_collected'] = Variable<double>(cashCollected.value);
    }
    if (paymentLedgersJson.present) {
      map['payment_ledgers_json'] = Variable<String>(paymentLedgersJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('XReadingsTableCompanion(')
          ..write('id: $id, ')
          ..write('cashierId: $cashierId, ')
          ..write('cashierName: $cashierName, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('totalSales: $totalSales, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('voidedCount: $voidedCount, ')
          ..write('refundedCount: $refundedCount, ')
          ..write('paymentBreakdownJson: $paymentBreakdownJson, ')
          ..write('topProductsJson: $topProductsJson, ')
          ..write('discountsJson: $discountsJson, ')
          ..write('totalDiscounts: $totalDiscounts, ')
          ..write('vatableSales: $vatableSales, ')
          ..write('vatAmount: $vatAmount, ')
          ..write('vatExemptSales: $vatExemptSales, ')
          ..write('averageSale: $averageSale, ')
          ..write('highestSale: $highestSale, ')
          ..write('lowestSale: $lowestSale, ')
          ..write('cashCollected: $cashCollected, ')
          ..write('paymentLedgersJson: $paymentLedgersJson')
          ..write(')'))
        .toString();
  }
}

class $DailyReportsTableTable extends DailyReportsTable
    with TableInfo<$DailyReportsTableTable, DailyReportsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyReportsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<int> cashierId = GeneratedColumn<int>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashierNameMeta = const VerificationMeta(
    'cashierName',
  );
  @override
  late final GeneratedColumn<String> cashierName = GeneratedColumn<String>(
    'cashier_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta(
    'periodStart',
  );
  @override
  late final GeneratedColumn<DateTime> periodStart = GeneratedColumn<DateTime>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodEndMeta = const VerificationMeta(
    'periodEnd',
  );
  @override
  late final GeneratedColumn<DateTime> periodEnd = GeneratedColumn<DateTime>(
    'period_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grossSalesMeta = const VerificationMeta(
    'grossSales',
  );
  @override
  late final GeneratedColumn<double> grossSales = GeneratedColumn<double>(
    'gross_sales',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatableSalesMeta = const VerificationMeta(
    'vatableSales',
  );
  @override
  late final GeneratedColumn<double> vatableSales = GeneratedColumn<double>(
    'vatable_sales',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatAmountMeta = const VerificationMeta(
    'vatAmount',
  );
  @override
  late final GeneratedColumn<double> vatAmount = GeneratedColumn<double>(
    'vat_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatExemptSalesMeta = const VerificationMeta(
    'vatExemptSales',
  );
  @override
  late final GeneratedColumn<double> vatExemptSales = GeneratedColumn<double>(
    'vat_exempt_sales',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _netOfTaxMeta = const VerificationMeta(
    'netOfTax',
  );
  @override
  late final GeneratedColumn<double> netOfTax = GeneratedColumn<double>(
    'net_of_tax',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionCountMeta = const VerificationMeta(
    'transactionCount',
  );
  @override
  late final GeneratedColumn<int> transactionCount = GeneratedColumn<int>(
    'transaction_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalQtySoldMeta = const VerificationMeta(
    'totalQtySold',
  );
  @override
  late final GeneratedColumn<int> totalQtySold = GeneratedColumn<int>(
    'total_qty_sold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashSalesTotalMeta = const VerificationMeta(
    'cashSalesTotal',
  );
  @override
  late final GeneratedColumn<double> cashSalesTotal = GeneratedColumn<double>(
    'cash_sales_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashSalesCountMeta = const VerificationMeta(
    'cashSalesCount',
  );
  @override
  late final GeneratedColumn<int> cashSalesCount = GeneratedColumn<int>(
    'cash_sales_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salesByProductJsonMeta =
      const VerificationMeta('salesByProductJson');
  @override
  late final GeneratedColumn<String> salesByProductJson =
      GeneratedColumn<String>(
        'sales_by_product_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cashLedgerJsonMeta = const VerificationMeta(
    'cashLedgerJson',
  );
  @override
  late final GeneratedColumn<String> cashLedgerJson = GeneratedColumn<String>(
    'cash_ledger_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cashierId,
    cashierName,
    periodStart,
    periodEnd,
    generatedAt,
    grossSales,
    vatableSales,
    vatAmount,
    vatExemptSales,
    netOfTax,
    transactionCount,
    totalQtySold,
    cashSalesTotal,
    cashSalesCount,
    salesByProductJson,
    cashLedgerJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyReportsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('cashier_name')) {
      context.handle(
        _cashierNameMeta,
        cashierName.isAcceptableOrUnknown(
          data['cashier_name']!,
          _cashierNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashierNameMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
        _periodStartMeta,
        periodStart.isAcceptableOrUnknown(
          data['period_start']!,
          _periodStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_end')) {
      context.handle(
        _periodEndMeta,
        periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta),
      );
    } else if (isInserting) {
      context.missing(_periodEndMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('gross_sales')) {
      context.handle(
        _grossSalesMeta,
        grossSales.isAcceptableOrUnknown(data['gross_sales']!, _grossSalesMeta),
      );
    } else if (isInserting) {
      context.missing(_grossSalesMeta);
    }
    if (data.containsKey('vatable_sales')) {
      context.handle(
        _vatableSalesMeta,
        vatableSales.isAcceptableOrUnknown(
          data['vatable_sales']!,
          _vatableSalesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vatableSalesMeta);
    }
    if (data.containsKey('vat_amount')) {
      context.handle(
        _vatAmountMeta,
        vatAmount.isAcceptableOrUnknown(data['vat_amount']!, _vatAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_vatAmountMeta);
    }
    if (data.containsKey('vat_exempt_sales')) {
      context.handle(
        _vatExemptSalesMeta,
        vatExemptSales.isAcceptableOrUnknown(
          data['vat_exempt_sales']!,
          _vatExemptSalesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vatExemptSalesMeta);
    }
    if (data.containsKey('net_of_tax')) {
      context.handle(
        _netOfTaxMeta,
        netOfTax.isAcceptableOrUnknown(data['net_of_tax']!, _netOfTaxMeta),
      );
    } else if (isInserting) {
      context.missing(_netOfTaxMeta);
    }
    if (data.containsKey('transaction_count')) {
      context.handle(
        _transactionCountMeta,
        transactionCount.isAcceptableOrUnknown(
          data['transaction_count']!,
          _transactionCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionCountMeta);
    }
    if (data.containsKey('total_qty_sold')) {
      context.handle(
        _totalQtySoldMeta,
        totalQtySold.isAcceptableOrUnknown(
          data['total_qty_sold']!,
          _totalQtySoldMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalQtySoldMeta);
    }
    if (data.containsKey('cash_sales_total')) {
      context.handle(
        _cashSalesTotalMeta,
        cashSalesTotal.isAcceptableOrUnknown(
          data['cash_sales_total']!,
          _cashSalesTotalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashSalesTotalMeta);
    }
    if (data.containsKey('cash_sales_count')) {
      context.handle(
        _cashSalesCountMeta,
        cashSalesCount.isAcceptableOrUnknown(
          data['cash_sales_count']!,
          _cashSalesCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashSalesCountMeta);
    }
    if (data.containsKey('sales_by_product_json')) {
      context.handle(
        _salesByProductJsonMeta,
        salesByProductJson.isAcceptableOrUnknown(
          data['sales_by_product_json']!,
          _salesByProductJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_salesByProductJsonMeta);
    }
    if (data.containsKey('cash_ledger_json')) {
      context.handle(
        _cashLedgerJsonMeta,
        cashLedgerJson.isAcceptableOrUnknown(
          data['cash_ledger_json']!,
          _cashLedgerJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashLedgerJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyReportsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyReportsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      cashierId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}cashier_id'],
          )!,
      cashierName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}cashier_name'],
          )!,
      periodStart:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}period_start'],
          )!,
      periodEnd:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}period_end'],
          )!,
      generatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}generated_at'],
          )!,
      grossSales:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}gross_sales'],
          )!,
      vatableSales:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}vatable_sales'],
          )!,
      vatAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}vat_amount'],
          )!,
      vatExemptSales:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}vat_exempt_sales'],
          )!,
      netOfTax:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}net_of_tax'],
          )!,
      transactionCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}transaction_count'],
          )!,
      totalQtySold:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total_qty_sold'],
          )!,
      cashSalesTotal:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}cash_sales_total'],
          )!,
      cashSalesCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}cash_sales_count'],
          )!,
      salesByProductJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sales_by_product_json'],
          )!,
      cashLedgerJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}cash_ledger_json'],
          )!,
    );
  }

  @override
  $DailyReportsTableTable createAlias(String alias) {
    return $DailyReportsTableTable(attachedDatabase, alias);
  }
}

class DailyReportsTableData extends DataClass
    implements Insertable<DailyReportsTableData> {
  final int id;
  final int cashierId;
  final String cashierName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime generatedAt;
  final double grossSales;
  final double vatableSales;
  final double vatAmount;
  final double vatExemptSales;
  final double netOfTax;
  final int transactionCount;
  final int totalQtySold;
  final double cashSalesTotal;
  final int cashSalesCount;
  final String salesByProductJson;
  final String cashLedgerJson;
  const DailyReportsTableData({
    required this.id,
    required this.cashierId,
    required this.cashierName,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.grossSales,
    required this.vatableSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.netOfTax,
    required this.transactionCount,
    required this.totalQtySold,
    required this.cashSalesTotal,
    required this.cashSalesCount,
    required this.salesByProductJson,
    required this.cashLedgerJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cashier_id'] = Variable<int>(cashierId);
    map['cashier_name'] = Variable<String>(cashierName);
    map['period_start'] = Variable<DateTime>(periodStart);
    map['period_end'] = Variable<DateTime>(periodEnd);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['gross_sales'] = Variable<double>(grossSales);
    map['vatable_sales'] = Variable<double>(vatableSales);
    map['vat_amount'] = Variable<double>(vatAmount);
    map['vat_exempt_sales'] = Variable<double>(vatExemptSales);
    map['net_of_tax'] = Variable<double>(netOfTax);
    map['transaction_count'] = Variable<int>(transactionCount);
    map['total_qty_sold'] = Variable<int>(totalQtySold);
    map['cash_sales_total'] = Variable<double>(cashSalesTotal);
    map['cash_sales_count'] = Variable<int>(cashSalesCount);
    map['sales_by_product_json'] = Variable<String>(salesByProductJson);
    map['cash_ledger_json'] = Variable<String>(cashLedgerJson);
    return map;
  }

  DailyReportsTableCompanion toCompanion(bool nullToAbsent) {
    return DailyReportsTableCompanion(
      id: Value(id),
      cashierId: Value(cashierId),
      cashierName: Value(cashierName),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      generatedAt: Value(generatedAt),
      grossSales: Value(grossSales),
      vatableSales: Value(vatableSales),
      vatAmount: Value(vatAmount),
      vatExemptSales: Value(vatExemptSales),
      netOfTax: Value(netOfTax),
      transactionCount: Value(transactionCount),
      totalQtySold: Value(totalQtySold),
      cashSalesTotal: Value(cashSalesTotal),
      cashSalesCount: Value(cashSalesCount),
      salesByProductJson: Value(salesByProductJson),
      cashLedgerJson: Value(cashLedgerJson),
    );
  }

  factory DailyReportsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyReportsTableData(
      id: serializer.fromJson<int>(json['id']),
      cashierId: serializer.fromJson<int>(json['cashierId']),
      cashierName: serializer.fromJson<String>(json['cashierName']),
      periodStart: serializer.fromJson<DateTime>(json['periodStart']),
      periodEnd: serializer.fromJson<DateTime>(json['periodEnd']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      grossSales: serializer.fromJson<double>(json['grossSales']),
      vatableSales: serializer.fromJson<double>(json['vatableSales']),
      vatAmount: serializer.fromJson<double>(json['vatAmount']),
      vatExemptSales: serializer.fromJson<double>(json['vatExemptSales']),
      netOfTax: serializer.fromJson<double>(json['netOfTax']),
      transactionCount: serializer.fromJson<int>(json['transactionCount']),
      totalQtySold: serializer.fromJson<int>(json['totalQtySold']),
      cashSalesTotal: serializer.fromJson<double>(json['cashSalesTotal']),
      cashSalesCount: serializer.fromJson<int>(json['cashSalesCount']),
      salesByProductJson: serializer.fromJson<String>(
        json['salesByProductJson'],
      ),
      cashLedgerJson: serializer.fromJson<String>(json['cashLedgerJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cashierId': serializer.toJson<int>(cashierId),
      'cashierName': serializer.toJson<String>(cashierName),
      'periodStart': serializer.toJson<DateTime>(periodStart),
      'periodEnd': serializer.toJson<DateTime>(periodEnd),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'grossSales': serializer.toJson<double>(grossSales),
      'vatableSales': serializer.toJson<double>(vatableSales),
      'vatAmount': serializer.toJson<double>(vatAmount),
      'vatExemptSales': serializer.toJson<double>(vatExemptSales),
      'netOfTax': serializer.toJson<double>(netOfTax),
      'transactionCount': serializer.toJson<int>(transactionCount),
      'totalQtySold': serializer.toJson<int>(totalQtySold),
      'cashSalesTotal': serializer.toJson<double>(cashSalesTotal),
      'cashSalesCount': serializer.toJson<int>(cashSalesCount),
      'salesByProductJson': serializer.toJson<String>(salesByProductJson),
      'cashLedgerJson': serializer.toJson<String>(cashLedgerJson),
    };
  }

  DailyReportsTableData copyWith({
    int? id,
    int? cashierId,
    String? cashierName,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? generatedAt,
    double? grossSales,
    double? vatableSales,
    double? vatAmount,
    double? vatExemptSales,
    double? netOfTax,
    int? transactionCount,
    int? totalQtySold,
    double? cashSalesTotal,
    int? cashSalesCount,
    String? salesByProductJson,
    String? cashLedgerJson,
  }) => DailyReportsTableData(
    id: id ?? this.id,
    cashierId: cashierId ?? this.cashierId,
    cashierName: cashierName ?? this.cashierName,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    generatedAt: generatedAt ?? this.generatedAt,
    grossSales: grossSales ?? this.grossSales,
    vatableSales: vatableSales ?? this.vatableSales,
    vatAmount: vatAmount ?? this.vatAmount,
    vatExemptSales: vatExemptSales ?? this.vatExemptSales,
    netOfTax: netOfTax ?? this.netOfTax,
    transactionCount: transactionCount ?? this.transactionCount,
    totalQtySold: totalQtySold ?? this.totalQtySold,
    cashSalesTotal: cashSalesTotal ?? this.cashSalesTotal,
    cashSalesCount: cashSalesCount ?? this.cashSalesCount,
    salesByProductJson: salesByProductJson ?? this.salesByProductJson,
    cashLedgerJson: cashLedgerJson ?? this.cashLedgerJson,
  );
  DailyReportsTableData copyWithCompanion(DailyReportsTableCompanion data) {
    return DailyReportsTableData(
      id: data.id.present ? data.id.value : this.id,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      cashierName:
          data.cashierName.present ? data.cashierName.value : this.cashierName,
      periodStart:
          data.periodStart.present ? data.periodStart.value : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      grossSales:
          data.grossSales.present ? data.grossSales.value : this.grossSales,
      vatableSales:
          data.vatableSales.present
              ? data.vatableSales.value
              : this.vatableSales,
      vatAmount: data.vatAmount.present ? data.vatAmount.value : this.vatAmount,
      vatExemptSales:
          data.vatExemptSales.present
              ? data.vatExemptSales.value
              : this.vatExemptSales,
      netOfTax: data.netOfTax.present ? data.netOfTax.value : this.netOfTax,
      transactionCount:
          data.transactionCount.present
              ? data.transactionCount.value
              : this.transactionCount,
      totalQtySold:
          data.totalQtySold.present
              ? data.totalQtySold.value
              : this.totalQtySold,
      cashSalesTotal:
          data.cashSalesTotal.present
              ? data.cashSalesTotal.value
              : this.cashSalesTotal,
      cashSalesCount:
          data.cashSalesCount.present
              ? data.cashSalesCount.value
              : this.cashSalesCount,
      salesByProductJson:
          data.salesByProductJson.present
              ? data.salesByProductJson.value
              : this.salesByProductJson,
      cashLedgerJson:
          data.cashLedgerJson.present
              ? data.cashLedgerJson.value
              : this.cashLedgerJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyReportsTableData(')
          ..write('id: $id, ')
          ..write('cashierId: $cashierId, ')
          ..write('cashierName: $cashierName, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('grossSales: $grossSales, ')
          ..write('vatableSales: $vatableSales, ')
          ..write('vatAmount: $vatAmount, ')
          ..write('vatExemptSales: $vatExemptSales, ')
          ..write('netOfTax: $netOfTax, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('totalQtySold: $totalQtySold, ')
          ..write('cashSalesTotal: $cashSalesTotal, ')
          ..write('cashSalesCount: $cashSalesCount, ')
          ..write('salesByProductJson: $salesByProductJson, ')
          ..write('cashLedgerJson: $cashLedgerJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cashierId,
    cashierName,
    periodStart,
    periodEnd,
    generatedAt,
    grossSales,
    vatableSales,
    vatAmount,
    vatExemptSales,
    netOfTax,
    transactionCount,
    totalQtySold,
    cashSalesTotal,
    cashSalesCount,
    salesByProductJson,
    cashLedgerJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyReportsTableData &&
          other.id == this.id &&
          other.cashierId == this.cashierId &&
          other.cashierName == this.cashierName &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.generatedAt == this.generatedAt &&
          other.grossSales == this.grossSales &&
          other.vatableSales == this.vatableSales &&
          other.vatAmount == this.vatAmount &&
          other.vatExemptSales == this.vatExemptSales &&
          other.netOfTax == this.netOfTax &&
          other.transactionCount == this.transactionCount &&
          other.totalQtySold == this.totalQtySold &&
          other.cashSalesTotal == this.cashSalesTotal &&
          other.cashSalesCount == this.cashSalesCount &&
          other.salesByProductJson == this.salesByProductJson &&
          other.cashLedgerJson == this.cashLedgerJson);
}

class DailyReportsTableCompanion
    extends UpdateCompanion<DailyReportsTableData> {
  final Value<int> id;
  final Value<int> cashierId;
  final Value<String> cashierName;
  final Value<DateTime> periodStart;
  final Value<DateTime> periodEnd;
  final Value<DateTime> generatedAt;
  final Value<double> grossSales;
  final Value<double> vatableSales;
  final Value<double> vatAmount;
  final Value<double> vatExemptSales;
  final Value<double> netOfTax;
  final Value<int> transactionCount;
  final Value<int> totalQtySold;
  final Value<double> cashSalesTotal;
  final Value<int> cashSalesCount;
  final Value<String> salesByProductJson;
  final Value<String> cashLedgerJson;
  const DailyReportsTableCompanion({
    this.id = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.cashierName = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.grossSales = const Value.absent(),
    this.vatableSales = const Value.absent(),
    this.vatAmount = const Value.absent(),
    this.vatExemptSales = const Value.absent(),
    this.netOfTax = const Value.absent(),
    this.transactionCount = const Value.absent(),
    this.totalQtySold = const Value.absent(),
    this.cashSalesTotal = const Value.absent(),
    this.cashSalesCount = const Value.absent(),
    this.salesByProductJson = const Value.absent(),
    this.cashLedgerJson = const Value.absent(),
  });
  DailyReportsTableCompanion.insert({
    this.id = const Value.absent(),
    required int cashierId,
    required String cashierName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime generatedAt,
    required double grossSales,
    required double vatableSales,
    required double vatAmount,
    required double vatExemptSales,
    required double netOfTax,
    required int transactionCount,
    required int totalQtySold,
    required double cashSalesTotal,
    required int cashSalesCount,
    required String salesByProductJson,
    required String cashLedgerJson,
  }) : cashierId = Value(cashierId),
       cashierName = Value(cashierName),
       periodStart = Value(periodStart),
       periodEnd = Value(periodEnd),
       generatedAt = Value(generatedAt),
       grossSales = Value(grossSales),
       vatableSales = Value(vatableSales),
       vatAmount = Value(vatAmount),
       vatExemptSales = Value(vatExemptSales),
       netOfTax = Value(netOfTax),
       transactionCount = Value(transactionCount),
       totalQtySold = Value(totalQtySold),
       cashSalesTotal = Value(cashSalesTotal),
       cashSalesCount = Value(cashSalesCount),
       salesByProductJson = Value(salesByProductJson),
       cashLedgerJson = Value(cashLedgerJson);
  static Insertable<DailyReportsTableData> custom({
    Expression<int>? id,
    Expression<int>? cashierId,
    Expression<String>? cashierName,
    Expression<DateTime>? periodStart,
    Expression<DateTime>? periodEnd,
    Expression<DateTime>? generatedAt,
    Expression<double>? grossSales,
    Expression<double>? vatableSales,
    Expression<double>? vatAmount,
    Expression<double>? vatExemptSales,
    Expression<double>? netOfTax,
    Expression<int>? transactionCount,
    Expression<int>? totalQtySold,
    Expression<double>? cashSalesTotal,
    Expression<int>? cashSalesCount,
    Expression<String>? salesByProductJson,
    Expression<String>? cashLedgerJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cashierId != null) 'cashier_id': cashierId,
      if (cashierName != null) 'cashier_name': cashierName,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (grossSales != null) 'gross_sales': grossSales,
      if (vatableSales != null) 'vatable_sales': vatableSales,
      if (vatAmount != null) 'vat_amount': vatAmount,
      if (vatExemptSales != null) 'vat_exempt_sales': vatExemptSales,
      if (netOfTax != null) 'net_of_tax': netOfTax,
      if (transactionCount != null) 'transaction_count': transactionCount,
      if (totalQtySold != null) 'total_qty_sold': totalQtySold,
      if (cashSalesTotal != null) 'cash_sales_total': cashSalesTotal,
      if (cashSalesCount != null) 'cash_sales_count': cashSalesCount,
      if (salesByProductJson != null)
        'sales_by_product_json': salesByProductJson,
      if (cashLedgerJson != null) 'cash_ledger_json': cashLedgerJson,
    });
  }

  DailyReportsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? cashierId,
    Value<String>? cashierName,
    Value<DateTime>? periodStart,
    Value<DateTime>? periodEnd,
    Value<DateTime>? generatedAt,
    Value<double>? grossSales,
    Value<double>? vatableSales,
    Value<double>? vatAmount,
    Value<double>? vatExemptSales,
    Value<double>? netOfTax,
    Value<int>? transactionCount,
    Value<int>? totalQtySold,
    Value<double>? cashSalesTotal,
    Value<int>? cashSalesCount,
    Value<String>? salesByProductJson,
    Value<String>? cashLedgerJson,
  }) {
    return DailyReportsTableCompanion(
      id: id ?? this.id,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      generatedAt: generatedAt ?? this.generatedAt,
      grossSales: grossSales ?? this.grossSales,
      vatableSales: vatableSales ?? this.vatableSales,
      vatAmount: vatAmount ?? this.vatAmount,
      vatExemptSales: vatExemptSales ?? this.vatExemptSales,
      netOfTax: netOfTax ?? this.netOfTax,
      transactionCount: transactionCount ?? this.transactionCount,
      totalQtySold: totalQtySold ?? this.totalQtySold,
      cashSalesTotal: cashSalesTotal ?? this.cashSalesTotal,
      cashSalesCount: cashSalesCount ?? this.cashSalesCount,
      salesByProductJson: salesByProductJson ?? this.salesByProductJson,
      cashLedgerJson: cashLedgerJson ?? this.cashLedgerJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<int>(cashierId.value);
    }
    if (cashierName.present) {
      map['cashier_name'] = Variable<String>(cashierName.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<DateTime>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<DateTime>(periodEnd.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (grossSales.present) {
      map['gross_sales'] = Variable<double>(grossSales.value);
    }
    if (vatableSales.present) {
      map['vatable_sales'] = Variable<double>(vatableSales.value);
    }
    if (vatAmount.present) {
      map['vat_amount'] = Variable<double>(vatAmount.value);
    }
    if (vatExemptSales.present) {
      map['vat_exempt_sales'] = Variable<double>(vatExemptSales.value);
    }
    if (netOfTax.present) {
      map['net_of_tax'] = Variable<double>(netOfTax.value);
    }
    if (transactionCount.present) {
      map['transaction_count'] = Variable<int>(transactionCount.value);
    }
    if (totalQtySold.present) {
      map['total_qty_sold'] = Variable<int>(totalQtySold.value);
    }
    if (cashSalesTotal.present) {
      map['cash_sales_total'] = Variable<double>(cashSalesTotal.value);
    }
    if (cashSalesCount.present) {
      map['cash_sales_count'] = Variable<int>(cashSalesCount.value);
    }
    if (salesByProductJson.present) {
      map['sales_by_product_json'] = Variable<String>(salesByProductJson.value);
    }
    if (cashLedgerJson.present) {
      map['cash_ledger_json'] = Variable<String>(cashLedgerJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyReportsTableCompanion(')
          ..write('id: $id, ')
          ..write('cashierId: $cashierId, ')
          ..write('cashierName: $cashierName, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('grossSales: $grossSales, ')
          ..write('vatableSales: $vatableSales, ')
          ..write('vatAmount: $vatAmount, ')
          ..write('vatExemptSales: $vatExemptSales, ')
          ..write('netOfTax: $netOfTax, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('totalQtySold: $totalQtySold, ')
          ..write('cashSalesTotal: $cashSalesTotal, ')
          ..write('cashSalesCount: $cashSalesCount, ')
          ..write('salesByProductJson: $salesByProductJson, ')
          ..write('cashLedgerJson: $cashLedgerJson')
          ..write(')'))
        .toString();
  }
}

class $ZReadingsTableTable extends ZReadingsTable
    with TableInfo<$ZReadingsTableTable, ZReadingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ZReadingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _zCounterMeta = const VerificationMeta(
    'zCounter',
  );
  @override
  late final GeneratedColumn<int> zCounter = GeneratedColumn<int>(
    'z_counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta(
    'periodStart',
  );
  @override
  late final GeneratedColumn<DateTime> periodStart = GeneratedColumn<DateTime>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodEndMeta = const VerificationMeta(
    'periodEnd',
  );
  @override
  late final GeneratedColumn<DateTime> periodEnd = GeneratedColumn<DateTime>(
    'period_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedByUserIdMeta = const VerificationMeta(
    'closedByUserId',
  );
  @override
  late final GeneratedColumn<int> closedByUserId = GeneratedColumn<int>(
    'closed_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedByNameMeta = const VerificationMeta(
    'closedByName',
  );
  @override
  late final GeneratedColumn<String> closedByName = GeneratedColumn<String>(
    'closed_by_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorizedByUserIdMeta =
      const VerificationMeta('authorizedByUserId');
  @override
  late final GeneratedColumn<int> authorizedByUserId = GeneratedColumn<int>(
    'authorized_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorizedByNameMeta = const VerificationMeta(
    'authorizedByName',
  );
  @override
  late final GeneratedColumn<String> authorizedByName = GeneratedColumn<String>(
    'authorized_by_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beginningBalanceMeta = const VerificationMeta(
    'beginningBalance',
  );
  @override
  late final GeneratedColumn<double> beginningBalance = GeneratedColumn<double>(
    'beginning_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endingBalanceMeta = const VerificationMeta(
    'endingBalance',
  );
  @override
  late final GeneratedColumn<double> endingBalance = GeneratedColumn<double>(
    'ending_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSalesMeta = const VerificationMeta(
    'totalSales',
  );
  @override
  late final GeneratedColumn<double> totalSales = GeneratedColumn<double>(
    'total_sales',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatableSalesMeta = const VerificationMeta(
    'vatableSales',
  );
  @override
  late final GeneratedColumn<double> vatableSales = GeneratedColumn<double>(
    'vatable_sales',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatAmountMeta = const VerificationMeta(
    'vatAmount',
  );
  @override
  late final GeneratedColumn<double> vatAmount = GeneratedColumn<double>(
    'vat_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatExemptSalesMeta = const VerificationMeta(
    'vatExemptSales',
  );
  @override
  late final GeneratedColumn<double> vatExemptSales = GeneratedColumn<double>(
    'vat_exempt_sales',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionCountMeta = const VerificationMeta(
    'transactionCount',
  );
  @override
  late final GeneratedColumn<int> transactionCount = GeneratedColumn<int>(
    'transaction_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedCountMeta = const VerificationMeta(
    'completedCount',
  );
  @override
  late final GeneratedColumn<int> completedCount = GeneratedColumn<int>(
    'completed_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voidedCountMeta = const VerificationMeta(
    'voidedCount',
  );
  @override
  late final GeneratedColumn<int> voidedCount = GeneratedColumn<int>(
    'voided_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refundedCountMeta = const VerificationMeta(
    'refundedCount',
  );
  @override
  late final GeneratedColumn<int> refundedCount = GeneratedColumn<int>(
    'refunded_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountTotalMeta = const VerificationMeta(
    'discountTotal',
  );
  @override
  late final GeneratedColumn<double> discountTotal = GeneratedColumn<double>(
    'discount_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashCollectedMeta = const VerificationMeta(
    'cashCollected',
  );
  @override
  late final GeneratedColumn<double> cashCollected = GeneratedColumn<double>(
    'cash_collected',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalQtySoldMeta = const VerificationMeta(
    'totalQtySold',
  );
  @override
  late final GeneratedColumn<int> totalQtySold = GeneratedColumn<int>(
    'total_qty_sold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentBreakdownJsonMeta =
      const VerificationMeta('paymentBreakdownJson');
  @override
  late final GeneratedColumn<String> paymentBreakdownJson =
      GeneratedColumn<String>(
        'payment_breakdown_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _salesByCashierJsonMeta =
      const VerificationMeta('salesByCashierJson');
  @override
  late final GeneratedColumn<String> salesByCashierJson =
      GeneratedColumn<String>(
        'sales_by_cashier_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _discountsJsonMeta = const VerificationMeta(
    'discountsJson',
  );
  @override
  late final GeneratedColumn<String> discountsJson = GeneratedColumn<String>(
    'discounts_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _paymentLedgersJsonMeta =
      const VerificationMeta('paymentLedgersJson');
  @override
  late final GeneratedColumn<String> paymentLedgersJson =
      GeneratedColumn<String>(
        'payment_ledgers_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    zCounter,
    periodStart,
    periodEnd,
    generatedAt,
    closedByUserId,
    closedByName,
    authorizedByUserId,
    authorizedByName,
    beginningBalance,
    endingBalance,
    totalSales,
    vatableSales,
    vatAmount,
    vatExemptSales,
    transactionCount,
    completedCount,
    voidedCount,
    refundedCount,
    discountTotal,
    cashCollected,
    totalQtySold,
    paymentBreakdownJson,
    salesByCashierJson,
    discountsJson,
    paymentLedgersJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'z_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ZReadingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('z_counter')) {
      context.handle(
        _zCounterMeta,
        zCounter.isAcceptableOrUnknown(data['z_counter']!, _zCounterMeta),
      );
    } else if (isInserting) {
      context.missing(_zCounterMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
        _periodStartMeta,
        periodStart.isAcceptableOrUnknown(
          data['period_start']!,
          _periodStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_end')) {
      context.handle(
        _periodEndMeta,
        periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta),
      );
    } else if (isInserting) {
      context.missing(_periodEndMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('closed_by_user_id')) {
      context.handle(
        _closedByUserIdMeta,
        closedByUserId.isAcceptableOrUnknown(
          data['closed_by_user_id']!,
          _closedByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_closedByUserIdMeta);
    }
    if (data.containsKey('closed_by_name')) {
      context.handle(
        _closedByNameMeta,
        closedByName.isAcceptableOrUnknown(
          data['closed_by_name']!,
          _closedByNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_closedByNameMeta);
    }
    if (data.containsKey('authorized_by_user_id')) {
      context.handle(
        _authorizedByUserIdMeta,
        authorizedByUserId.isAcceptableOrUnknown(
          data['authorized_by_user_id']!,
          _authorizedByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authorizedByUserIdMeta);
    }
    if (data.containsKey('authorized_by_name')) {
      context.handle(
        _authorizedByNameMeta,
        authorizedByName.isAcceptableOrUnknown(
          data['authorized_by_name']!,
          _authorizedByNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authorizedByNameMeta);
    }
    if (data.containsKey('beginning_balance')) {
      context.handle(
        _beginningBalanceMeta,
        beginningBalance.isAcceptableOrUnknown(
          data['beginning_balance']!,
          _beginningBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_beginningBalanceMeta);
    }
    if (data.containsKey('ending_balance')) {
      context.handle(
        _endingBalanceMeta,
        endingBalance.isAcceptableOrUnknown(
          data['ending_balance']!,
          _endingBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endingBalanceMeta);
    }
    if (data.containsKey('total_sales')) {
      context.handle(
        _totalSalesMeta,
        totalSales.isAcceptableOrUnknown(data['total_sales']!, _totalSalesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSalesMeta);
    }
    if (data.containsKey('vatable_sales')) {
      context.handle(
        _vatableSalesMeta,
        vatableSales.isAcceptableOrUnknown(
          data['vatable_sales']!,
          _vatableSalesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vatableSalesMeta);
    }
    if (data.containsKey('vat_amount')) {
      context.handle(
        _vatAmountMeta,
        vatAmount.isAcceptableOrUnknown(data['vat_amount']!, _vatAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_vatAmountMeta);
    }
    if (data.containsKey('vat_exempt_sales')) {
      context.handle(
        _vatExemptSalesMeta,
        vatExemptSales.isAcceptableOrUnknown(
          data['vat_exempt_sales']!,
          _vatExemptSalesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vatExemptSalesMeta);
    }
    if (data.containsKey('transaction_count')) {
      context.handle(
        _transactionCountMeta,
        transactionCount.isAcceptableOrUnknown(
          data['transaction_count']!,
          _transactionCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionCountMeta);
    }
    if (data.containsKey('completed_count')) {
      context.handle(
        _completedCountMeta,
        completedCount.isAcceptableOrUnknown(
          data['completed_count']!,
          _completedCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedCountMeta);
    }
    if (data.containsKey('voided_count')) {
      context.handle(
        _voidedCountMeta,
        voidedCount.isAcceptableOrUnknown(
          data['voided_count']!,
          _voidedCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_voidedCountMeta);
    }
    if (data.containsKey('refunded_count')) {
      context.handle(
        _refundedCountMeta,
        refundedCount.isAcceptableOrUnknown(
          data['refunded_count']!,
          _refundedCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refundedCountMeta);
    }
    if (data.containsKey('discount_total')) {
      context.handle(
        _discountTotalMeta,
        discountTotal.isAcceptableOrUnknown(
          data['discount_total']!,
          _discountTotalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountTotalMeta);
    }
    if (data.containsKey('cash_collected')) {
      context.handle(
        _cashCollectedMeta,
        cashCollected.isAcceptableOrUnknown(
          data['cash_collected']!,
          _cashCollectedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashCollectedMeta);
    }
    if (data.containsKey('total_qty_sold')) {
      context.handle(
        _totalQtySoldMeta,
        totalQtySold.isAcceptableOrUnknown(
          data['total_qty_sold']!,
          _totalQtySoldMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalQtySoldMeta);
    }
    if (data.containsKey('payment_breakdown_json')) {
      context.handle(
        _paymentBreakdownJsonMeta,
        paymentBreakdownJson.isAcceptableOrUnknown(
          data['payment_breakdown_json']!,
          _paymentBreakdownJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentBreakdownJsonMeta);
    }
    if (data.containsKey('sales_by_cashier_json')) {
      context.handle(
        _salesByCashierJsonMeta,
        salesByCashierJson.isAcceptableOrUnknown(
          data['sales_by_cashier_json']!,
          _salesByCashierJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_salesByCashierJsonMeta);
    }
    if (data.containsKey('discounts_json')) {
      context.handle(
        _discountsJsonMeta,
        discountsJson.isAcceptableOrUnknown(
          data['discounts_json']!,
          _discountsJsonMeta,
        ),
      );
    }
    if (data.containsKey('payment_ledgers_json')) {
      context.handle(
        _paymentLedgersJsonMeta,
        paymentLedgersJson.isAcceptableOrUnknown(
          data['payment_ledgers_json']!,
          _paymentLedgersJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ZReadingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ZReadingsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      zCounter:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}z_counter'],
          )!,
      periodStart:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}period_start'],
          )!,
      periodEnd:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}period_end'],
          )!,
      generatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}generated_at'],
          )!,
      closedByUserId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}closed_by_user_id'],
          )!,
      closedByName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}closed_by_name'],
          )!,
      authorizedByUserId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}authorized_by_user_id'],
          )!,
      authorizedByName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}authorized_by_name'],
          )!,
      beginningBalance:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}beginning_balance'],
          )!,
      endingBalance:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}ending_balance'],
          )!,
      totalSales:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}total_sales'],
          )!,
      vatableSales:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}vatable_sales'],
          )!,
      vatAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}vat_amount'],
          )!,
      vatExemptSales:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}vat_exempt_sales'],
          )!,
      transactionCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}transaction_count'],
          )!,
      completedCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}completed_count'],
          )!,
      voidedCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}voided_count'],
          )!,
      refundedCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}refunded_count'],
          )!,
      discountTotal:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}discount_total'],
          )!,
      cashCollected:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}cash_collected'],
          )!,
      totalQtySold:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total_qty_sold'],
          )!,
      paymentBreakdownJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payment_breakdown_json'],
          )!,
      salesByCashierJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sales_by_cashier_json'],
          )!,
      discountsJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}discounts_json'],
          )!,
      paymentLedgersJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payment_ledgers_json'],
          )!,
    );
  }

  @override
  $ZReadingsTableTable createAlias(String alias) {
    return $ZReadingsTableTable(attachedDatabase, alias);
  }
}

class ZReadingsTableData extends DataClass
    implements Insertable<ZReadingsTableData> {
  final int id;
  final int zCounter;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime generatedAt;
  final int closedByUserId;
  final String closedByName;
  final int authorizedByUserId;
  final String authorizedByName;
  final double beginningBalance;
  final double endingBalance;
  final double totalSales;
  final double vatableSales;
  final double vatAmount;
  final double vatExemptSales;
  final int transactionCount;
  final int completedCount;
  final int voidedCount;
  final int refundedCount;
  final double discountTotal;
  final double cashCollected;
  final int totalQtySold;
  final String paymentBreakdownJson;
  final String salesByCashierJson;
  final String discountsJson;
  final String paymentLedgersJson;
  const ZReadingsTableData({
    required this.id,
    required this.zCounter,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.closedByUserId,
    required this.closedByName,
    required this.authorizedByUserId,
    required this.authorizedByName,
    required this.beginningBalance,
    required this.endingBalance,
    required this.totalSales,
    required this.vatableSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.transactionCount,
    required this.completedCount,
    required this.voidedCount,
    required this.refundedCount,
    required this.discountTotal,
    required this.cashCollected,
    required this.totalQtySold,
    required this.paymentBreakdownJson,
    required this.salesByCashierJson,
    required this.discountsJson,
    required this.paymentLedgersJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['z_counter'] = Variable<int>(zCounter);
    map['period_start'] = Variable<DateTime>(periodStart);
    map['period_end'] = Variable<DateTime>(periodEnd);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['closed_by_user_id'] = Variable<int>(closedByUserId);
    map['closed_by_name'] = Variable<String>(closedByName);
    map['authorized_by_user_id'] = Variable<int>(authorizedByUserId);
    map['authorized_by_name'] = Variable<String>(authorizedByName);
    map['beginning_balance'] = Variable<double>(beginningBalance);
    map['ending_balance'] = Variable<double>(endingBalance);
    map['total_sales'] = Variable<double>(totalSales);
    map['vatable_sales'] = Variable<double>(vatableSales);
    map['vat_amount'] = Variable<double>(vatAmount);
    map['vat_exempt_sales'] = Variable<double>(vatExemptSales);
    map['transaction_count'] = Variable<int>(transactionCount);
    map['completed_count'] = Variable<int>(completedCount);
    map['voided_count'] = Variable<int>(voidedCount);
    map['refunded_count'] = Variable<int>(refundedCount);
    map['discount_total'] = Variable<double>(discountTotal);
    map['cash_collected'] = Variable<double>(cashCollected);
    map['total_qty_sold'] = Variable<int>(totalQtySold);
    map['payment_breakdown_json'] = Variable<String>(paymentBreakdownJson);
    map['sales_by_cashier_json'] = Variable<String>(salesByCashierJson);
    map['discounts_json'] = Variable<String>(discountsJson);
    map['payment_ledgers_json'] = Variable<String>(paymentLedgersJson);
    return map;
  }

  ZReadingsTableCompanion toCompanion(bool nullToAbsent) {
    return ZReadingsTableCompanion(
      id: Value(id),
      zCounter: Value(zCounter),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      generatedAt: Value(generatedAt),
      closedByUserId: Value(closedByUserId),
      closedByName: Value(closedByName),
      authorizedByUserId: Value(authorizedByUserId),
      authorizedByName: Value(authorizedByName),
      beginningBalance: Value(beginningBalance),
      endingBalance: Value(endingBalance),
      totalSales: Value(totalSales),
      vatableSales: Value(vatableSales),
      vatAmount: Value(vatAmount),
      vatExemptSales: Value(vatExemptSales),
      transactionCount: Value(transactionCount),
      completedCount: Value(completedCount),
      voidedCount: Value(voidedCount),
      refundedCount: Value(refundedCount),
      discountTotal: Value(discountTotal),
      cashCollected: Value(cashCollected),
      totalQtySold: Value(totalQtySold),
      paymentBreakdownJson: Value(paymentBreakdownJson),
      salesByCashierJson: Value(salesByCashierJson),
      discountsJson: Value(discountsJson),
      paymentLedgersJson: Value(paymentLedgersJson),
    );
  }

  factory ZReadingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ZReadingsTableData(
      id: serializer.fromJson<int>(json['id']),
      zCounter: serializer.fromJson<int>(json['zCounter']),
      periodStart: serializer.fromJson<DateTime>(json['periodStart']),
      periodEnd: serializer.fromJson<DateTime>(json['periodEnd']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      closedByUserId: serializer.fromJson<int>(json['closedByUserId']),
      closedByName: serializer.fromJson<String>(json['closedByName']),
      authorizedByUserId: serializer.fromJson<int>(json['authorizedByUserId']),
      authorizedByName: serializer.fromJson<String>(json['authorizedByName']),
      beginningBalance: serializer.fromJson<double>(json['beginningBalance']),
      endingBalance: serializer.fromJson<double>(json['endingBalance']),
      totalSales: serializer.fromJson<double>(json['totalSales']),
      vatableSales: serializer.fromJson<double>(json['vatableSales']),
      vatAmount: serializer.fromJson<double>(json['vatAmount']),
      vatExemptSales: serializer.fromJson<double>(json['vatExemptSales']),
      transactionCount: serializer.fromJson<int>(json['transactionCount']),
      completedCount: serializer.fromJson<int>(json['completedCount']),
      voidedCount: serializer.fromJson<int>(json['voidedCount']),
      refundedCount: serializer.fromJson<int>(json['refundedCount']),
      discountTotal: serializer.fromJson<double>(json['discountTotal']),
      cashCollected: serializer.fromJson<double>(json['cashCollected']),
      totalQtySold: serializer.fromJson<int>(json['totalQtySold']),
      paymentBreakdownJson: serializer.fromJson<String>(
        json['paymentBreakdownJson'],
      ),
      salesByCashierJson: serializer.fromJson<String>(
        json['salesByCashierJson'],
      ),
      discountsJson: serializer.fromJson<String>(json['discountsJson']),
      paymentLedgersJson: serializer.fromJson<String>(
        json['paymentLedgersJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'zCounter': serializer.toJson<int>(zCounter),
      'periodStart': serializer.toJson<DateTime>(periodStart),
      'periodEnd': serializer.toJson<DateTime>(periodEnd),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'closedByUserId': serializer.toJson<int>(closedByUserId),
      'closedByName': serializer.toJson<String>(closedByName),
      'authorizedByUserId': serializer.toJson<int>(authorizedByUserId),
      'authorizedByName': serializer.toJson<String>(authorizedByName),
      'beginningBalance': serializer.toJson<double>(beginningBalance),
      'endingBalance': serializer.toJson<double>(endingBalance),
      'totalSales': serializer.toJson<double>(totalSales),
      'vatableSales': serializer.toJson<double>(vatableSales),
      'vatAmount': serializer.toJson<double>(vatAmount),
      'vatExemptSales': serializer.toJson<double>(vatExemptSales),
      'transactionCount': serializer.toJson<int>(transactionCount),
      'completedCount': serializer.toJson<int>(completedCount),
      'voidedCount': serializer.toJson<int>(voidedCount),
      'refundedCount': serializer.toJson<int>(refundedCount),
      'discountTotal': serializer.toJson<double>(discountTotal),
      'cashCollected': serializer.toJson<double>(cashCollected),
      'totalQtySold': serializer.toJson<int>(totalQtySold),
      'paymentBreakdownJson': serializer.toJson<String>(paymentBreakdownJson),
      'salesByCashierJson': serializer.toJson<String>(salesByCashierJson),
      'discountsJson': serializer.toJson<String>(discountsJson),
      'paymentLedgersJson': serializer.toJson<String>(paymentLedgersJson),
    };
  }

  ZReadingsTableData copyWith({
    int? id,
    int? zCounter,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? generatedAt,
    int? closedByUserId,
    String? closedByName,
    int? authorizedByUserId,
    String? authorizedByName,
    double? beginningBalance,
    double? endingBalance,
    double? totalSales,
    double? vatableSales,
    double? vatAmount,
    double? vatExemptSales,
    int? transactionCount,
    int? completedCount,
    int? voidedCount,
    int? refundedCount,
    double? discountTotal,
    double? cashCollected,
    int? totalQtySold,
    String? paymentBreakdownJson,
    String? salesByCashierJson,
    String? discountsJson,
    String? paymentLedgersJson,
  }) => ZReadingsTableData(
    id: id ?? this.id,
    zCounter: zCounter ?? this.zCounter,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    generatedAt: generatedAt ?? this.generatedAt,
    closedByUserId: closedByUserId ?? this.closedByUserId,
    closedByName: closedByName ?? this.closedByName,
    authorizedByUserId: authorizedByUserId ?? this.authorizedByUserId,
    authorizedByName: authorizedByName ?? this.authorizedByName,
    beginningBalance: beginningBalance ?? this.beginningBalance,
    endingBalance: endingBalance ?? this.endingBalance,
    totalSales: totalSales ?? this.totalSales,
    vatableSales: vatableSales ?? this.vatableSales,
    vatAmount: vatAmount ?? this.vatAmount,
    vatExemptSales: vatExemptSales ?? this.vatExemptSales,
    transactionCount: transactionCount ?? this.transactionCount,
    completedCount: completedCount ?? this.completedCount,
    voidedCount: voidedCount ?? this.voidedCount,
    refundedCount: refundedCount ?? this.refundedCount,
    discountTotal: discountTotal ?? this.discountTotal,
    cashCollected: cashCollected ?? this.cashCollected,
    totalQtySold: totalQtySold ?? this.totalQtySold,
    paymentBreakdownJson: paymentBreakdownJson ?? this.paymentBreakdownJson,
    salesByCashierJson: salesByCashierJson ?? this.salesByCashierJson,
    discountsJson: discountsJson ?? this.discountsJson,
    paymentLedgersJson: paymentLedgersJson ?? this.paymentLedgersJson,
  );
  ZReadingsTableData copyWithCompanion(ZReadingsTableCompanion data) {
    return ZReadingsTableData(
      id: data.id.present ? data.id.value : this.id,
      zCounter: data.zCounter.present ? data.zCounter.value : this.zCounter,
      periodStart:
          data.periodStart.present ? data.periodStart.value : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      closedByUserId:
          data.closedByUserId.present
              ? data.closedByUserId.value
              : this.closedByUserId,
      closedByName:
          data.closedByName.present
              ? data.closedByName.value
              : this.closedByName,
      authorizedByUserId:
          data.authorizedByUserId.present
              ? data.authorizedByUserId.value
              : this.authorizedByUserId,
      authorizedByName:
          data.authorizedByName.present
              ? data.authorizedByName.value
              : this.authorizedByName,
      beginningBalance:
          data.beginningBalance.present
              ? data.beginningBalance.value
              : this.beginningBalance,
      endingBalance:
          data.endingBalance.present
              ? data.endingBalance.value
              : this.endingBalance,
      totalSales:
          data.totalSales.present ? data.totalSales.value : this.totalSales,
      vatableSales:
          data.vatableSales.present
              ? data.vatableSales.value
              : this.vatableSales,
      vatAmount: data.vatAmount.present ? data.vatAmount.value : this.vatAmount,
      vatExemptSales:
          data.vatExemptSales.present
              ? data.vatExemptSales.value
              : this.vatExemptSales,
      transactionCount:
          data.transactionCount.present
              ? data.transactionCount.value
              : this.transactionCount,
      completedCount:
          data.completedCount.present
              ? data.completedCount.value
              : this.completedCount,
      voidedCount:
          data.voidedCount.present ? data.voidedCount.value : this.voidedCount,
      refundedCount:
          data.refundedCount.present
              ? data.refundedCount.value
              : this.refundedCount,
      discountTotal:
          data.discountTotal.present
              ? data.discountTotal.value
              : this.discountTotal,
      cashCollected:
          data.cashCollected.present
              ? data.cashCollected.value
              : this.cashCollected,
      totalQtySold:
          data.totalQtySold.present
              ? data.totalQtySold.value
              : this.totalQtySold,
      paymentBreakdownJson:
          data.paymentBreakdownJson.present
              ? data.paymentBreakdownJson.value
              : this.paymentBreakdownJson,
      salesByCashierJson:
          data.salesByCashierJson.present
              ? data.salesByCashierJson.value
              : this.salesByCashierJson,
      discountsJson:
          data.discountsJson.present
              ? data.discountsJson.value
              : this.discountsJson,
      paymentLedgersJson:
          data.paymentLedgersJson.present
              ? data.paymentLedgersJson.value
              : this.paymentLedgersJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ZReadingsTableData(')
          ..write('id: $id, ')
          ..write('zCounter: $zCounter, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('closedByUserId: $closedByUserId, ')
          ..write('closedByName: $closedByName, ')
          ..write('authorizedByUserId: $authorizedByUserId, ')
          ..write('authorizedByName: $authorizedByName, ')
          ..write('beginningBalance: $beginningBalance, ')
          ..write('endingBalance: $endingBalance, ')
          ..write('totalSales: $totalSales, ')
          ..write('vatableSales: $vatableSales, ')
          ..write('vatAmount: $vatAmount, ')
          ..write('vatExemptSales: $vatExemptSales, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('completedCount: $completedCount, ')
          ..write('voidedCount: $voidedCount, ')
          ..write('refundedCount: $refundedCount, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('cashCollected: $cashCollected, ')
          ..write('totalQtySold: $totalQtySold, ')
          ..write('paymentBreakdownJson: $paymentBreakdownJson, ')
          ..write('salesByCashierJson: $salesByCashierJson, ')
          ..write('discountsJson: $discountsJson, ')
          ..write('paymentLedgersJson: $paymentLedgersJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    zCounter,
    periodStart,
    periodEnd,
    generatedAt,
    closedByUserId,
    closedByName,
    authorizedByUserId,
    authorizedByName,
    beginningBalance,
    endingBalance,
    totalSales,
    vatableSales,
    vatAmount,
    vatExemptSales,
    transactionCount,
    completedCount,
    voidedCount,
    refundedCount,
    discountTotal,
    cashCollected,
    totalQtySold,
    paymentBreakdownJson,
    salesByCashierJson,
    discountsJson,
    paymentLedgersJson,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ZReadingsTableData &&
          other.id == this.id &&
          other.zCounter == this.zCounter &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.generatedAt == this.generatedAt &&
          other.closedByUserId == this.closedByUserId &&
          other.closedByName == this.closedByName &&
          other.authorizedByUserId == this.authorizedByUserId &&
          other.authorizedByName == this.authorizedByName &&
          other.beginningBalance == this.beginningBalance &&
          other.endingBalance == this.endingBalance &&
          other.totalSales == this.totalSales &&
          other.vatableSales == this.vatableSales &&
          other.vatAmount == this.vatAmount &&
          other.vatExemptSales == this.vatExemptSales &&
          other.transactionCount == this.transactionCount &&
          other.completedCount == this.completedCount &&
          other.voidedCount == this.voidedCount &&
          other.refundedCount == this.refundedCount &&
          other.discountTotal == this.discountTotal &&
          other.cashCollected == this.cashCollected &&
          other.totalQtySold == this.totalQtySold &&
          other.paymentBreakdownJson == this.paymentBreakdownJson &&
          other.salesByCashierJson == this.salesByCashierJson &&
          other.discountsJson == this.discountsJson &&
          other.paymentLedgersJson == this.paymentLedgersJson);
}

class ZReadingsTableCompanion extends UpdateCompanion<ZReadingsTableData> {
  final Value<int> id;
  final Value<int> zCounter;
  final Value<DateTime> periodStart;
  final Value<DateTime> periodEnd;
  final Value<DateTime> generatedAt;
  final Value<int> closedByUserId;
  final Value<String> closedByName;
  final Value<int> authorizedByUserId;
  final Value<String> authorizedByName;
  final Value<double> beginningBalance;
  final Value<double> endingBalance;
  final Value<double> totalSales;
  final Value<double> vatableSales;
  final Value<double> vatAmount;
  final Value<double> vatExemptSales;
  final Value<int> transactionCount;
  final Value<int> completedCount;
  final Value<int> voidedCount;
  final Value<int> refundedCount;
  final Value<double> discountTotal;
  final Value<double> cashCollected;
  final Value<int> totalQtySold;
  final Value<String> paymentBreakdownJson;
  final Value<String> salesByCashierJson;
  final Value<String> discountsJson;
  final Value<String> paymentLedgersJson;
  const ZReadingsTableCompanion({
    this.id = const Value.absent(),
    this.zCounter = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.closedByUserId = const Value.absent(),
    this.closedByName = const Value.absent(),
    this.authorizedByUserId = const Value.absent(),
    this.authorizedByName = const Value.absent(),
    this.beginningBalance = const Value.absent(),
    this.endingBalance = const Value.absent(),
    this.totalSales = const Value.absent(),
    this.vatableSales = const Value.absent(),
    this.vatAmount = const Value.absent(),
    this.vatExemptSales = const Value.absent(),
    this.transactionCount = const Value.absent(),
    this.completedCount = const Value.absent(),
    this.voidedCount = const Value.absent(),
    this.refundedCount = const Value.absent(),
    this.discountTotal = const Value.absent(),
    this.cashCollected = const Value.absent(),
    this.totalQtySold = const Value.absent(),
    this.paymentBreakdownJson = const Value.absent(),
    this.salesByCashierJson = const Value.absent(),
    this.discountsJson = const Value.absent(),
    this.paymentLedgersJson = const Value.absent(),
  });
  ZReadingsTableCompanion.insert({
    this.id = const Value.absent(),
    required int zCounter,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime generatedAt,
    required int closedByUserId,
    required String closedByName,
    required int authorizedByUserId,
    required String authorizedByName,
    required double beginningBalance,
    required double endingBalance,
    required double totalSales,
    required double vatableSales,
    required double vatAmount,
    required double vatExemptSales,
    required int transactionCount,
    required int completedCount,
    required int voidedCount,
    required int refundedCount,
    required double discountTotal,
    required double cashCollected,
    required int totalQtySold,
    required String paymentBreakdownJson,
    required String salesByCashierJson,
    this.discountsJson = const Value.absent(),
    this.paymentLedgersJson = const Value.absent(),
  }) : zCounter = Value(zCounter),
       periodStart = Value(periodStart),
       periodEnd = Value(periodEnd),
       generatedAt = Value(generatedAt),
       closedByUserId = Value(closedByUserId),
       closedByName = Value(closedByName),
       authorizedByUserId = Value(authorizedByUserId),
       authorizedByName = Value(authorizedByName),
       beginningBalance = Value(beginningBalance),
       endingBalance = Value(endingBalance),
       totalSales = Value(totalSales),
       vatableSales = Value(vatableSales),
       vatAmount = Value(vatAmount),
       vatExemptSales = Value(vatExemptSales),
       transactionCount = Value(transactionCount),
       completedCount = Value(completedCount),
       voidedCount = Value(voidedCount),
       refundedCount = Value(refundedCount),
       discountTotal = Value(discountTotal),
       cashCollected = Value(cashCollected),
       totalQtySold = Value(totalQtySold),
       paymentBreakdownJson = Value(paymentBreakdownJson),
       salesByCashierJson = Value(salesByCashierJson);
  static Insertable<ZReadingsTableData> custom({
    Expression<int>? id,
    Expression<int>? zCounter,
    Expression<DateTime>? periodStart,
    Expression<DateTime>? periodEnd,
    Expression<DateTime>? generatedAt,
    Expression<int>? closedByUserId,
    Expression<String>? closedByName,
    Expression<int>? authorizedByUserId,
    Expression<String>? authorizedByName,
    Expression<double>? beginningBalance,
    Expression<double>? endingBalance,
    Expression<double>? totalSales,
    Expression<double>? vatableSales,
    Expression<double>? vatAmount,
    Expression<double>? vatExemptSales,
    Expression<int>? transactionCount,
    Expression<int>? completedCount,
    Expression<int>? voidedCount,
    Expression<int>? refundedCount,
    Expression<double>? discountTotal,
    Expression<double>? cashCollected,
    Expression<int>? totalQtySold,
    Expression<String>? paymentBreakdownJson,
    Expression<String>? salesByCashierJson,
    Expression<String>? discountsJson,
    Expression<String>? paymentLedgersJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (zCounter != null) 'z_counter': zCounter,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (closedByUserId != null) 'closed_by_user_id': closedByUserId,
      if (closedByName != null) 'closed_by_name': closedByName,
      if (authorizedByUserId != null)
        'authorized_by_user_id': authorizedByUserId,
      if (authorizedByName != null) 'authorized_by_name': authorizedByName,
      if (beginningBalance != null) 'beginning_balance': beginningBalance,
      if (endingBalance != null) 'ending_balance': endingBalance,
      if (totalSales != null) 'total_sales': totalSales,
      if (vatableSales != null) 'vatable_sales': vatableSales,
      if (vatAmount != null) 'vat_amount': vatAmount,
      if (vatExemptSales != null) 'vat_exempt_sales': vatExemptSales,
      if (transactionCount != null) 'transaction_count': transactionCount,
      if (completedCount != null) 'completed_count': completedCount,
      if (voidedCount != null) 'voided_count': voidedCount,
      if (refundedCount != null) 'refunded_count': refundedCount,
      if (discountTotal != null) 'discount_total': discountTotal,
      if (cashCollected != null) 'cash_collected': cashCollected,
      if (totalQtySold != null) 'total_qty_sold': totalQtySold,
      if (paymentBreakdownJson != null)
        'payment_breakdown_json': paymentBreakdownJson,
      if (salesByCashierJson != null)
        'sales_by_cashier_json': salesByCashierJson,
      if (discountsJson != null) 'discounts_json': discountsJson,
      if (paymentLedgersJson != null)
        'payment_ledgers_json': paymentLedgersJson,
    });
  }

  ZReadingsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? zCounter,
    Value<DateTime>? periodStart,
    Value<DateTime>? periodEnd,
    Value<DateTime>? generatedAt,
    Value<int>? closedByUserId,
    Value<String>? closedByName,
    Value<int>? authorizedByUserId,
    Value<String>? authorizedByName,
    Value<double>? beginningBalance,
    Value<double>? endingBalance,
    Value<double>? totalSales,
    Value<double>? vatableSales,
    Value<double>? vatAmount,
    Value<double>? vatExemptSales,
    Value<int>? transactionCount,
    Value<int>? completedCount,
    Value<int>? voidedCount,
    Value<int>? refundedCount,
    Value<double>? discountTotal,
    Value<double>? cashCollected,
    Value<int>? totalQtySold,
    Value<String>? paymentBreakdownJson,
    Value<String>? salesByCashierJson,
    Value<String>? discountsJson,
    Value<String>? paymentLedgersJson,
  }) {
    return ZReadingsTableCompanion(
      id: id ?? this.id,
      zCounter: zCounter ?? this.zCounter,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      generatedAt: generatedAt ?? this.generatedAt,
      closedByUserId: closedByUserId ?? this.closedByUserId,
      closedByName: closedByName ?? this.closedByName,
      authorizedByUserId: authorizedByUserId ?? this.authorizedByUserId,
      authorizedByName: authorizedByName ?? this.authorizedByName,
      beginningBalance: beginningBalance ?? this.beginningBalance,
      endingBalance: endingBalance ?? this.endingBalance,
      totalSales: totalSales ?? this.totalSales,
      vatableSales: vatableSales ?? this.vatableSales,
      vatAmount: vatAmount ?? this.vatAmount,
      vatExemptSales: vatExemptSales ?? this.vatExemptSales,
      transactionCount: transactionCount ?? this.transactionCount,
      completedCount: completedCount ?? this.completedCount,
      voidedCount: voidedCount ?? this.voidedCount,
      refundedCount: refundedCount ?? this.refundedCount,
      discountTotal: discountTotal ?? this.discountTotal,
      cashCollected: cashCollected ?? this.cashCollected,
      totalQtySold: totalQtySold ?? this.totalQtySold,
      paymentBreakdownJson: paymentBreakdownJson ?? this.paymentBreakdownJson,
      salesByCashierJson: salesByCashierJson ?? this.salesByCashierJson,
      discountsJson: discountsJson ?? this.discountsJson,
      paymentLedgersJson: paymentLedgersJson ?? this.paymentLedgersJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (zCounter.present) {
      map['z_counter'] = Variable<int>(zCounter.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<DateTime>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<DateTime>(periodEnd.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (closedByUserId.present) {
      map['closed_by_user_id'] = Variable<int>(closedByUserId.value);
    }
    if (closedByName.present) {
      map['closed_by_name'] = Variable<String>(closedByName.value);
    }
    if (authorizedByUserId.present) {
      map['authorized_by_user_id'] = Variable<int>(authorizedByUserId.value);
    }
    if (authorizedByName.present) {
      map['authorized_by_name'] = Variable<String>(authorizedByName.value);
    }
    if (beginningBalance.present) {
      map['beginning_balance'] = Variable<double>(beginningBalance.value);
    }
    if (endingBalance.present) {
      map['ending_balance'] = Variable<double>(endingBalance.value);
    }
    if (totalSales.present) {
      map['total_sales'] = Variable<double>(totalSales.value);
    }
    if (vatableSales.present) {
      map['vatable_sales'] = Variable<double>(vatableSales.value);
    }
    if (vatAmount.present) {
      map['vat_amount'] = Variable<double>(vatAmount.value);
    }
    if (vatExemptSales.present) {
      map['vat_exempt_sales'] = Variable<double>(vatExemptSales.value);
    }
    if (transactionCount.present) {
      map['transaction_count'] = Variable<int>(transactionCount.value);
    }
    if (completedCount.present) {
      map['completed_count'] = Variable<int>(completedCount.value);
    }
    if (voidedCount.present) {
      map['voided_count'] = Variable<int>(voidedCount.value);
    }
    if (refundedCount.present) {
      map['refunded_count'] = Variable<int>(refundedCount.value);
    }
    if (discountTotal.present) {
      map['discount_total'] = Variable<double>(discountTotal.value);
    }
    if (cashCollected.present) {
      map['cash_collected'] = Variable<double>(cashCollected.value);
    }
    if (totalQtySold.present) {
      map['total_qty_sold'] = Variable<int>(totalQtySold.value);
    }
    if (paymentBreakdownJson.present) {
      map['payment_breakdown_json'] = Variable<String>(
        paymentBreakdownJson.value,
      );
    }
    if (salesByCashierJson.present) {
      map['sales_by_cashier_json'] = Variable<String>(salesByCashierJson.value);
    }
    if (discountsJson.present) {
      map['discounts_json'] = Variable<String>(discountsJson.value);
    }
    if (paymentLedgersJson.present) {
      map['payment_ledgers_json'] = Variable<String>(paymentLedgersJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ZReadingsTableCompanion(')
          ..write('id: $id, ')
          ..write('zCounter: $zCounter, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('closedByUserId: $closedByUserId, ')
          ..write('closedByName: $closedByName, ')
          ..write('authorizedByUserId: $authorizedByUserId, ')
          ..write('authorizedByName: $authorizedByName, ')
          ..write('beginningBalance: $beginningBalance, ')
          ..write('endingBalance: $endingBalance, ')
          ..write('totalSales: $totalSales, ')
          ..write('vatableSales: $vatableSales, ')
          ..write('vatAmount: $vatAmount, ')
          ..write('vatExemptSales: $vatExemptSales, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('completedCount: $completedCount, ')
          ..write('voidedCount: $voidedCount, ')
          ..write('refundedCount: $refundedCount, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('cashCollected: $cashCollected, ')
          ..write('totalQtySold: $totalQtySold, ')
          ..write('paymentBreakdownJson: $paymentBreakdownJson, ')
          ..write('salesByCashierJson: $salesByCashierJson, ')
          ..write('discountsJson: $discountsJson, ')
          ..write('paymentLedgersJson: $paymentLedgersJson')
          ..write(')'))
        .toString();
  }
}

class $PaymentMethodsTableTable extends PaymentMethodsTable
    with TableInfo<$PaymentMethodsTableTable, PaymentMethodsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentMethodsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountNameMeta = const VerificationMeta(
    'accountName',
  );
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
    'account_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountNumberMeta = const VerificationMeta(
    'accountNumber',
  );
  @override
  late final GeneratedColumn<String> accountNumber = GeneratedColumn<String>(
    'account_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    accountName,
    accountNumber,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_methods';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentMethodsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('account_name')) {
      context.handle(
        _accountNameMeta,
        accountName.isAcceptableOrUnknown(
          data['account_name']!,
          _accountNameMeta,
        ),
      );
    }
    if (data.containsKey('account_number')) {
      context.handle(
        _accountNumberMeta,
        accountNumber.isAcceptableOrUnknown(
          data['account_number']!,
          _accountNumberMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentMethodsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentMethodsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      label:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}label'],
          )!,
      accountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name'],
      ),
      accountNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_number'],
      ),
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
    );
  }

  @override
  $PaymentMethodsTableTable createAlias(String alias) {
    return $PaymentMethodsTableTable(attachedDatabase, alias);
  }
}

class PaymentMethodsTableData extends DataClass
    implements Insertable<PaymentMethodsTableData> {
  final int id;
  final String label;
  final String? accountName;
  final String? accountNumber;
  final int sortOrder;
  const PaymentMethodsTableData({
    required this.id,
    required this.label,
    this.accountName,
    this.accountNumber,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || accountName != null) {
      map['account_name'] = Variable<String>(accountName);
    }
    if (!nullToAbsent || accountNumber != null) {
      map['account_number'] = Variable<String>(accountNumber);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  PaymentMethodsTableCompanion toCompanion(bool nullToAbsent) {
    return PaymentMethodsTableCompanion(
      id: Value(id),
      label: Value(label),
      accountName:
          accountName == null && nullToAbsent
              ? const Value.absent()
              : Value(accountName),
      accountNumber:
          accountNumber == null && nullToAbsent
              ? const Value.absent()
              : Value(accountNumber),
      sortOrder: Value(sortOrder),
    );
  }

  factory PaymentMethodsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentMethodsTableData(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      accountName: serializer.fromJson<String?>(json['accountName']),
      accountNumber: serializer.fromJson<String?>(json['accountNumber']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'accountName': serializer.toJson<String?>(accountName),
      'accountNumber': serializer.toJson<String?>(accountNumber),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  PaymentMethodsTableData copyWith({
    int? id,
    String? label,
    Value<String?> accountName = const Value.absent(),
    Value<String?> accountNumber = const Value.absent(),
    int? sortOrder,
  }) => PaymentMethodsTableData(
    id: id ?? this.id,
    label: label ?? this.label,
    accountName: accountName.present ? accountName.value : this.accountName,
    accountNumber:
        accountNumber.present ? accountNumber.value : this.accountNumber,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  PaymentMethodsTableData copyWithCompanion(PaymentMethodsTableCompanion data) {
    return PaymentMethodsTableData(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      accountName:
          data.accountName.present ? data.accountName.value : this.accountName,
      accountNumber:
          data.accountNumber.present
              ? data.accountNumber.value
              : this.accountNumber,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodsTableData(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('accountName: $accountName, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, label, accountName, accountNumber, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentMethodsTableData &&
          other.id == this.id &&
          other.label == this.label &&
          other.accountName == this.accountName &&
          other.accountNumber == this.accountNumber &&
          other.sortOrder == this.sortOrder);
}

class PaymentMethodsTableCompanion
    extends UpdateCompanion<PaymentMethodsTableData> {
  final Value<int> id;
  final Value<String> label;
  final Value<String?> accountName;
  final Value<String?> accountNumber;
  final Value<int> sortOrder;
  const PaymentMethodsTableCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.accountName = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  PaymentMethodsTableCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    this.accountName = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : label = Value(label);
  static Insertable<PaymentMethodsTableData> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<String>? accountName,
    Expression<String>? accountNumber,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (accountName != null) 'account_name': accountName,
      if (accountNumber != null) 'account_number': accountNumber,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  PaymentMethodsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<String?>? accountName,
    Value<String?>? accountNumber,
    Value<int>? sortOrder,
  }) {
    return PaymentMethodsTableCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (accountNumber.present) {
      map['account_number'] = Variable<String>(accountNumber.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodsTableCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('accountName: $accountName, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $OrderEventsTableTable extends OrderEventsTable
    with TableInfo<$OrderEventsTableTable, OrderEventsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderEventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncGenerationMeta = const VerificationMeta(
    'syncGeneration',
  );
  @override
  late final GeneratedColumn<int> syncGeneration = GeneratedColumn<int>(
    'sync_generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    orderId,
    storeId,
    eventType,
    payload,
    updatedAt,
    syncGeneration,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderEventsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_generation')) {
      context.handle(
        _syncGenerationMeta,
        syncGeneration.isAcceptableOrUnknown(
          data['sync_generation']!,
          _syncGenerationMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {orderId};
  @override
  OrderEventsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderEventsTableData(
      orderId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}order_id'],
          )!,
      storeId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}store_id'],
          )!,
      eventType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}event_type'],
          )!,
      payload:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
      syncGeneration:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sync_generation'],
          )!,
    );
  }

  @override
  $OrderEventsTableTable createAlias(String alias) {
    return $OrderEventsTableTable(attachedDatabase, alias);
  }
}

class OrderEventsTableData extends DataClass
    implements Insertable<OrderEventsTableData> {
  final String orderId;
  final String storeId;
  final String eventType;
  final String payload;
  final DateTime updatedAt;
  final int syncGeneration;
  const OrderEventsTableData({
    required this.orderId,
    required this.storeId,
    required this.eventType,
    required this.payload,
    required this.updatedAt,
    required this.syncGeneration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['order_id'] = Variable<String>(orderId);
    map['store_id'] = Variable<String>(storeId);
    map['event_type'] = Variable<String>(eventType);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_generation'] = Variable<int>(syncGeneration);
    return map;
  }

  OrderEventsTableCompanion toCompanion(bool nullToAbsent) {
    return OrderEventsTableCompanion(
      orderId: Value(orderId),
      storeId: Value(storeId),
      eventType: Value(eventType),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
      syncGeneration: Value(syncGeneration),
    );
  }

  factory OrderEventsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderEventsTableData(
      orderId: serializer.fromJson<String>(json['orderId']),
      storeId: serializer.fromJson<String>(json['storeId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncGeneration: serializer.fromJson<int>(json['syncGeneration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'orderId': serializer.toJson<String>(orderId),
      'storeId': serializer.toJson<String>(storeId),
      'eventType': serializer.toJson<String>(eventType),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncGeneration': serializer.toJson<int>(syncGeneration),
    };
  }

  OrderEventsTableData copyWith({
    String? orderId,
    String? storeId,
    String? eventType,
    String? payload,
    DateTime? updatedAt,
    int? syncGeneration,
  }) => OrderEventsTableData(
    orderId: orderId ?? this.orderId,
    storeId: storeId ?? this.storeId,
    eventType: eventType ?? this.eventType,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
    syncGeneration: syncGeneration ?? this.syncGeneration,
  );
  OrderEventsTableData copyWithCompanion(OrderEventsTableCompanion data) {
    return OrderEventsTableData(
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncGeneration:
          data.syncGeneration.present
              ? data.syncGeneration.value
              : this.syncGeneration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderEventsTableData(')
          ..write('orderId: $orderId, ')
          ..write('storeId: $storeId, ')
          ..write('eventType: $eventType, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncGeneration: $syncGeneration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    orderId,
    storeId,
    eventType,
    payload,
    updatedAt,
    syncGeneration,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderEventsTableData &&
          other.orderId == this.orderId &&
          other.storeId == this.storeId &&
          other.eventType == this.eventType &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt &&
          other.syncGeneration == this.syncGeneration);
}

class OrderEventsTableCompanion extends UpdateCompanion<OrderEventsTableData> {
  final Value<String> orderId;
  final Value<String> storeId;
  final Value<String> eventType;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> syncGeneration;
  final Value<int> rowid;
  const OrderEventsTableCompanion({
    this.orderId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncGeneration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderEventsTableCompanion.insert({
    required String orderId,
    required String storeId,
    required String eventType,
    required String payload,
    this.updatedAt = const Value.absent(),
    this.syncGeneration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : orderId = Value(orderId),
       storeId = Value(storeId),
       eventType = Value(eventType),
       payload = Value(payload);
  static Insertable<OrderEventsTableData> custom({
    Expression<String>? orderId,
    Expression<String>? storeId,
    Expression<String>? eventType,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? syncGeneration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (orderId != null) 'order_id': orderId,
      if (storeId != null) 'store_id': storeId,
      if (eventType != null) 'event_type': eventType,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncGeneration != null) 'sync_generation': syncGeneration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderEventsTableCompanion copyWith({
    Value<String>? orderId,
    Value<String>? storeId,
    Value<String>? eventType,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? syncGeneration,
    Value<int>? rowid,
  }) {
    return OrderEventsTableCompanion(
      orderId: orderId ?? this.orderId,
      storeId: storeId ?? this.storeId,
      eventType: eventType ?? this.eventType,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      syncGeneration: syncGeneration ?? this.syncGeneration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncGeneration.present) {
      map['sync_generation'] = Variable<int>(syncGeneration.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderEventsTableCompanion(')
          ..write('orderId: $orderId, ')
          ..write('storeId: $storeId, ')
          ..write('eventType: $eventType, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTableTable usersTable = $UsersTableTable(this);
  late final $ProductGroupsTableTable productGroupsTable =
      $ProductGroupsTableTable(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $ProductVariantsTableTable productVariantsTable =
      $ProductVariantsTableTable(this);
  late final $ModifierGroupsTableTable modifierGroupsTable =
      $ModifierGroupsTableTable(this);
  late final $ModifierOptionsTableTable modifierOptionsTable =
      $ModifierOptionsTableTable(this);
  late final $ProductModifierGroupsTableTable productModifierGroupsTable =
      $ProductModifierGroupsTableTable(this);
  late final $SalesTableTable salesTable = $SalesTableTable(this);
  late final $SaleItemsTableTable saleItemsTable = $SaleItemsTableTable(this);
  late final $SaleItemModifiersTableTable saleItemModifiersTable =
      $SaleItemModifiersTableTable(this);
  late final $PaymentsTableTable paymentsTable = $PaymentsTableTable(this);
  late final $RefundsTableTable refundsTable = $RefundsTableTable(this);
  late final $RefundItemsTableTable refundItemsTable = $RefundItemsTableTable(
    this,
  );
  late final $StoreInfoTableTable storeInfoTable = $StoreInfoTableTable(this);
  late final $XReadingsTableTable xReadingsTable = $XReadingsTableTable(this);
  late final $DailyReportsTableTable dailyReportsTable =
      $DailyReportsTableTable(this);
  late final $ZReadingsTableTable zReadingsTable = $ZReadingsTableTable(this);
  late final $PaymentMethodsTableTable paymentMethodsTable =
      $PaymentMethodsTableTable(this);
  late final $OrderEventsTableTable orderEventsTable = $OrderEventsTableTable(
    this,
  );
  late final UsersDao usersDao = UsersDao(this as AppDatabase);
  late final ProductsDao productsDao = ProductsDao(this as AppDatabase);
  late final SalesDao salesDao = SalesDao(this as AppDatabase);
  late final StoreInfoDao storeInfoDao = StoreInfoDao(this as AppDatabase);
  late final CashierAccountingDao cashierAccountingDao = CashierAccountingDao(
    this as AppDatabase,
  );
  late final OrderEventsDao orderEventsDao = OrderEventsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    usersTable,
    productGroupsTable,
    productsTable,
    productVariantsTable,
    modifierGroupsTable,
    modifierOptionsTable,
    productModifierGroupsTable,
    salesTable,
    saleItemsTable,
    saleItemModifiersTable,
    paymentsTable,
    refundsTable,
    refundItemsTable,
    storeInfoTable,
    xReadingsTable,
    dailyReportsTable,
    zReadingsTable,
    paymentMethodsTable,
    orderEventsTable,
  ];
}

typedef $$UsersTableTableCreateCompanionBuilder =
    UsersTableCompanion Function({
      Value<int> id,
      required String name,
      required String role,
      required String pinHash,
      Value<bool> isActive,
      Value<String?> employeeId,
      Value<String?> phone,
      Value<String?> avatarUrl,
      Value<bool> isPinChanged,
    });
typedef $$UsersTableTableUpdateCompanionBuilder =
    UsersTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> role,
      Value<String> pinHash,
      Value<bool> isActive,
      Value<String?> employeeId,
      Value<String?> phone,
      Value<String?> avatarUrl,
      Value<bool> isPinChanged,
    });

final class $$UsersTableTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTableTable, UsersTableData> {
  $$UsersTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SalesTableTable, List<SalesTableData>>
  _salesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.salesTable,
    aliasName: $_aliasNameGenerator(db.usersTable.id, db.salesTable.cashierId),
  );

  $$SalesTableTableProcessedTableManager get salesTableRefs {
    final manager = $$SalesTableTableTableManager(
      $_db,
      $_db.salesTable,
    ).filter((f) => f.cashierId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableTableFilterComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinChanged => $composableBuilder(
    column: $table.isPinChanged,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> salesTableRefs(
    Expression<bool> Function($$SalesTableTableFilterComposer f) f,
  ) {
    final $$SalesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.salesTable,
      getReferencedColumn: (t) => t.cashierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableTableFilterComposer(
            $db: $db,
            $table: $db.salesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinChanged => $composableBuilder(
    column: $table.isPinChanged,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<bool> get isPinChanged => $composableBuilder(
    column: $table.isPinChanged,
    builder: (column) => column,
  );

  Expression<T> salesTableRefs<T extends Object>(
    Expression<T> Function($$SalesTableTableAnnotationComposer a) f,
  ) {
    final $$SalesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.salesTable,
      getReferencedColumn: (t) => t.cashierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.salesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTableTable,
          UsersTableData,
          $$UsersTableTableFilterComposer,
          $$UsersTableTableOrderingComposer,
          $$UsersTableTableAnnotationComposer,
          $$UsersTableTableCreateCompanionBuilder,
          $$UsersTableTableUpdateCompanionBuilder,
          (UsersTableData, $$UsersTableTableReferences),
          UsersTableData,
          PrefetchHooks Function({bool salesTableRefs})
        > {
  $$UsersTableTableTableManager(_$AppDatabase db, $UsersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$UsersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$UsersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$UsersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> pinHash = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> employeeId = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<bool> isPinChanged = const Value.absent(),
              }) => UsersTableCompanion(
                id: id,
                name: name,
                role: role,
                pinHash: pinHash,
                isActive: isActive,
                employeeId: employeeId,
                phone: phone,
                avatarUrl: avatarUrl,
                isPinChanged: isPinChanged,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String role,
                required String pinHash,
                Value<bool> isActive = const Value.absent(),
                Value<String?> employeeId = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<bool> isPinChanged = const Value.absent(),
              }) => UsersTableCompanion.insert(
                id: id,
                name: name,
                role: role,
                pinHash: pinHash,
                isActive: isActive,
                employeeId: employeeId,
                phone: phone,
                avatarUrl: avatarUrl,
                isPinChanged: isPinChanged,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$UsersTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({salesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (salesTableRefs) db.salesTable],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (salesTableRefs)
                    await $_getPrefetchedData<
                      UsersTableData,
                      $UsersTableTable,
                      SalesTableData
                    >(
                      currentTable: table,
                      referencedTable: $$UsersTableTableReferences
                          ._salesTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).salesTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.cashierId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UsersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTableTable,
      UsersTableData,
      $$UsersTableTableFilterComposer,
      $$UsersTableTableOrderingComposer,
      $$UsersTableTableAnnotationComposer,
      $$UsersTableTableCreateCompanionBuilder,
      $$UsersTableTableUpdateCompanionBuilder,
      (UsersTableData, $$UsersTableTableReferences),
      UsersTableData,
      PrefetchHooks Function({bool salesTableRefs})
    >;
typedef $$ProductGroupsTableTableCreateCompanionBuilder =
    ProductGroupsTableCompanion Function({
      Value<int> id,
      required String name,
      Value<int> sortOrder,
      Value<bool> isActive,
    });
typedef $$ProductGroupsTableTableUpdateCompanionBuilder =
    ProductGroupsTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<bool> isActive,
    });

final class $$ProductGroupsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProductGroupsTableTable,
          ProductGroupsTableData
        > {
  $$ProductGroupsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ProductsTableTable, List<ProductsTableData>>
  _productsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.productsTable,
    aliasName: $_aliasNameGenerator(
      db.productGroupsTable.id,
      db.productsTable.groupId,
    ),
  );

  $$ProductsTableTableProcessedTableManager get productsTableRefs {
    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductGroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductGroupsTableTable> {
  $$ProductGroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productsTableRefs(
    Expression<bool> Function($$ProductsTableTableFilterComposer f) f,
  ) {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductGroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductGroupsTableTable> {
  $$ProductGroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductGroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductGroupsTableTable> {
  $$ProductGroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> productsTableRefs<T extends Object>(
    Expression<T> Function($$ProductsTableTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductGroupsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductGroupsTableTable,
          ProductGroupsTableData,
          $$ProductGroupsTableTableFilterComposer,
          $$ProductGroupsTableTableOrderingComposer,
          $$ProductGroupsTableTableAnnotationComposer,
          $$ProductGroupsTableTableCreateCompanionBuilder,
          $$ProductGroupsTableTableUpdateCompanionBuilder,
          (ProductGroupsTableData, $$ProductGroupsTableTableReferences),
          ProductGroupsTableData,
          PrefetchHooks Function({bool productsTableRefs})
        > {
  $$ProductGroupsTableTableTableManager(
    _$AppDatabase db,
    $ProductGroupsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ProductGroupsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$ProductGroupsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ProductGroupsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ProductGroupsTableCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ProductGroupsTableCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                isActive: isActive,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ProductGroupsTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({productsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (productsTableRefs) db.productsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productsTableRefs)
                    await $_getPrefetchedData<
                      ProductGroupsTableData,
                      $ProductGroupsTableTable,
                      ProductsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$ProductGroupsTableTableReferences
                          ._productsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$ProductGroupsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).productsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.groupId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductGroupsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductGroupsTableTable,
      ProductGroupsTableData,
      $$ProductGroupsTableTableFilterComposer,
      $$ProductGroupsTableTableOrderingComposer,
      $$ProductGroupsTableTableAnnotationComposer,
      $$ProductGroupsTableTableCreateCompanionBuilder,
      $$ProductGroupsTableTableUpdateCompanionBuilder,
      (ProductGroupsTableData, $$ProductGroupsTableTableReferences),
      ProductGroupsTableData,
      PrefetchHooks Function({bool productsTableRefs})
    >;
typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<int> id,
      required int groupId,
      required String name,
      Value<bool> isAvailable,
      Value<String?> imageUrl,
      Value<int> sortOrder,
    });
typedef $$ProductsTableTableUpdateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<int> id,
      Value<int> groupId,
      Value<String> name,
      Value<bool> isAvailable,
      Value<String?> imageUrl,
      Value<int> sortOrder,
    });

final class $$ProductsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $ProductsTableTable, ProductsTableData> {
  $$ProductsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductGroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.productGroupsTable.createAlias(
        $_aliasNameGenerator(
          db.productsTable.groupId,
          db.productGroupsTable.id,
        ),
      );

  $$ProductGroupsTableTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$ProductGroupsTableTableTableManager(
      $_db,
      $_db.productGroupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ProductVariantsTableTable,
    List<ProductVariantsTableData>
  >
  _productVariantsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.productVariantsTable,
        aliasName: $_aliasNameGenerator(
          db.productsTable.id,
          db.productVariantsTable.productId,
        ),
      );

  $$ProductVariantsTableTableProcessedTableManager
  get productVariantsTableRefs {
    final manager = $$ProductVariantsTableTableTableManager(
      $_db,
      $_db.productVariantsTable,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _productVariantsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ProductModifierGroupsTableTable,
    List<ProductModifierGroupsTableData>
  >
  _productModifierGroupsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.productModifierGroupsTable,
        aliasName: $_aliasNameGenerator(
          db.productsTable.id,
          db.productModifierGroupsTable.productId,
        ),
      );

  $$ProductModifierGroupsTableTableProcessedTableManager
  get productModifierGroupsTableRefs {
    final manager = $$ProductModifierGroupsTableTableTableManager(
      $_db,
      $_db.productModifierGroupsTable,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _productModifierGroupsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SaleItemsTableTable, List<SaleItemsTableData>>
  _saleItemsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleItemsTable,
    aliasName: $_aliasNameGenerator(
      db.productsTable.id,
      db.saleItemsTable.productId,
    ),
  );

  $$SaleItemsTableTableProcessedTableManager get saleItemsTableRefs {
    final manager = $$SaleItemsTableTableTableManager(
      $_db,
      $_db.saleItemsTable,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_saleItemsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductGroupsTableTableFilterComposer get groupId {
    final $$ProductGroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.productGroupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductGroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.productGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> productVariantsTableRefs(
    Expression<bool> Function($$ProductVariantsTableTableFilterComposer f) f,
  ) {
    final $$ProductVariantsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productVariantsTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductVariantsTableTableFilterComposer(
            $db: $db,
            $table: $db.productVariantsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> productModifierGroupsTableRefs(
    Expression<bool> Function($$ProductModifierGroupsTableTableFilterComposer f)
    f,
  ) {
    final $$ProductModifierGroupsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.productModifierGroupsTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProductModifierGroupsTableTableFilterComposer(
                $db: $db,
                $table: $db.productModifierGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> saleItemsTableRefs(
    Expression<bool> Function($$SaleItemsTableTableFilterComposer f) f,
  ) {
    final $$SaleItemsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleItemsTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableTableFilterComposer(
            $db: $db,
            $table: $db.saleItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductGroupsTableTableOrderingComposer get groupId {
    final $$ProductGroupsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.productGroupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductGroupsTableTableOrderingComposer(
            $db: $db,
            $table: $db.productGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$ProductGroupsTableTableAnnotationComposer get groupId {
    final $$ProductGroupsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.groupId,
          referencedTable: $db.productGroupsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProductGroupsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.productGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> productVariantsTableRefs<T extends Object>(
    Expression<T> Function($$ProductVariantsTableTableAnnotationComposer a) f,
  ) {
    final $$ProductVariantsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.productVariantsTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProductVariantsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.productVariantsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> productModifierGroupsTableRefs<T extends Object>(
    Expression<T> Function(
      $$ProductModifierGroupsTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$ProductModifierGroupsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.productModifierGroupsTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProductModifierGroupsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.productModifierGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> saleItemsTableRefs<T extends Object>(
    Expression<T> Function($$SaleItemsTableTableAnnotationComposer a) f,
  ) {
    final $$SaleItemsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleItemsTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.saleItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTableTable,
          ProductsTableData,
          $$ProductsTableTableFilterComposer,
          $$ProductsTableTableOrderingComposer,
          $$ProductsTableTableAnnotationComposer,
          $$ProductsTableTableCreateCompanionBuilder,
          $$ProductsTableTableUpdateCompanionBuilder,
          (ProductsTableData, $$ProductsTableTableReferences),
          ProductsTableData,
          PrefetchHooks Function({
            bool groupId,
            bool productVariantsTableRefs,
            bool productModifierGroupsTableRefs,
            bool saleItemsTableRefs,
          })
        > {
  $$ProductsTableTableTableManager(_$AppDatabase db, $ProductsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$ProductsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ProductsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ProductsTableCompanion(
                id: id,
                groupId: groupId,
                name: name,
                isAvailable: isAvailable,
                imageUrl: imageUrl,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int groupId,
                required String name,
                Value<bool> isAvailable = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ProductsTableCompanion.insert(
                id: id,
                groupId: groupId,
                name: name,
                isAvailable: isAvailable,
                imageUrl: imageUrl,
                sortOrder: sortOrder,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ProductsTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            groupId = false,
            productVariantsTableRefs = false,
            productModifierGroupsTableRefs = false,
            saleItemsTableRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (productVariantsTableRefs) db.productVariantsTable,
                if (productModifierGroupsTableRefs)
                  db.productModifierGroupsTable,
                if (saleItemsTableRefs) db.saleItemsTable,
              ],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (groupId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $$ProductsTableTableReferences
                                ._groupIdTable(db),
                            referencedColumn:
                                $$ProductsTableTableReferences
                                    ._groupIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productVariantsTableRefs)
                    await $_getPrefetchedData<
                      ProductsTableData,
                      $ProductsTableTable,
                      ProductVariantsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$ProductsTableTableReferences
                          ._productVariantsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$ProductsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).productVariantsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.productId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (productModifierGroupsTableRefs)
                    await $_getPrefetchedData<
                      ProductsTableData,
                      $ProductsTableTable,
                      ProductModifierGroupsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$ProductsTableTableReferences
                          ._productModifierGroupsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$ProductsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).productModifierGroupsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.productId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (saleItemsTableRefs)
                    await $_getPrefetchedData<
                      ProductsTableData,
                      $ProductsTableTable,
                      SaleItemsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$ProductsTableTableReferences
                          ._saleItemsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$ProductsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).saleItemsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.productId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTableTable,
      ProductsTableData,
      $$ProductsTableTableFilterComposer,
      $$ProductsTableTableOrderingComposer,
      $$ProductsTableTableAnnotationComposer,
      $$ProductsTableTableCreateCompanionBuilder,
      $$ProductsTableTableUpdateCompanionBuilder,
      (ProductsTableData, $$ProductsTableTableReferences),
      ProductsTableData,
      PrefetchHooks Function({
        bool groupId,
        bool productVariantsTableRefs,
        bool productModifierGroupsTableRefs,
        bool saleItemsTableRefs,
      })
    >;
typedef $$ProductVariantsTableTableCreateCompanionBuilder =
    ProductVariantsTableCompanion Function({
      Value<int> id,
      required int productId,
      required String name,
      required double price,
      Value<bool> isDefault,
      Value<bool> isActive,
    });
typedef $$ProductVariantsTableTableUpdateCompanionBuilder =
    ProductVariantsTableCompanion Function({
      Value<int> id,
      Value<int> productId,
      Value<String> name,
      Value<double> price,
      Value<bool> isDefault,
      Value<bool> isActive,
    });

final class $$ProductVariantsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProductVariantsTableTable,
          ProductVariantsTableData
        > {
  $$ProductVariantsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTableTable _productIdTable(_$AppDatabase db) =>
      db.productsTable.createAlias(
        $_aliasNameGenerator(
          db.productVariantsTable.productId,
          db.productsTable.id,
        ),
      );

  $$ProductsTableTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProductVariantsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductVariantsTableTable> {
  $$ProductVariantsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableTableFilterComposer get productId {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductVariantsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductVariantsTableTable> {
  $$ProductVariantsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableTableOrderingComposer get productId {
    final $$ProductsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableOrderingComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductVariantsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductVariantsTableTable> {
  $$ProductVariantsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$ProductsTableTableAnnotationComposer get productId {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductVariantsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductVariantsTableTable,
          ProductVariantsTableData,
          $$ProductVariantsTableTableFilterComposer,
          $$ProductVariantsTableTableOrderingComposer,
          $$ProductVariantsTableTableAnnotationComposer,
          $$ProductVariantsTableTableCreateCompanionBuilder,
          $$ProductVariantsTableTableUpdateCompanionBuilder,
          (ProductVariantsTableData, $$ProductVariantsTableTableReferences),
          ProductVariantsTableData,
          PrefetchHooks Function({bool productId})
        > {
  $$ProductVariantsTableTableTableManager(
    _$AppDatabase db,
    $ProductVariantsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ProductVariantsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$ProductVariantsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ProductVariantsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ProductVariantsTableCompanion(
                id: id,
                productId: productId,
                name: name,
                price: price,
                isDefault: isDefault,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                required String name,
                required double price,
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ProductVariantsTableCompanion.insert(
                id: id,
                productId: productId,
                name: name,
                price: price,
                isDefault: isDefault,
                isActive: isActive,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ProductVariantsTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (productId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.productId,
                            referencedTable:
                                $$ProductVariantsTableTableReferences
                                    ._productIdTable(db),
                            referencedColumn:
                                $$ProductVariantsTableTableReferences
                                    ._productIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProductVariantsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductVariantsTableTable,
      ProductVariantsTableData,
      $$ProductVariantsTableTableFilterComposer,
      $$ProductVariantsTableTableOrderingComposer,
      $$ProductVariantsTableTableAnnotationComposer,
      $$ProductVariantsTableTableCreateCompanionBuilder,
      $$ProductVariantsTableTableUpdateCompanionBuilder,
      (ProductVariantsTableData, $$ProductVariantsTableTableReferences),
      ProductVariantsTableData,
      PrefetchHooks Function({bool productId})
    >;
typedef $$ModifierGroupsTableTableCreateCompanionBuilder =
    ModifierGroupsTableCompanion Function({
      Value<int> id,
      required String name,
      Value<bool> isRequired,
      Value<int> maxSelections,
      Value<bool> isActive,
    });
typedef $$ModifierGroupsTableTableUpdateCompanionBuilder =
    ModifierGroupsTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<bool> isRequired,
      Value<int> maxSelections,
      Value<bool> isActive,
    });

final class $$ModifierGroupsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ModifierGroupsTableTable,
          ModifierGroupsTableData
        > {
  $$ModifierGroupsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $ModifierOptionsTableTable,
    List<ModifierOptionsTableData>
  >
  _modifierOptionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.modifierOptionsTable,
        aliasName: $_aliasNameGenerator(
          db.modifierGroupsTable.id,
          db.modifierOptionsTable.groupId,
        ),
      );

  $$ModifierOptionsTableTableProcessedTableManager
  get modifierOptionsTableRefs {
    final manager = $$ModifierOptionsTableTableTableManager(
      $_db,
      $_db.modifierOptionsTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _modifierOptionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ProductModifierGroupsTableTable,
    List<ProductModifierGroupsTableData>
  >
  _productModifierGroupsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.productModifierGroupsTable,
        aliasName: $_aliasNameGenerator(
          db.modifierGroupsTable.id,
          db.productModifierGroupsTable.modifierGroupId,
        ),
      );

  $$ProductModifierGroupsTableTableProcessedTableManager
  get productModifierGroupsTableRefs {
    final manager = $$ProductModifierGroupsTableTableTableManager(
      $_db,
      $_db.productModifierGroupsTable,
    ).filter((f) => f.modifierGroupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _productModifierGroupsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ModifierGroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ModifierGroupsTableTable> {
  $$ModifierGroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxSelections => $composableBuilder(
    column: $table.maxSelections,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> modifierOptionsTableRefs(
    Expression<bool> Function($$ModifierOptionsTableTableFilterComposer f) f,
  ) {
    final $$ModifierOptionsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.modifierOptionsTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ModifierOptionsTableTableFilterComposer(
            $db: $db,
            $table: $db.modifierOptionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> productModifierGroupsTableRefs(
    Expression<bool> Function($$ProductModifierGroupsTableTableFilterComposer f)
    f,
  ) {
    final $$ProductModifierGroupsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.productModifierGroupsTable,
          getReferencedColumn: (t) => t.modifierGroupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProductModifierGroupsTableTableFilterComposer(
                $db: $db,
                $table: $db.productModifierGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ModifierGroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ModifierGroupsTableTable> {
  $$ModifierGroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxSelections => $composableBuilder(
    column: $table.maxSelections,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModifierGroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModifierGroupsTableTable> {
  $$ModifierGroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxSelections => $composableBuilder(
    column: $table.maxSelections,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> modifierOptionsTableRefs<T extends Object>(
    Expression<T> Function($$ModifierOptionsTableTableAnnotationComposer a) f,
  ) {
    final $$ModifierOptionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.modifierOptionsTable,
          getReferencedColumn: (t) => t.groupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ModifierOptionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.modifierOptionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> productModifierGroupsTableRefs<T extends Object>(
    Expression<T> Function(
      $$ProductModifierGroupsTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$ProductModifierGroupsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.productModifierGroupsTable,
          getReferencedColumn: (t) => t.modifierGroupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProductModifierGroupsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.productModifierGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ModifierGroupsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModifierGroupsTableTable,
          ModifierGroupsTableData,
          $$ModifierGroupsTableTableFilterComposer,
          $$ModifierGroupsTableTableOrderingComposer,
          $$ModifierGroupsTableTableAnnotationComposer,
          $$ModifierGroupsTableTableCreateCompanionBuilder,
          $$ModifierGroupsTableTableUpdateCompanionBuilder,
          (ModifierGroupsTableData, $$ModifierGroupsTableTableReferences),
          ModifierGroupsTableData,
          PrefetchHooks Function({
            bool modifierOptionsTableRefs,
            bool productModifierGroupsTableRefs,
          })
        > {
  $$ModifierGroupsTableTableTableManager(
    _$AppDatabase db,
    $ModifierGroupsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ModifierGroupsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$ModifierGroupsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ModifierGroupsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isRequired = const Value.absent(),
                Value<int> maxSelections = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ModifierGroupsTableCompanion(
                id: id,
                name: name,
                isRequired: isRequired,
                maxSelections: maxSelections,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> isRequired = const Value.absent(),
                Value<int> maxSelections = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ModifierGroupsTableCompanion.insert(
                id: id,
                name: name,
                isRequired: isRequired,
                maxSelections: maxSelections,
                isActive: isActive,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ModifierGroupsTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            modifierOptionsTableRefs = false,
            productModifierGroupsTableRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (modifierOptionsTableRefs) db.modifierOptionsTable,
                if (productModifierGroupsTableRefs)
                  db.productModifierGroupsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (modifierOptionsTableRefs)
                    await $_getPrefetchedData<
                      ModifierGroupsTableData,
                      $ModifierGroupsTableTable,
                      ModifierOptionsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$ModifierGroupsTableTableReferences
                          ._modifierOptionsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$ModifierGroupsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).modifierOptionsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.groupId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (productModifierGroupsTableRefs)
                    await $_getPrefetchedData<
                      ModifierGroupsTableData,
                      $ModifierGroupsTableTable,
                      ProductModifierGroupsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$ModifierGroupsTableTableReferences
                          ._productModifierGroupsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$ModifierGroupsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).productModifierGroupsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.modifierGroupId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ModifierGroupsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModifierGroupsTableTable,
      ModifierGroupsTableData,
      $$ModifierGroupsTableTableFilterComposer,
      $$ModifierGroupsTableTableOrderingComposer,
      $$ModifierGroupsTableTableAnnotationComposer,
      $$ModifierGroupsTableTableCreateCompanionBuilder,
      $$ModifierGroupsTableTableUpdateCompanionBuilder,
      (ModifierGroupsTableData, $$ModifierGroupsTableTableReferences),
      ModifierGroupsTableData,
      PrefetchHooks Function({
        bool modifierOptionsTableRefs,
        bool productModifierGroupsTableRefs,
      })
    >;
typedef $$ModifierOptionsTableTableCreateCompanionBuilder =
    ModifierOptionsTableCompanion Function({
      Value<int> id,
      required int groupId,
      required String name,
      Value<double> additionalPrice,
      Value<bool> isActive,
    });
typedef $$ModifierOptionsTableTableUpdateCompanionBuilder =
    ModifierOptionsTableCompanion Function({
      Value<int> id,
      Value<int> groupId,
      Value<String> name,
      Value<double> additionalPrice,
      Value<bool> isActive,
    });

final class $$ModifierOptionsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ModifierOptionsTableTable,
          ModifierOptionsTableData
        > {
  $$ModifierOptionsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ModifierGroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.modifierGroupsTable.createAlias(
        $_aliasNameGenerator(
          db.modifierOptionsTable.groupId,
          db.modifierGroupsTable.id,
        ),
      );

  $$ModifierGroupsTableTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$ModifierGroupsTableTableTableManager(
      $_db,
      $_db.modifierGroupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ModifierOptionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ModifierOptionsTableTable> {
  $$ModifierOptionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get additionalPrice => $composableBuilder(
    column: $table.additionalPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$ModifierGroupsTableTableFilterComposer get groupId {
    final $$ModifierGroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.modifierGroupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ModifierGroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.modifierGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ModifierOptionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ModifierOptionsTableTable> {
  $$ModifierOptionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get additionalPrice => $composableBuilder(
    column: $table.additionalPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$ModifierGroupsTableTableOrderingComposer get groupId {
    final $$ModifierGroupsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.groupId,
          referencedTable: $db.modifierGroupsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ModifierGroupsTableTableOrderingComposer(
                $db: $db,
                $table: $db.modifierGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ModifierOptionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModifierOptionsTableTable> {
  $$ModifierOptionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get additionalPrice => $composableBuilder(
    column: $table.additionalPrice,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$ModifierGroupsTableTableAnnotationComposer get groupId {
    final $$ModifierGroupsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.groupId,
          referencedTable: $db.modifierGroupsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ModifierGroupsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.modifierGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ModifierOptionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModifierOptionsTableTable,
          ModifierOptionsTableData,
          $$ModifierOptionsTableTableFilterComposer,
          $$ModifierOptionsTableTableOrderingComposer,
          $$ModifierOptionsTableTableAnnotationComposer,
          $$ModifierOptionsTableTableCreateCompanionBuilder,
          $$ModifierOptionsTableTableUpdateCompanionBuilder,
          (ModifierOptionsTableData, $$ModifierOptionsTableTableReferences),
          ModifierOptionsTableData,
          PrefetchHooks Function({bool groupId})
        > {
  $$ModifierOptionsTableTableTableManager(
    _$AppDatabase db,
    $ModifierOptionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ModifierOptionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$ModifierOptionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ModifierOptionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> additionalPrice = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ModifierOptionsTableCompanion(
                id: id,
                groupId: groupId,
                name: name,
                additionalPrice: additionalPrice,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int groupId,
                required String name,
                Value<double> additionalPrice = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ModifierOptionsTableCompanion.insert(
                id: id,
                groupId: groupId,
                name: name,
                additionalPrice: additionalPrice,
                isActive: isActive,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ModifierOptionsTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (groupId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable:
                                $$ModifierOptionsTableTableReferences
                                    ._groupIdTable(db),
                            referencedColumn:
                                $$ModifierOptionsTableTableReferences
                                    ._groupIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ModifierOptionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModifierOptionsTableTable,
      ModifierOptionsTableData,
      $$ModifierOptionsTableTableFilterComposer,
      $$ModifierOptionsTableTableOrderingComposer,
      $$ModifierOptionsTableTableAnnotationComposer,
      $$ModifierOptionsTableTableCreateCompanionBuilder,
      $$ModifierOptionsTableTableUpdateCompanionBuilder,
      (ModifierOptionsTableData, $$ModifierOptionsTableTableReferences),
      ModifierOptionsTableData,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$ProductModifierGroupsTableTableCreateCompanionBuilder =
    ProductModifierGroupsTableCompanion Function({
      Value<int> id,
      required int productId,
      required int modifierGroupId,
    });
typedef $$ProductModifierGroupsTableTableUpdateCompanionBuilder =
    ProductModifierGroupsTableCompanion Function({
      Value<int> id,
      Value<int> productId,
      Value<int> modifierGroupId,
    });

final class $$ProductModifierGroupsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProductModifierGroupsTableTable,
          ProductModifierGroupsTableData
        > {
  $$ProductModifierGroupsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTableTable _productIdTable(_$AppDatabase db) =>
      db.productsTable.createAlias(
        $_aliasNameGenerator(
          db.productModifierGroupsTable.productId,
          db.productsTable.id,
        ),
      );

  $$ProductsTableTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ModifierGroupsTableTable _modifierGroupIdTable(_$AppDatabase db) =>
      db.modifierGroupsTable.createAlias(
        $_aliasNameGenerator(
          db.productModifierGroupsTable.modifierGroupId,
          db.modifierGroupsTable.id,
        ),
      );

  $$ModifierGroupsTableTableProcessedTableManager get modifierGroupId {
    final $_column = $_itemColumn<int>('modifier_group_id')!;

    final manager = $$ModifierGroupsTableTableTableManager(
      $_db,
      $_db.modifierGroupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_modifierGroupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProductModifierGroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductModifierGroupsTableTable> {
  $$ProductModifierGroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableTableFilterComposer get productId {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ModifierGroupsTableTableFilterComposer get modifierGroupId {
    final $$ModifierGroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modifierGroupId,
      referencedTable: $db.modifierGroupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ModifierGroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.modifierGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductModifierGroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductModifierGroupsTableTable> {
  $$ProductModifierGroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableTableOrderingComposer get productId {
    final $$ProductsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableOrderingComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ModifierGroupsTableTableOrderingComposer get modifierGroupId {
    final $$ModifierGroupsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.modifierGroupId,
          referencedTable: $db.modifierGroupsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ModifierGroupsTableTableOrderingComposer(
                $db: $db,
                $table: $db.modifierGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ProductModifierGroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductModifierGroupsTableTable> {
  $$ProductModifierGroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  $$ProductsTableTableAnnotationComposer get productId {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ModifierGroupsTableTableAnnotationComposer get modifierGroupId {
    final $$ModifierGroupsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.modifierGroupId,
          referencedTable: $db.modifierGroupsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ModifierGroupsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.modifierGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ProductModifierGroupsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductModifierGroupsTableTable,
          ProductModifierGroupsTableData,
          $$ProductModifierGroupsTableTableFilterComposer,
          $$ProductModifierGroupsTableTableOrderingComposer,
          $$ProductModifierGroupsTableTableAnnotationComposer,
          $$ProductModifierGroupsTableTableCreateCompanionBuilder,
          $$ProductModifierGroupsTableTableUpdateCompanionBuilder,
          (
            ProductModifierGroupsTableData,
            $$ProductModifierGroupsTableTableReferences,
          ),
          ProductModifierGroupsTableData,
          PrefetchHooks Function({bool productId, bool modifierGroupId})
        > {
  $$ProductModifierGroupsTableTableTableManager(
    _$AppDatabase db,
    $ProductModifierGroupsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ProductModifierGroupsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$ProductModifierGroupsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ProductModifierGroupsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<int> modifierGroupId = const Value.absent(),
              }) => ProductModifierGroupsTableCompanion(
                id: id,
                productId: productId,
                modifierGroupId: modifierGroupId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                required int modifierGroupId,
              }) => ProductModifierGroupsTableCompanion.insert(
                id: id,
                productId: productId,
                modifierGroupId: modifierGroupId,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ProductModifierGroupsTableTableReferences(
                            db,
                            table,
                            e,
                          ),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            productId = false,
            modifierGroupId = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (productId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.productId,
                            referencedTable:
                                $$ProductModifierGroupsTableTableReferences
                                    ._productIdTable(db),
                            referencedColumn:
                                $$ProductModifierGroupsTableTableReferences
                                    ._productIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (modifierGroupId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.modifierGroupId,
                            referencedTable:
                                $$ProductModifierGroupsTableTableReferences
                                    ._modifierGroupIdTable(db),
                            referencedColumn:
                                $$ProductModifierGroupsTableTableReferences
                                    ._modifierGroupIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProductModifierGroupsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductModifierGroupsTableTable,
      ProductModifierGroupsTableData,
      $$ProductModifierGroupsTableTableFilterComposer,
      $$ProductModifierGroupsTableTableOrderingComposer,
      $$ProductModifierGroupsTableTableAnnotationComposer,
      $$ProductModifierGroupsTableTableCreateCompanionBuilder,
      $$ProductModifierGroupsTableTableUpdateCompanionBuilder,
      (
        ProductModifierGroupsTableData,
        $$ProductModifierGroupsTableTableReferences,
      ),
      ProductModifierGroupsTableData,
      PrefetchHooks Function({bool productId, bool modifierGroupId})
    >;
typedef $$SalesTableTableCreateCompanionBuilder =
    SalesTableCompanion Function({
      Value<int> id,
      required int cashierId,
      required double total,
      Value<double> discount,
      required String status,
      required String type,
      required DateTime createdAt,
      Value<String?> soNumber,
      Value<String?> voidReason,
      Value<DateTime?> voidedAt,
    });
typedef $$SalesTableTableUpdateCompanionBuilder =
    SalesTableCompanion Function({
      Value<int> id,
      Value<int> cashierId,
      Value<double> total,
      Value<double> discount,
      Value<String> status,
      Value<String> type,
      Value<DateTime> createdAt,
      Value<String?> soNumber,
      Value<String?> voidReason,
      Value<DateTime?> voidedAt,
    });

final class $$SalesTableTableReferences
    extends BaseReferences<_$AppDatabase, $SalesTableTable, SalesTableData> {
  $$SalesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTableTable _cashierIdTable(_$AppDatabase db) =>
      db.usersTable.createAlias(
        $_aliasNameGenerator(db.salesTable.cashierId, db.usersTable.id),
      );

  $$UsersTableTableProcessedTableManager get cashierId {
    final $_column = $_itemColumn<int>('cashier_id')!;

    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cashierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SaleItemsTableTable, List<SaleItemsTableData>>
  _saleItemsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleItemsTable,
    aliasName: $_aliasNameGenerator(db.salesTable.id, db.saleItemsTable.saleId),
  );

  $$SaleItemsTableTableProcessedTableManager get saleItemsTableRefs {
    final manager = $$SaleItemsTableTableTableManager(
      $_db,
      $_db.saleItemsTable,
    ).filter((f) => f.saleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_saleItemsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentsTableTable, List<PaymentsTableData>>
  _paymentsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.paymentsTable,
    aliasName: $_aliasNameGenerator(db.salesTable.id, db.paymentsTable.saleId),
  );

  $$PaymentsTableTableProcessedTableManager get paymentsTableRefs {
    final manager = $$PaymentsTableTableTableManager(
      $_db,
      $_db.paymentsTable,
    ).filter((f) => f.saleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RefundsTableTable, List<RefundsTableData>>
  _refundsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.refundsTable,
    aliasName: $_aliasNameGenerator(db.salesTable.id, db.refundsTable.saleId),
  );

  $$RefundsTableTableProcessedTableManager get refundsTableRefs {
    final manager = $$RefundsTableTableTableManager(
      $_db,
      $_db.refundsTable,
    ).filter((f) => f.saleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_refundsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SalesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SalesTableTable> {
  $$SalesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soNumber => $composableBuilder(
    column: $table.soNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableTableFilterComposer get cashierId {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> saleItemsTableRefs(
    Expression<bool> Function($$SaleItemsTableTableFilterComposer f) f,
  ) {
    final $$SaleItemsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleItemsTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableTableFilterComposer(
            $db: $db,
            $table: $db.saleItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentsTableRefs(
    Expression<bool> Function($$PaymentsTableTableFilterComposer f) f,
  ) {
    final $$PaymentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.paymentsTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableTableFilterComposer(
            $db: $db,
            $table: $db.paymentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> refundsTableRefs(
    Expression<bool> Function($$RefundsTableTableFilterComposer f) f,
  ) {
    final $$RefundsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refundsTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundsTableTableFilterComposer(
            $db: $db,
            $table: $db.refundsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTableTable> {
  $$SalesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soNumber => $composableBuilder(
    column: $table.soNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableTableOrderingComposer get cashierId {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTableTable> {
  $$SalesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get soNumber =>
      $composableBuilder(column: $table.soNumber, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);

  $$UsersTableTableAnnotationComposer get cashierId {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> saleItemsTableRefs<T extends Object>(
    Expression<T> Function($$SaleItemsTableTableAnnotationComposer a) f,
  ) {
    final $$SaleItemsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleItemsTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.saleItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentsTableRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.paymentsTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> refundsTableRefs<T extends Object>(
    Expression<T> Function($$RefundsTableTableAnnotationComposer a) f,
  ) {
    final $$RefundsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refundsTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.refundsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesTableTable,
          SalesTableData,
          $$SalesTableTableFilterComposer,
          $$SalesTableTableOrderingComposer,
          $$SalesTableTableAnnotationComposer,
          $$SalesTableTableCreateCompanionBuilder,
          $$SalesTableTableUpdateCompanionBuilder,
          (SalesTableData, $$SalesTableTableReferences),
          SalesTableData,
          PrefetchHooks Function({
            bool cashierId,
            bool saleItemsTableRefs,
            bool paymentsTableRefs,
            bool refundsTableRefs,
          })
        > {
  $$SalesTableTableTableManager(_$AppDatabase db, $SalesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SalesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SalesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SalesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cashierId = const Value.absent(),
                Value<double> total = const Value.absent(),
                Value<double> discount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> soNumber = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
              }) => SalesTableCompanion(
                id: id,
                cashierId: cashierId,
                total: total,
                discount: discount,
                status: status,
                type: type,
                createdAt: createdAt,
                soNumber: soNumber,
                voidReason: voidReason,
                voidedAt: voidedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cashierId,
                required double total,
                Value<double> discount = const Value.absent(),
                required String status,
                required String type,
                required DateTime createdAt,
                Value<String?> soNumber = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
              }) => SalesTableCompanion.insert(
                id: id,
                cashierId: cashierId,
                total: total,
                discount: discount,
                status: status,
                type: type,
                createdAt: createdAt,
                soNumber: soNumber,
                voidReason: voidReason,
                voidedAt: voidedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$SalesTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            cashierId = false,
            saleItemsTableRefs = false,
            paymentsTableRefs = false,
            refundsTableRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (saleItemsTableRefs) db.saleItemsTable,
                if (paymentsTableRefs) db.paymentsTable,
                if (refundsTableRefs) db.refundsTable,
              ],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (cashierId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.cashierId,
                            referencedTable: $$SalesTableTableReferences
                                ._cashierIdTable(db),
                            referencedColumn:
                                $$SalesTableTableReferences
                                    ._cashierIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (saleItemsTableRefs)
                    await $_getPrefetchedData<
                      SalesTableData,
                      $SalesTableTable,
                      SaleItemsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$SalesTableTableReferences
                          ._saleItemsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$SalesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).saleItemsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.saleId == item.id),
                      typedResults: items,
                    ),
                  if (paymentsTableRefs)
                    await $_getPrefetchedData<
                      SalesTableData,
                      $SalesTableTable,
                      PaymentsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$SalesTableTableReferences
                          ._paymentsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$SalesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.saleId == item.id),
                      typedResults: items,
                    ),
                  if (refundsTableRefs)
                    await $_getPrefetchedData<
                      SalesTableData,
                      $SalesTableTable,
                      RefundsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$SalesTableTableReferences
                          ._refundsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$SalesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).refundsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.saleId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SalesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesTableTable,
      SalesTableData,
      $$SalesTableTableFilterComposer,
      $$SalesTableTableOrderingComposer,
      $$SalesTableTableAnnotationComposer,
      $$SalesTableTableCreateCompanionBuilder,
      $$SalesTableTableUpdateCompanionBuilder,
      (SalesTableData, $$SalesTableTableReferences),
      SalesTableData,
      PrefetchHooks Function({
        bool cashierId,
        bool saleItemsTableRefs,
        bool paymentsTableRefs,
        bool refundsTableRefs,
      })
    >;
typedef $$SaleItemsTableTableCreateCompanionBuilder =
    SaleItemsTableCompanion Function({
      Value<int> id,
      required int saleId,
      required int productId,
      required String variantName,
      required int qty,
      required double unitPrice,
      Value<String?> discountType,
      Value<String?> discountBeneficiaryId,
      Value<String?> discountBeneficiaryName,
      Value<double?> discountAmount,
      Value<double?> vatExemptAmount,
    });
typedef $$SaleItemsTableTableUpdateCompanionBuilder =
    SaleItemsTableCompanion Function({
      Value<int> id,
      Value<int> saleId,
      Value<int> productId,
      Value<String> variantName,
      Value<int> qty,
      Value<double> unitPrice,
      Value<String?> discountType,
      Value<String?> discountBeneficiaryId,
      Value<String?> discountBeneficiaryName,
      Value<double?> discountAmount,
      Value<double?> vatExemptAmount,
    });

final class $$SaleItemsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SaleItemsTableTable,
          SaleItemsTableData
        > {
  $$SaleItemsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SalesTableTable _saleIdTable(_$AppDatabase db) =>
      db.salesTable.createAlias(
        $_aliasNameGenerator(db.saleItemsTable.saleId, db.salesTable.id),
      );

  $$SalesTableTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<int>('sale_id')!;

    final manager = $$SalesTableTableTableManager(
      $_db,
      $_db.salesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTableTable _productIdTable(_$AppDatabase db) =>
      db.productsTable.createAlias(
        $_aliasNameGenerator(db.saleItemsTable.productId, db.productsTable.id),
      );

  $$ProductsTableTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $SaleItemModifiersTableTable,
    List<SaleItemModifiersTableData>
  >
  _saleItemModifiersTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.saleItemModifiersTable,
        aliasName: $_aliasNameGenerator(
          db.saleItemsTable.id,
          db.saleItemModifiersTable.itemId,
        ),
      );

  $$SaleItemModifiersTableTableProcessedTableManager
  get saleItemModifiersTableRefs {
    final manager = $$SaleItemModifiersTableTableTableManager(
      $_db,
      $_db.saleItemModifiersTable,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _saleItemModifiersTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RefundItemsTableTable, List<RefundItemsTableData>>
  _refundItemsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.refundItemsTable,
    aliasName: $_aliasNameGenerator(
      db.saleItemsTable.id,
      db.refundItemsTable.saleItemId,
    ),
  );

  $$RefundItemsTableTableProcessedTableManager get refundItemsTableRefs {
    final manager = $$RefundItemsTableTableTableManager(
      $_db,
      $_db.refundItemsTable,
    ).filter((f) => f.saleItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _refundItemsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SaleItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SaleItemsTableTable> {
  $$SaleItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountBeneficiaryId => $composableBuilder(
    column: $table.discountBeneficiaryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountBeneficiaryName => $composableBuilder(
    column: $table.discountBeneficiaryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatExemptAmount => $composableBuilder(
    column: $table.vatExemptAmount,
    builder: (column) => ColumnFilters(column),
  );

  $$SalesTableTableFilterComposer get saleId {
    final $$SalesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.salesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableTableFilterComposer(
            $db: $db,
            $table: $db.salesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableTableFilterComposer get productId {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> saleItemModifiersTableRefs(
    Expression<bool> Function($$SaleItemModifiersTableTableFilterComposer f) f,
  ) {
    final $$SaleItemModifiersTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.saleItemModifiersTable,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SaleItemModifiersTableTableFilterComposer(
                $db: $db,
                $table: $db.saleItemModifiersTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> refundItemsTableRefs(
    Expression<bool> Function($$RefundItemsTableTableFilterComposer f) f,
  ) {
    final $$RefundItemsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refundItemsTable,
      getReferencedColumn: (t) => t.saleItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundItemsTableTableFilterComposer(
            $db: $db,
            $table: $db.refundItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SaleItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleItemsTableTable> {
  $$SaleItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountBeneficiaryId => $composableBuilder(
    column: $table.discountBeneficiaryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountBeneficiaryName => $composableBuilder(
    column: $table.discountBeneficiaryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatExemptAmount => $composableBuilder(
    column: $table.vatExemptAmount,
    builder: (column) => ColumnOrderings(column),
  );

  $$SalesTableTableOrderingComposer get saleId {
    final $$SalesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.salesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableTableOrderingComposer(
            $db: $db,
            $table: $db.salesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableTableOrderingComposer get productId {
    final $$ProductsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableOrderingComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleItemsTableTable> {
  $$SaleItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountBeneficiaryId => $composableBuilder(
    column: $table.discountBeneficiaryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountBeneficiaryName => $composableBuilder(
    column: $table.discountBeneficiaryName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vatExemptAmount => $composableBuilder(
    column: $table.vatExemptAmount,
    builder: (column) => column,
  );

  $$SalesTableTableAnnotationComposer get saleId {
    final $$SalesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.salesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.salesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableTableAnnotationComposer get productId {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> saleItemModifiersTableRefs<T extends Object>(
    Expression<T> Function($$SaleItemModifiersTableTableAnnotationComposer a) f,
  ) {
    final $$SaleItemModifiersTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.saleItemModifiersTable,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SaleItemModifiersTableTableAnnotationComposer(
                $db: $db,
                $table: $db.saleItemModifiersTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> refundItemsTableRefs<T extends Object>(
    Expression<T> Function($$RefundItemsTableTableAnnotationComposer a) f,
  ) {
    final $$RefundItemsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refundItemsTable,
      getReferencedColumn: (t) => t.saleItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundItemsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.refundItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SaleItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleItemsTableTable,
          SaleItemsTableData,
          $$SaleItemsTableTableFilterComposer,
          $$SaleItemsTableTableOrderingComposer,
          $$SaleItemsTableTableAnnotationComposer,
          $$SaleItemsTableTableCreateCompanionBuilder,
          $$SaleItemsTableTableUpdateCompanionBuilder,
          (SaleItemsTableData, $$SaleItemsTableTableReferences),
          SaleItemsTableData,
          PrefetchHooks Function({
            bool saleId,
            bool productId,
            bool saleItemModifiersTableRefs,
            bool refundItemsTableRefs,
          })
        > {
  $$SaleItemsTableTableTableManager(
    _$AppDatabase db,
    $SaleItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SaleItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$SaleItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SaleItemsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> saleId = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String> variantName = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<String?> discountType = const Value.absent(),
                Value<String?> discountBeneficiaryId = const Value.absent(),
                Value<String?> discountBeneficiaryName = const Value.absent(),
                Value<double?> discountAmount = const Value.absent(),
                Value<double?> vatExemptAmount = const Value.absent(),
              }) => SaleItemsTableCompanion(
                id: id,
                saleId: saleId,
                productId: productId,
                variantName: variantName,
                qty: qty,
                unitPrice: unitPrice,
                discountType: discountType,
                discountBeneficiaryId: discountBeneficiaryId,
                discountBeneficiaryName: discountBeneficiaryName,
                discountAmount: discountAmount,
                vatExemptAmount: vatExemptAmount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int saleId,
                required int productId,
                required String variantName,
                required int qty,
                required double unitPrice,
                Value<String?> discountType = const Value.absent(),
                Value<String?> discountBeneficiaryId = const Value.absent(),
                Value<String?> discountBeneficiaryName = const Value.absent(),
                Value<double?> discountAmount = const Value.absent(),
                Value<double?> vatExemptAmount = const Value.absent(),
              }) => SaleItemsTableCompanion.insert(
                id: id,
                saleId: saleId,
                productId: productId,
                variantName: variantName,
                qty: qty,
                unitPrice: unitPrice,
                discountType: discountType,
                discountBeneficiaryId: discountBeneficiaryId,
                discountBeneficiaryName: discountBeneficiaryName,
                discountAmount: discountAmount,
                vatExemptAmount: vatExemptAmount,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$SaleItemsTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            saleId = false,
            productId = false,
            saleItemModifiersTableRefs = false,
            refundItemsTableRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (saleItemModifiersTableRefs) db.saleItemModifiersTable,
                if (refundItemsTableRefs) db.refundItemsTable,
              ],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (saleId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.saleId,
                            referencedTable: $$SaleItemsTableTableReferences
                                ._saleIdTable(db),
                            referencedColumn:
                                $$SaleItemsTableTableReferences
                                    ._saleIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (productId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.productId,
                            referencedTable: $$SaleItemsTableTableReferences
                                ._productIdTable(db),
                            referencedColumn:
                                $$SaleItemsTableTableReferences
                                    ._productIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (saleItemModifiersTableRefs)
                    await $_getPrefetchedData<
                      SaleItemsTableData,
                      $SaleItemsTableTable,
                      SaleItemModifiersTableData
                    >(
                      currentTable: table,
                      referencedTable: $$SaleItemsTableTableReferences
                          ._saleItemModifiersTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$SaleItemsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).saleItemModifiersTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.itemId == item.id),
                      typedResults: items,
                    ),
                  if (refundItemsTableRefs)
                    await $_getPrefetchedData<
                      SaleItemsTableData,
                      $SaleItemsTableTable,
                      RefundItemsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$SaleItemsTableTableReferences
                          ._refundItemsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$SaleItemsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).refundItemsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.saleItemId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SaleItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleItemsTableTable,
      SaleItemsTableData,
      $$SaleItemsTableTableFilterComposer,
      $$SaleItemsTableTableOrderingComposer,
      $$SaleItemsTableTableAnnotationComposer,
      $$SaleItemsTableTableCreateCompanionBuilder,
      $$SaleItemsTableTableUpdateCompanionBuilder,
      (SaleItemsTableData, $$SaleItemsTableTableReferences),
      SaleItemsTableData,
      PrefetchHooks Function({
        bool saleId,
        bool productId,
        bool saleItemModifiersTableRefs,
        bool refundItemsTableRefs,
      })
    >;
typedef $$SaleItemModifiersTableTableCreateCompanionBuilder =
    SaleItemModifiersTableCompanion Function({
      Value<int> id,
      required int itemId,
      required String modifierName,
      Value<double> additionalPrice,
    });
typedef $$SaleItemModifiersTableTableUpdateCompanionBuilder =
    SaleItemModifiersTableCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<String> modifierName,
      Value<double> additionalPrice,
    });

final class $$SaleItemModifiersTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SaleItemModifiersTableTable,
          SaleItemModifiersTableData
        > {
  $$SaleItemModifiersTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SaleItemsTableTable _itemIdTable(_$AppDatabase db) =>
      db.saleItemsTable.createAlias(
        $_aliasNameGenerator(
          db.saleItemModifiersTable.itemId,
          db.saleItemsTable.id,
        ),
      );

  $$SaleItemsTableTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$SaleItemsTableTableTableManager(
      $_db,
      $_db.saleItemsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SaleItemModifiersTableTableFilterComposer
    extends Composer<_$AppDatabase, $SaleItemModifiersTableTable> {
  $$SaleItemModifiersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifierName => $composableBuilder(
    column: $table.modifierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get additionalPrice => $composableBuilder(
    column: $table.additionalPrice,
    builder: (column) => ColumnFilters(column),
  );

  $$SaleItemsTableTableFilterComposer get itemId {
    final $$SaleItemsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.saleItemsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableTableFilterComposer(
            $db: $db,
            $table: $db.saleItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemModifiersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleItemModifiersTableTable> {
  $$SaleItemModifiersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifierName => $composableBuilder(
    column: $table.modifierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get additionalPrice => $composableBuilder(
    column: $table.additionalPrice,
    builder: (column) => ColumnOrderings(column),
  );

  $$SaleItemsTableTableOrderingComposer get itemId {
    final $$SaleItemsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.saleItemsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableTableOrderingComposer(
            $db: $db,
            $table: $db.saleItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemModifiersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleItemModifiersTableTable> {
  $$SaleItemModifiersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get modifierName => $composableBuilder(
    column: $table.modifierName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get additionalPrice => $composableBuilder(
    column: $table.additionalPrice,
    builder: (column) => column,
  );

  $$SaleItemsTableTableAnnotationComposer get itemId {
    final $$SaleItemsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.saleItemsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.saleItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemModifiersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleItemModifiersTableTable,
          SaleItemModifiersTableData,
          $$SaleItemModifiersTableTableFilterComposer,
          $$SaleItemModifiersTableTableOrderingComposer,
          $$SaleItemModifiersTableTableAnnotationComposer,
          $$SaleItemModifiersTableTableCreateCompanionBuilder,
          $$SaleItemModifiersTableTableUpdateCompanionBuilder,
          (SaleItemModifiersTableData, $$SaleItemModifiersTableTableReferences),
          SaleItemModifiersTableData,
          PrefetchHooks Function({bool itemId})
        > {
  $$SaleItemModifiersTableTableTableManager(
    _$AppDatabase db,
    $SaleItemModifiersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SaleItemModifiersTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$SaleItemModifiersTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$SaleItemModifiersTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> modifierName = const Value.absent(),
                Value<double> additionalPrice = const Value.absent(),
              }) => SaleItemModifiersTableCompanion(
                id: id,
                itemId: itemId,
                modifierName: modifierName,
                additionalPrice: additionalPrice,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required String modifierName,
                Value<double> additionalPrice = const Value.absent(),
              }) => SaleItemModifiersTableCompanion.insert(
                id: id,
                itemId: itemId,
                modifierName: modifierName,
                additionalPrice: additionalPrice,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$SaleItemModifiersTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (itemId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.itemId,
                            referencedTable:
                                $$SaleItemModifiersTableTableReferences
                                    ._itemIdTable(db),
                            referencedColumn:
                                $$SaleItemModifiersTableTableReferences
                                    ._itemIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SaleItemModifiersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleItemModifiersTableTable,
      SaleItemModifiersTableData,
      $$SaleItemModifiersTableTableFilterComposer,
      $$SaleItemModifiersTableTableOrderingComposer,
      $$SaleItemModifiersTableTableAnnotationComposer,
      $$SaleItemModifiersTableTableCreateCompanionBuilder,
      $$SaleItemModifiersTableTableUpdateCompanionBuilder,
      (SaleItemModifiersTableData, $$SaleItemModifiersTableTableReferences),
      SaleItemModifiersTableData,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$PaymentsTableTableCreateCompanionBuilder =
    PaymentsTableCompanion Function({
      Value<int> id,
      required int saleId,
      required String method,
      required double amount,
      Value<double?> cashReceived,
      Value<String?> reference,
      required DateTime createdAt,
    });
typedef $$PaymentsTableTableUpdateCompanionBuilder =
    PaymentsTableCompanion Function({
      Value<int> id,
      Value<int> saleId,
      Value<String> method,
      Value<double> amount,
      Value<double?> cashReceived,
      Value<String?> reference,
      Value<DateTime> createdAt,
    });

final class $$PaymentsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $PaymentsTableTable, PaymentsTableData> {
  $$PaymentsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SalesTableTable _saleIdTable(_$AppDatabase db) =>
      db.salesTable.createAlias(
        $_aliasNameGenerator(db.paymentsTable.saleId, db.salesTable.id),
      );

  $$SalesTableTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<int>('sale_id')!;

    final manager = $$SalesTableTableTableManager(
      $_db,
      $_db.salesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PaymentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTableTable> {
  $$PaymentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashReceived => $composableBuilder(
    column: $table.cashReceived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SalesTableTableFilterComposer get saleId {
    final $$SalesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.salesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableTableFilterComposer(
            $db: $db,
            $table: $db.salesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTableTable> {
  $$PaymentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashReceived => $composableBuilder(
    column: $table.cashReceived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SalesTableTableOrderingComposer get saleId {
    final $$SalesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.salesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableTableOrderingComposer(
            $db: $db,
            $table: $db.salesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTableTable> {
  $$PaymentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get cashReceived => $composableBuilder(
    column: $table.cashReceived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SalesTableTableAnnotationComposer get saleId {
    final $$SalesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.salesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.salesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTableTable,
          PaymentsTableData,
          $$PaymentsTableTableFilterComposer,
          $$PaymentsTableTableOrderingComposer,
          $$PaymentsTableTableAnnotationComposer,
          $$PaymentsTableTableCreateCompanionBuilder,
          $$PaymentsTableTableUpdateCompanionBuilder,
          (PaymentsTableData, $$PaymentsTableTableReferences),
          PaymentsTableData,
          PrefetchHooks Function({bool saleId})
        > {
  $$PaymentsTableTableTableManager(_$AppDatabase db, $PaymentsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PaymentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$PaymentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$PaymentsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> saleId = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double?> cashReceived = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PaymentsTableCompanion(
                id: id,
                saleId: saleId,
                method: method,
                amount: amount,
                cashReceived: cashReceived,
                reference: reference,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int saleId,
                required String method,
                required double amount,
                Value<double?> cashReceived = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                required DateTime createdAt,
              }) => PaymentsTableCompanion.insert(
                id: id,
                saleId: saleId,
                method: method,
                amount: amount,
                cashReceived: cashReceived,
                reference: reference,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$PaymentsTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({saleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (saleId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.saleId,
                            referencedTable: $$PaymentsTableTableReferences
                                ._saleIdTable(db),
                            referencedColumn:
                                $$PaymentsTableTableReferences
                                    ._saleIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PaymentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTableTable,
      PaymentsTableData,
      $$PaymentsTableTableFilterComposer,
      $$PaymentsTableTableOrderingComposer,
      $$PaymentsTableTableAnnotationComposer,
      $$PaymentsTableTableCreateCompanionBuilder,
      $$PaymentsTableTableUpdateCompanionBuilder,
      (PaymentsTableData, $$PaymentsTableTableReferences),
      PaymentsTableData,
      PrefetchHooks Function({bool saleId})
    >;
typedef $$RefundsTableTableCreateCompanionBuilder =
    RefundsTableCompanion Function({
      Value<int> id,
      required int saleId,
      required String reason,
      required double total,
      required DateTime createdAt,
      Value<String?> refundNumber,
      Value<String> method,
    });
typedef $$RefundsTableTableUpdateCompanionBuilder =
    RefundsTableCompanion Function({
      Value<int> id,
      Value<int> saleId,
      Value<String> reason,
      Value<double> total,
      Value<DateTime> createdAt,
      Value<String?> refundNumber,
      Value<String> method,
    });

final class $$RefundsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $RefundsTableTable, RefundsTableData> {
  $$RefundsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SalesTableTable _saleIdTable(_$AppDatabase db) =>
      db.salesTable.createAlias(
        $_aliasNameGenerator(db.refundsTable.saleId, db.salesTable.id),
      );

  $$SalesTableTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<int>('sale_id')!;

    final manager = $$SalesTableTableTableManager(
      $_db,
      $_db.salesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RefundItemsTableTable, List<RefundItemsTableData>>
  _refundItemsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.refundItemsTable,
    aliasName: $_aliasNameGenerator(
      db.refundsTable.id,
      db.refundItemsTable.refundId,
    ),
  );

  $$RefundItemsTableTableProcessedTableManager get refundItemsTableRefs {
    final manager = $$RefundItemsTableTableTableManager(
      $_db,
      $_db.refundItemsTable,
    ).filter((f) => f.refundId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _refundItemsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RefundsTableTableFilterComposer
    extends Composer<_$AppDatabase, $RefundsTableTable> {
  $$RefundsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refundNumber => $composableBuilder(
    column: $table.refundNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  $$SalesTableTableFilterComposer get saleId {
    final $$SalesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.salesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableTableFilterComposer(
            $db: $db,
            $table: $db.salesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> refundItemsTableRefs(
    Expression<bool> Function($$RefundItemsTableTableFilterComposer f) f,
  ) {
    final $$RefundItemsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refundItemsTable,
      getReferencedColumn: (t) => t.refundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundItemsTableTableFilterComposer(
            $db: $db,
            $table: $db.refundItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RefundsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RefundsTableTable> {
  $$RefundsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refundNumber => $composableBuilder(
    column: $table.refundNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  $$SalesTableTableOrderingComposer get saleId {
    final $$SalesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.salesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableTableOrderingComposer(
            $db: $db,
            $table: $db.salesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefundsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefundsTableTable> {
  $$RefundsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get refundNumber => $composableBuilder(
    column: $table.refundNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  $$SalesTableTableAnnotationComposer get saleId {
    final $$SalesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.salesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.salesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> refundItemsTableRefs<T extends Object>(
    Expression<T> Function($$RefundItemsTableTableAnnotationComposer a) f,
  ) {
    final $$RefundItemsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refundItemsTable,
      getReferencedColumn: (t) => t.refundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundItemsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.refundItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RefundsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RefundsTableTable,
          RefundsTableData,
          $$RefundsTableTableFilterComposer,
          $$RefundsTableTableOrderingComposer,
          $$RefundsTableTableAnnotationComposer,
          $$RefundsTableTableCreateCompanionBuilder,
          $$RefundsTableTableUpdateCompanionBuilder,
          (RefundsTableData, $$RefundsTableTableReferences),
          RefundsTableData,
          PrefetchHooks Function({bool saleId, bool refundItemsTableRefs})
        > {
  $$RefundsTableTableTableManager(_$AppDatabase db, $RefundsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RefundsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$RefundsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$RefundsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> saleId = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<double> total = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> refundNumber = const Value.absent(),
                Value<String> method = const Value.absent(),
              }) => RefundsTableCompanion(
                id: id,
                saleId: saleId,
                reason: reason,
                total: total,
                createdAt: createdAt,
                refundNumber: refundNumber,
                method: method,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int saleId,
                required String reason,
                required double total,
                required DateTime createdAt,
                Value<String?> refundNumber = const Value.absent(),
                Value<String> method = const Value.absent(),
              }) => RefundsTableCompanion.insert(
                id: id,
                saleId: saleId,
                reason: reason,
                total: total,
                createdAt: createdAt,
                refundNumber: refundNumber,
                method: method,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$RefundsTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            saleId = false,
            refundItemsTableRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (refundItemsTableRefs) db.refundItemsTable,
              ],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (saleId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.saleId,
                            referencedTable: $$RefundsTableTableReferences
                                ._saleIdTable(db),
                            referencedColumn:
                                $$RefundsTableTableReferences
                                    ._saleIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (refundItemsTableRefs)
                    await $_getPrefetchedData<
                      RefundsTableData,
                      $RefundsTableTable,
                      RefundItemsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$RefundsTableTableReferences
                          ._refundItemsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$RefundsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).refundItemsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.refundId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RefundsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RefundsTableTable,
      RefundsTableData,
      $$RefundsTableTableFilterComposer,
      $$RefundsTableTableOrderingComposer,
      $$RefundsTableTableAnnotationComposer,
      $$RefundsTableTableCreateCompanionBuilder,
      $$RefundsTableTableUpdateCompanionBuilder,
      (RefundsTableData, $$RefundsTableTableReferences),
      RefundsTableData,
      PrefetchHooks Function({bool saleId, bool refundItemsTableRefs})
    >;
typedef $$RefundItemsTableTableCreateCompanionBuilder =
    RefundItemsTableCompanion Function({
      Value<int> id,
      required int refundId,
      required int saleItemId,
      required int qty,
      required double amount,
    });
typedef $$RefundItemsTableTableUpdateCompanionBuilder =
    RefundItemsTableCompanion Function({
      Value<int> id,
      Value<int> refundId,
      Value<int> saleItemId,
      Value<int> qty,
      Value<double> amount,
    });

final class $$RefundItemsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RefundItemsTableTable,
          RefundItemsTableData
        > {
  $$RefundItemsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RefundsTableTable _refundIdTable(_$AppDatabase db) =>
      db.refundsTable.createAlias(
        $_aliasNameGenerator(db.refundItemsTable.refundId, db.refundsTable.id),
      );

  $$RefundsTableTableProcessedTableManager get refundId {
    final $_column = $_itemColumn<int>('refund_id')!;

    final manager = $$RefundsTableTableTableManager(
      $_db,
      $_db.refundsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_refundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SaleItemsTableTable _saleItemIdTable(_$AppDatabase db) =>
      db.saleItemsTable.createAlias(
        $_aliasNameGenerator(
          db.refundItemsTable.saleItemId,
          db.saleItemsTable.id,
        ),
      );

  $$SaleItemsTableTableProcessedTableManager get saleItemId {
    final $_column = $_itemColumn<int>('sale_item_id')!;

    final manager = $$SaleItemsTableTableTableManager(
      $_db,
      $_db.saleItemsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RefundItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $RefundItemsTableTable> {
  $$RefundItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  $$RefundsTableTableFilterComposer get refundId {
    final $$RefundsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundId,
      referencedTable: $db.refundsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundsTableTableFilterComposer(
            $db: $db,
            $table: $db.refundsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SaleItemsTableTableFilterComposer get saleItemId {
    final $$SaleItemsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleItemId,
      referencedTable: $db.saleItemsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableTableFilterComposer(
            $db: $db,
            $table: $db.saleItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefundItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RefundItemsTableTable> {
  $$RefundItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  $$RefundsTableTableOrderingComposer get refundId {
    final $$RefundsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundId,
      referencedTable: $db.refundsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundsTableTableOrderingComposer(
            $db: $db,
            $table: $db.refundsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SaleItemsTableTableOrderingComposer get saleItemId {
    final $$SaleItemsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleItemId,
      referencedTable: $db.saleItemsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableTableOrderingComposer(
            $db: $db,
            $table: $db.saleItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefundItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefundItemsTableTable> {
  $$RefundItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  $$RefundsTableTableAnnotationComposer get refundId {
    final $$RefundsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundId,
      referencedTable: $db.refundsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefundsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.refundsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SaleItemsTableTableAnnotationComposer get saleItemId {
    final $$SaleItemsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleItemId,
      referencedTable: $db.saleItemsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.saleItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefundItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RefundItemsTableTable,
          RefundItemsTableData,
          $$RefundItemsTableTableFilterComposer,
          $$RefundItemsTableTableOrderingComposer,
          $$RefundItemsTableTableAnnotationComposer,
          $$RefundItemsTableTableCreateCompanionBuilder,
          $$RefundItemsTableTableUpdateCompanionBuilder,
          (RefundItemsTableData, $$RefundItemsTableTableReferences),
          RefundItemsTableData,
          PrefetchHooks Function({bool refundId, bool saleItemId})
        > {
  $$RefundItemsTableTableTableManager(
    _$AppDatabase db,
    $RefundItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$RefundItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$RefundItemsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$RefundItemsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> refundId = const Value.absent(),
                Value<int> saleItemId = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<double> amount = const Value.absent(),
              }) => RefundItemsTableCompanion(
                id: id,
                refundId: refundId,
                saleItemId: saleItemId,
                qty: qty,
                amount: amount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int refundId,
                required int saleItemId,
                required int qty,
                required double amount,
              }) => RefundItemsTableCompanion.insert(
                id: id,
                refundId: refundId,
                saleItemId: saleItemId,
                qty: qty,
                amount: amount,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$RefundItemsTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({refundId = false, saleItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (refundId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.refundId,
                            referencedTable: $$RefundItemsTableTableReferences
                                ._refundIdTable(db),
                            referencedColumn:
                                $$RefundItemsTableTableReferences
                                    ._refundIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (saleItemId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.saleItemId,
                            referencedTable: $$RefundItemsTableTableReferences
                                ._saleItemIdTable(db),
                            referencedColumn:
                                $$RefundItemsTableTableReferences
                                    ._saleItemIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RefundItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RefundItemsTableTable,
      RefundItemsTableData,
      $$RefundItemsTableTableFilterComposer,
      $$RefundItemsTableTableOrderingComposer,
      $$RefundItemsTableTableAnnotationComposer,
      $$RefundItemsTableTableCreateCompanionBuilder,
      $$RefundItemsTableTableUpdateCompanionBuilder,
      (RefundItemsTableData, $$RefundItemsTableTableReferences),
      RefundItemsTableData,
      PrefetchHooks Function({bool refundId, bool saleItemId})
    >;
typedef $$StoreInfoTableTableCreateCompanionBuilder =
    StoreInfoTableCompanion Function({
      Value<int> id,
      Value<String> storeId,
      Value<String> storeName,
      Value<String> address,
      Value<double> taxRate,
      Value<String> currency,
      Value<String> receiptFooter,
      Value<String> tin,
      Value<String> terminalName,
    });
typedef $$StoreInfoTableTableUpdateCompanionBuilder =
    StoreInfoTableCompanion Function({
      Value<int> id,
      Value<String> storeId,
      Value<String> storeName,
      Value<String> address,
      Value<double> taxRate,
      Value<String> currency,
      Value<String> receiptFooter,
      Value<String> tin,
      Value<String> terminalName,
    });

class $$StoreInfoTableTableFilterComposer
    extends Composer<_$AppDatabase, $StoreInfoTableTable> {
  $$StoreInfoTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tin => $composableBuilder(
    column: $table.tin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get terminalName => $composableBuilder(
    column: $table.terminalName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoreInfoTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StoreInfoTableTable> {
  $$StoreInfoTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tin => $composableBuilder(
    column: $table.tin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get terminalName => $composableBuilder(
    column: $table.terminalName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoreInfoTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoreInfoTableTable> {
  $$StoreInfoTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tin =>
      $composableBuilder(column: $table.tin, builder: (column) => column);

  GeneratedColumn<String> get terminalName => $composableBuilder(
    column: $table.terminalName,
    builder: (column) => column,
  );
}

class $$StoreInfoTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoreInfoTableTable,
          StoreInfoTableData,
          $$StoreInfoTableTableFilterComposer,
          $$StoreInfoTableTableOrderingComposer,
          $$StoreInfoTableTableAnnotationComposer,
          $$StoreInfoTableTableCreateCompanionBuilder,
          $$StoreInfoTableTableUpdateCompanionBuilder,
          (
            StoreInfoTableData,
            BaseReferences<
              _$AppDatabase,
              $StoreInfoTableTable,
              StoreInfoTableData
            >,
          ),
          StoreInfoTableData,
          PrefetchHooks Function()
        > {
  $$StoreInfoTableTableTableManager(
    _$AppDatabase db,
    $StoreInfoTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$StoreInfoTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$StoreInfoTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$StoreInfoTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> storeName = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<double> taxRate = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> receiptFooter = const Value.absent(),
                Value<String> tin = const Value.absent(),
                Value<String> terminalName = const Value.absent(),
              }) => StoreInfoTableCompanion(
                id: id,
                storeId: storeId,
                storeName: storeName,
                address: address,
                taxRate: taxRate,
                currency: currency,
                receiptFooter: receiptFooter,
                tin: tin,
                terminalName: terminalName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> storeName = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<double> taxRate = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> receiptFooter = const Value.absent(),
                Value<String> tin = const Value.absent(),
                Value<String> terminalName = const Value.absent(),
              }) => StoreInfoTableCompanion.insert(
                id: id,
                storeId: storeId,
                storeName: storeName,
                address: address,
                taxRate: taxRate,
                currency: currency,
                receiptFooter: receiptFooter,
                tin: tin,
                terminalName: terminalName,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoreInfoTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoreInfoTableTable,
      StoreInfoTableData,
      $$StoreInfoTableTableFilterComposer,
      $$StoreInfoTableTableOrderingComposer,
      $$StoreInfoTableTableAnnotationComposer,
      $$StoreInfoTableTableCreateCompanionBuilder,
      $$StoreInfoTableTableUpdateCompanionBuilder,
      (
        StoreInfoTableData,
        BaseReferences<_$AppDatabase, $StoreInfoTableTable, StoreInfoTableData>,
      ),
      StoreInfoTableData,
      PrefetchHooks Function()
    >;
typedef $$XReadingsTableTableCreateCompanionBuilder =
    XReadingsTableCompanion Function({
      Value<int> id,
      required int cashierId,
      required String cashierName,
      required DateTime periodStart,
      required DateTime periodEnd,
      required DateTime generatedAt,
      required double totalSales,
      required int transactionCount,
      required int voidedCount,
      required int refundedCount,
      required String paymentBreakdownJson,
      required String topProductsJson,
      Value<String> discountsJson,
      Value<double> totalDiscounts,
      Value<double> vatableSales,
      Value<double> vatAmount,
      Value<double> vatExemptSales,
      Value<double> averageSale,
      Value<double> highestSale,
      Value<double> lowestSale,
      Value<double> cashCollected,
      Value<String> paymentLedgersJson,
    });
typedef $$XReadingsTableTableUpdateCompanionBuilder =
    XReadingsTableCompanion Function({
      Value<int> id,
      Value<int> cashierId,
      Value<String> cashierName,
      Value<DateTime> periodStart,
      Value<DateTime> periodEnd,
      Value<DateTime> generatedAt,
      Value<double> totalSales,
      Value<int> transactionCount,
      Value<int> voidedCount,
      Value<int> refundedCount,
      Value<String> paymentBreakdownJson,
      Value<String> topProductsJson,
      Value<String> discountsJson,
      Value<double> totalDiscounts,
      Value<double> vatableSales,
      Value<double> vatAmount,
      Value<double> vatExemptSales,
      Value<double> averageSale,
      Value<double> highestSale,
      Value<double> lowestSale,
      Value<double> cashCollected,
      Value<String> paymentLedgersJson,
    });

class $$XReadingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $XReadingsTableTable> {
  $$XReadingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get voidedCount => $composableBuilder(
    column: $table.voidedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get refundedCount => $composableBuilder(
    column: $table.refundedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentBreakdownJson => $composableBuilder(
    column: $table.paymentBreakdownJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topProductsJson => $composableBuilder(
    column: $table.topProductsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountsJson => $composableBuilder(
    column: $table.discountsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDiscounts => $composableBuilder(
    column: $table.totalDiscounts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatableSales => $composableBuilder(
    column: $table.vatableSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatAmount => $composableBuilder(
    column: $table.vatAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatExemptSales => $composableBuilder(
    column: $table.vatExemptSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageSale => $composableBuilder(
    column: $table.averageSale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get highestSale => $composableBuilder(
    column: $table.highestSale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lowestSale => $composableBuilder(
    column: $table.lowestSale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashCollected => $composableBuilder(
    column: $table.cashCollected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentLedgersJson => $composableBuilder(
    column: $table.paymentLedgersJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$XReadingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $XReadingsTableTable> {
  $$XReadingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get voidedCount => $composableBuilder(
    column: $table.voidedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refundedCount => $composableBuilder(
    column: $table.refundedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentBreakdownJson => $composableBuilder(
    column: $table.paymentBreakdownJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topProductsJson => $composableBuilder(
    column: $table.topProductsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountsJson => $composableBuilder(
    column: $table.discountsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDiscounts => $composableBuilder(
    column: $table.totalDiscounts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatableSales => $composableBuilder(
    column: $table.vatableSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatAmount => $composableBuilder(
    column: $table.vatAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatExemptSales => $composableBuilder(
    column: $table.vatExemptSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageSale => $composableBuilder(
    column: $table.averageSale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get highestSale => $composableBuilder(
    column: $table.highestSale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lowestSale => $composableBuilder(
    column: $table.lowestSale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashCollected => $composableBuilder(
    column: $table.cashCollected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentLedgersJson => $composableBuilder(
    column: $table.paymentLedgersJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$XReadingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $XReadingsTableTable> {
  $$XReadingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get voidedCount => $composableBuilder(
    column: $table.voidedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get refundedCount => $composableBuilder(
    column: $table.refundedCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentBreakdownJson => $composableBuilder(
    column: $table.paymentBreakdownJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get topProductsJson => $composableBuilder(
    column: $table.topProductsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountsJson => $composableBuilder(
    column: $table.discountsJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalDiscounts => $composableBuilder(
    column: $table.totalDiscounts,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vatableSales => $composableBuilder(
    column: $table.vatableSales,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vatAmount =>
      $composableBuilder(column: $table.vatAmount, builder: (column) => column);

  GeneratedColumn<double> get vatExemptSales => $composableBuilder(
    column: $table.vatExemptSales,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageSale => $composableBuilder(
    column: $table.averageSale,
    builder: (column) => column,
  );

  GeneratedColumn<double> get highestSale => $composableBuilder(
    column: $table.highestSale,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lowestSale => $composableBuilder(
    column: $table.lowestSale,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashCollected => $composableBuilder(
    column: $table.cashCollected,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentLedgersJson => $composableBuilder(
    column: $table.paymentLedgersJson,
    builder: (column) => column,
  );
}

class $$XReadingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $XReadingsTableTable,
          XReadingsTableData,
          $$XReadingsTableTableFilterComposer,
          $$XReadingsTableTableOrderingComposer,
          $$XReadingsTableTableAnnotationComposer,
          $$XReadingsTableTableCreateCompanionBuilder,
          $$XReadingsTableTableUpdateCompanionBuilder,
          (
            XReadingsTableData,
            BaseReferences<
              _$AppDatabase,
              $XReadingsTableTable,
              XReadingsTableData
            >,
          ),
          XReadingsTableData,
          PrefetchHooks Function()
        > {
  $$XReadingsTableTableTableManager(
    _$AppDatabase db,
    $XReadingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$XReadingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$XReadingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$XReadingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cashierId = const Value.absent(),
                Value<String> cashierName = const Value.absent(),
                Value<DateTime> periodStart = const Value.absent(),
                Value<DateTime> periodEnd = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<double> totalSales = const Value.absent(),
                Value<int> transactionCount = const Value.absent(),
                Value<int> voidedCount = const Value.absent(),
                Value<int> refundedCount = const Value.absent(),
                Value<String> paymentBreakdownJson = const Value.absent(),
                Value<String> topProductsJson = const Value.absent(),
                Value<String> discountsJson = const Value.absent(),
                Value<double> totalDiscounts = const Value.absent(),
                Value<double> vatableSales = const Value.absent(),
                Value<double> vatAmount = const Value.absent(),
                Value<double> vatExemptSales = const Value.absent(),
                Value<double> averageSale = const Value.absent(),
                Value<double> highestSale = const Value.absent(),
                Value<double> lowestSale = const Value.absent(),
                Value<double> cashCollected = const Value.absent(),
                Value<String> paymentLedgersJson = const Value.absent(),
              }) => XReadingsTableCompanion(
                id: id,
                cashierId: cashierId,
                cashierName: cashierName,
                periodStart: periodStart,
                periodEnd: periodEnd,
                generatedAt: generatedAt,
                totalSales: totalSales,
                transactionCount: transactionCount,
                voidedCount: voidedCount,
                refundedCount: refundedCount,
                paymentBreakdownJson: paymentBreakdownJson,
                topProductsJson: topProductsJson,
                discountsJson: discountsJson,
                totalDiscounts: totalDiscounts,
                vatableSales: vatableSales,
                vatAmount: vatAmount,
                vatExemptSales: vatExemptSales,
                averageSale: averageSale,
                highestSale: highestSale,
                lowestSale: lowestSale,
                cashCollected: cashCollected,
                paymentLedgersJson: paymentLedgersJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cashierId,
                required String cashierName,
                required DateTime periodStart,
                required DateTime periodEnd,
                required DateTime generatedAt,
                required double totalSales,
                required int transactionCount,
                required int voidedCount,
                required int refundedCount,
                required String paymentBreakdownJson,
                required String topProductsJson,
                Value<String> discountsJson = const Value.absent(),
                Value<double> totalDiscounts = const Value.absent(),
                Value<double> vatableSales = const Value.absent(),
                Value<double> vatAmount = const Value.absent(),
                Value<double> vatExemptSales = const Value.absent(),
                Value<double> averageSale = const Value.absent(),
                Value<double> highestSale = const Value.absent(),
                Value<double> lowestSale = const Value.absent(),
                Value<double> cashCollected = const Value.absent(),
                Value<String> paymentLedgersJson = const Value.absent(),
              }) => XReadingsTableCompanion.insert(
                id: id,
                cashierId: cashierId,
                cashierName: cashierName,
                periodStart: periodStart,
                periodEnd: periodEnd,
                generatedAt: generatedAt,
                totalSales: totalSales,
                transactionCount: transactionCount,
                voidedCount: voidedCount,
                refundedCount: refundedCount,
                paymentBreakdownJson: paymentBreakdownJson,
                topProductsJson: topProductsJson,
                discountsJson: discountsJson,
                totalDiscounts: totalDiscounts,
                vatableSales: vatableSales,
                vatAmount: vatAmount,
                vatExemptSales: vatExemptSales,
                averageSale: averageSale,
                highestSale: highestSale,
                lowestSale: lowestSale,
                cashCollected: cashCollected,
                paymentLedgersJson: paymentLedgersJson,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$XReadingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $XReadingsTableTable,
      XReadingsTableData,
      $$XReadingsTableTableFilterComposer,
      $$XReadingsTableTableOrderingComposer,
      $$XReadingsTableTableAnnotationComposer,
      $$XReadingsTableTableCreateCompanionBuilder,
      $$XReadingsTableTableUpdateCompanionBuilder,
      (
        XReadingsTableData,
        BaseReferences<_$AppDatabase, $XReadingsTableTable, XReadingsTableData>,
      ),
      XReadingsTableData,
      PrefetchHooks Function()
    >;
typedef $$DailyReportsTableTableCreateCompanionBuilder =
    DailyReportsTableCompanion Function({
      Value<int> id,
      required int cashierId,
      required String cashierName,
      required DateTime periodStart,
      required DateTime periodEnd,
      required DateTime generatedAt,
      required double grossSales,
      required double vatableSales,
      required double vatAmount,
      required double vatExemptSales,
      required double netOfTax,
      required int transactionCount,
      required int totalQtySold,
      required double cashSalesTotal,
      required int cashSalesCount,
      required String salesByProductJson,
      required String cashLedgerJson,
    });
typedef $$DailyReportsTableTableUpdateCompanionBuilder =
    DailyReportsTableCompanion Function({
      Value<int> id,
      Value<int> cashierId,
      Value<String> cashierName,
      Value<DateTime> periodStart,
      Value<DateTime> periodEnd,
      Value<DateTime> generatedAt,
      Value<double> grossSales,
      Value<double> vatableSales,
      Value<double> vatAmount,
      Value<double> vatExemptSales,
      Value<double> netOfTax,
      Value<int> transactionCount,
      Value<int> totalQtySold,
      Value<double> cashSalesTotal,
      Value<int> cashSalesCount,
      Value<String> salesByProductJson,
      Value<String> cashLedgerJson,
    });

class $$DailyReportsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DailyReportsTableTable> {
  $$DailyReportsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grossSales => $composableBuilder(
    column: $table.grossSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatableSales => $composableBuilder(
    column: $table.vatableSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatAmount => $composableBuilder(
    column: $table.vatAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatExemptSales => $composableBuilder(
    column: $table.vatExemptSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get netOfTax => $composableBuilder(
    column: $table.netOfTax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQtySold => $composableBuilder(
    column: $table.totalQtySold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashSalesTotal => $composableBuilder(
    column: $table.cashSalesTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashSalesCount => $composableBuilder(
    column: $table.cashSalesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salesByProductJson => $composableBuilder(
    column: $table.salesByProductJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashLedgerJson => $composableBuilder(
    column: $table.cashLedgerJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyReportsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyReportsTableTable> {
  $$DailyReportsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grossSales => $composableBuilder(
    column: $table.grossSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatableSales => $composableBuilder(
    column: $table.vatableSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatAmount => $composableBuilder(
    column: $table.vatAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatExemptSales => $composableBuilder(
    column: $table.vatExemptSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get netOfTax => $composableBuilder(
    column: $table.netOfTax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQtySold => $composableBuilder(
    column: $table.totalQtySold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashSalesTotal => $composableBuilder(
    column: $table.cashSalesTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashSalesCount => $composableBuilder(
    column: $table.cashSalesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salesByProductJson => $composableBuilder(
    column: $table.salesByProductJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashLedgerJson => $composableBuilder(
    column: $table.cashLedgerJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyReportsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyReportsTableTable> {
  $$DailyReportsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grossSales => $composableBuilder(
    column: $table.grossSales,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vatableSales => $composableBuilder(
    column: $table.vatableSales,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vatAmount =>
      $composableBuilder(column: $table.vatAmount, builder: (column) => column);

  GeneratedColumn<double> get vatExemptSales => $composableBuilder(
    column: $table.vatExemptSales,
    builder: (column) => column,
  );

  GeneratedColumn<double> get netOfTax =>
      $composableBuilder(column: $table.netOfTax, builder: (column) => column);

  GeneratedColumn<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalQtySold => $composableBuilder(
    column: $table.totalQtySold,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashSalesTotal => $composableBuilder(
    column: $table.cashSalesTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashSalesCount => $composableBuilder(
    column: $table.cashSalesCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get salesByProductJson => $composableBuilder(
    column: $table.salesByProductJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashLedgerJson => $composableBuilder(
    column: $table.cashLedgerJson,
    builder: (column) => column,
  );
}

class $$DailyReportsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyReportsTableTable,
          DailyReportsTableData,
          $$DailyReportsTableTableFilterComposer,
          $$DailyReportsTableTableOrderingComposer,
          $$DailyReportsTableTableAnnotationComposer,
          $$DailyReportsTableTableCreateCompanionBuilder,
          $$DailyReportsTableTableUpdateCompanionBuilder,
          (
            DailyReportsTableData,
            BaseReferences<
              _$AppDatabase,
              $DailyReportsTableTable,
              DailyReportsTableData
            >,
          ),
          DailyReportsTableData,
          PrefetchHooks Function()
        > {
  $$DailyReportsTableTableTableManager(
    _$AppDatabase db,
    $DailyReportsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$DailyReportsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$DailyReportsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$DailyReportsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cashierId = const Value.absent(),
                Value<String> cashierName = const Value.absent(),
                Value<DateTime> periodStart = const Value.absent(),
                Value<DateTime> periodEnd = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<double> grossSales = const Value.absent(),
                Value<double> vatableSales = const Value.absent(),
                Value<double> vatAmount = const Value.absent(),
                Value<double> vatExemptSales = const Value.absent(),
                Value<double> netOfTax = const Value.absent(),
                Value<int> transactionCount = const Value.absent(),
                Value<int> totalQtySold = const Value.absent(),
                Value<double> cashSalesTotal = const Value.absent(),
                Value<int> cashSalesCount = const Value.absent(),
                Value<String> salesByProductJson = const Value.absent(),
                Value<String> cashLedgerJson = const Value.absent(),
              }) => DailyReportsTableCompanion(
                id: id,
                cashierId: cashierId,
                cashierName: cashierName,
                periodStart: periodStart,
                periodEnd: periodEnd,
                generatedAt: generatedAt,
                grossSales: grossSales,
                vatableSales: vatableSales,
                vatAmount: vatAmount,
                vatExemptSales: vatExemptSales,
                netOfTax: netOfTax,
                transactionCount: transactionCount,
                totalQtySold: totalQtySold,
                cashSalesTotal: cashSalesTotal,
                cashSalesCount: cashSalesCount,
                salesByProductJson: salesByProductJson,
                cashLedgerJson: cashLedgerJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cashierId,
                required String cashierName,
                required DateTime periodStart,
                required DateTime periodEnd,
                required DateTime generatedAt,
                required double grossSales,
                required double vatableSales,
                required double vatAmount,
                required double vatExemptSales,
                required double netOfTax,
                required int transactionCount,
                required int totalQtySold,
                required double cashSalesTotal,
                required int cashSalesCount,
                required String salesByProductJson,
                required String cashLedgerJson,
              }) => DailyReportsTableCompanion.insert(
                id: id,
                cashierId: cashierId,
                cashierName: cashierName,
                periodStart: periodStart,
                periodEnd: periodEnd,
                generatedAt: generatedAt,
                grossSales: grossSales,
                vatableSales: vatableSales,
                vatAmount: vatAmount,
                vatExemptSales: vatExemptSales,
                netOfTax: netOfTax,
                transactionCount: transactionCount,
                totalQtySold: totalQtySold,
                cashSalesTotal: cashSalesTotal,
                cashSalesCount: cashSalesCount,
                salesByProductJson: salesByProductJson,
                cashLedgerJson: cashLedgerJson,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyReportsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyReportsTableTable,
      DailyReportsTableData,
      $$DailyReportsTableTableFilterComposer,
      $$DailyReportsTableTableOrderingComposer,
      $$DailyReportsTableTableAnnotationComposer,
      $$DailyReportsTableTableCreateCompanionBuilder,
      $$DailyReportsTableTableUpdateCompanionBuilder,
      (
        DailyReportsTableData,
        BaseReferences<
          _$AppDatabase,
          $DailyReportsTableTable,
          DailyReportsTableData
        >,
      ),
      DailyReportsTableData,
      PrefetchHooks Function()
    >;
typedef $$ZReadingsTableTableCreateCompanionBuilder =
    ZReadingsTableCompanion Function({
      Value<int> id,
      required int zCounter,
      required DateTime periodStart,
      required DateTime periodEnd,
      required DateTime generatedAt,
      required int closedByUserId,
      required String closedByName,
      required int authorizedByUserId,
      required String authorizedByName,
      required double beginningBalance,
      required double endingBalance,
      required double totalSales,
      required double vatableSales,
      required double vatAmount,
      required double vatExemptSales,
      required int transactionCount,
      required int completedCount,
      required int voidedCount,
      required int refundedCount,
      required double discountTotal,
      required double cashCollected,
      required int totalQtySold,
      required String paymentBreakdownJson,
      required String salesByCashierJson,
      Value<String> discountsJson,
      Value<String> paymentLedgersJson,
    });
typedef $$ZReadingsTableTableUpdateCompanionBuilder =
    ZReadingsTableCompanion Function({
      Value<int> id,
      Value<int> zCounter,
      Value<DateTime> periodStart,
      Value<DateTime> periodEnd,
      Value<DateTime> generatedAt,
      Value<int> closedByUserId,
      Value<String> closedByName,
      Value<int> authorizedByUserId,
      Value<String> authorizedByName,
      Value<double> beginningBalance,
      Value<double> endingBalance,
      Value<double> totalSales,
      Value<double> vatableSales,
      Value<double> vatAmount,
      Value<double> vatExemptSales,
      Value<int> transactionCount,
      Value<int> completedCount,
      Value<int> voidedCount,
      Value<int> refundedCount,
      Value<double> discountTotal,
      Value<double> cashCollected,
      Value<int> totalQtySold,
      Value<String> paymentBreakdownJson,
      Value<String> salesByCashierJson,
      Value<String> discountsJson,
      Value<String> paymentLedgersJson,
    });

class $$ZReadingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ZReadingsTableTable> {
  $$ZReadingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zCounter => $composableBuilder(
    column: $table.zCounter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closedByUserId => $composableBuilder(
    column: $table.closedByUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closedByName => $composableBuilder(
    column: $table.closedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get authorizedByUserId => $composableBuilder(
    column: $table.authorizedByUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorizedByName => $composableBuilder(
    column: $table.authorizedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get beginningBalance => $composableBuilder(
    column: $table.beginningBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endingBalance => $composableBuilder(
    column: $table.endingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatableSales => $composableBuilder(
    column: $table.vatableSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatAmount => $composableBuilder(
    column: $table.vatAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatExemptSales => $composableBuilder(
    column: $table.vatExemptSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get voidedCount => $composableBuilder(
    column: $table.voidedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get refundedCount => $composableBuilder(
    column: $table.refundedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashCollected => $composableBuilder(
    column: $table.cashCollected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQtySold => $composableBuilder(
    column: $table.totalQtySold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentBreakdownJson => $composableBuilder(
    column: $table.paymentBreakdownJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salesByCashierJson => $composableBuilder(
    column: $table.salesByCashierJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountsJson => $composableBuilder(
    column: $table.discountsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentLedgersJson => $composableBuilder(
    column: $table.paymentLedgersJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ZReadingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ZReadingsTableTable> {
  $$ZReadingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zCounter => $composableBuilder(
    column: $table.zCounter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closedByUserId => $composableBuilder(
    column: $table.closedByUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closedByName => $composableBuilder(
    column: $table.closedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get authorizedByUserId => $composableBuilder(
    column: $table.authorizedByUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorizedByName => $composableBuilder(
    column: $table.authorizedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get beginningBalance => $composableBuilder(
    column: $table.beginningBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endingBalance => $composableBuilder(
    column: $table.endingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatableSales => $composableBuilder(
    column: $table.vatableSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatAmount => $composableBuilder(
    column: $table.vatAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatExemptSales => $composableBuilder(
    column: $table.vatExemptSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get voidedCount => $composableBuilder(
    column: $table.voidedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refundedCount => $composableBuilder(
    column: $table.refundedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashCollected => $composableBuilder(
    column: $table.cashCollected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQtySold => $composableBuilder(
    column: $table.totalQtySold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentBreakdownJson => $composableBuilder(
    column: $table.paymentBreakdownJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salesByCashierJson => $composableBuilder(
    column: $table.salesByCashierJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountsJson => $composableBuilder(
    column: $table.discountsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentLedgersJson => $composableBuilder(
    column: $table.paymentLedgersJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ZReadingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ZReadingsTableTable> {
  $$ZReadingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get zCounter =>
      $composableBuilder(column: $table.zCounter, builder: (column) => column);

  GeneratedColumn<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get closedByUserId => $composableBuilder(
    column: $table.closedByUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get closedByName => $composableBuilder(
    column: $table.closedByName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get authorizedByUserId => $composableBuilder(
    column: $table.authorizedByUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorizedByName => $composableBuilder(
    column: $table.authorizedByName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get beginningBalance => $composableBuilder(
    column: $table.beginningBalance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get endingBalance => $composableBuilder(
    column: $table.endingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalSales => $composableBuilder(
    column: $table.totalSales,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vatableSales => $composableBuilder(
    column: $table.vatableSales,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vatAmount =>
      $composableBuilder(column: $table.vatAmount, builder: (column) => column);

  GeneratedColumn<double> get vatExemptSales => $composableBuilder(
    column: $table.vatExemptSales,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get voidedCount => $composableBuilder(
    column: $table.voidedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get refundedCount => $composableBuilder(
    column: $table.refundedCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashCollected => $composableBuilder(
    column: $table.cashCollected,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalQtySold => $composableBuilder(
    column: $table.totalQtySold,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentBreakdownJson => $composableBuilder(
    column: $table.paymentBreakdownJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get salesByCashierJson => $composableBuilder(
    column: $table.salesByCashierJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountsJson => $composableBuilder(
    column: $table.discountsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentLedgersJson => $composableBuilder(
    column: $table.paymentLedgersJson,
    builder: (column) => column,
  );
}

class $$ZReadingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ZReadingsTableTable,
          ZReadingsTableData,
          $$ZReadingsTableTableFilterComposer,
          $$ZReadingsTableTableOrderingComposer,
          $$ZReadingsTableTableAnnotationComposer,
          $$ZReadingsTableTableCreateCompanionBuilder,
          $$ZReadingsTableTableUpdateCompanionBuilder,
          (
            ZReadingsTableData,
            BaseReferences<
              _$AppDatabase,
              $ZReadingsTableTable,
              ZReadingsTableData
            >,
          ),
          ZReadingsTableData,
          PrefetchHooks Function()
        > {
  $$ZReadingsTableTableTableManager(
    _$AppDatabase db,
    $ZReadingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ZReadingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$ZReadingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ZReadingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> zCounter = const Value.absent(),
                Value<DateTime> periodStart = const Value.absent(),
                Value<DateTime> periodEnd = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<int> closedByUserId = const Value.absent(),
                Value<String> closedByName = const Value.absent(),
                Value<int> authorizedByUserId = const Value.absent(),
                Value<String> authorizedByName = const Value.absent(),
                Value<double> beginningBalance = const Value.absent(),
                Value<double> endingBalance = const Value.absent(),
                Value<double> totalSales = const Value.absent(),
                Value<double> vatableSales = const Value.absent(),
                Value<double> vatAmount = const Value.absent(),
                Value<double> vatExemptSales = const Value.absent(),
                Value<int> transactionCount = const Value.absent(),
                Value<int> completedCount = const Value.absent(),
                Value<int> voidedCount = const Value.absent(),
                Value<int> refundedCount = const Value.absent(),
                Value<double> discountTotal = const Value.absent(),
                Value<double> cashCollected = const Value.absent(),
                Value<int> totalQtySold = const Value.absent(),
                Value<String> paymentBreakdownJson = const Value.absent(),
                Value<String> salesByCashierJson = const Value.absent(),
                Value<String> discountsJson = const Value.absent(),
                Value<String> paymentLedgersJson = const Value.absent(),
              }) => ZReadingsTableCompanion(
                id: id,
                zCounter: zCounter,
                periodStart: periodStart,
                periodEnd: periodEnd,
                generatedAt: generatedAt,
                closedByUserId: closedByUserId,
                closedByName: closedByName,
                authorizedByUserId: authorizedByUserId,
                authorizedByName: authorizedByName,
                beginningBalance: beginningBalance,
                endingBalance: endingBalance,
                totalSales: totalSales,
                vatableSales: vatableSales,
                vatAmount: vatAmount,
                vatExemptSales: vatExemptSales,
                transactionCount: transactionCount,
                completedCount: completedCount,
                voidedCount: voidedCount,
                refundedCount: refundedCount,
                discountTotal: discountTotal,
                cashCollected: cashCollected,
                totalQtySold: totalQtySold,
                paymentBreakdownJson: paymentBreakdownJson,
                salesByCashierJson: salesByCashierJson,
                discountsJson: discountsJson,
                paymentLedgersJson: paymentLedgersJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int zCounter,
                required DateTime periodStart,
                required DateTime periodEnd,
                required DateTime generatedAt,
                required int closedByUserId,
                required String closedByName,
                required int authorizedByUserId,
                required String authorizedByName,
                required double beginningBalance,
                required double endingBalance,
                required double totalSales,
                required double vatableSales,
                required double vatAmount,
                required double vatExemptSales,
                required int transactionCount,
                required int completedCount,
                required int voidedCount,
                required int refundedCount,
                required double discountTotal,
                required double cashCollected,
                required int totalQtySold,
                required String paymentBreakdownJson,
                required String salesByCashierJson,
                Value<String> discountsJson = const Value.absent(),
                Value<String> paymentLedgersJson = const Value.absent(),
              }) => ZReadingsTableCompanion.insert(
                id: id,
                zCounter: zCounter,
                periodStart: periodStart,
                periodEnd: periodEnd,
                generatedAt: generatedAt,
                closedByUserId: closedByUserId,
                closedByName: closedByName,
                authorizedByUserId: authorizedByUserId,
                authorizedByName: authorizedByName,
                beginningBalance: beginningBalance,
                endingBalance: endingBalance,
                totalSales: totalSales,
                vatableSales: vatableSales,
                vatAmount: vatAmount,
                vatExemptSales: vatExemptSales,
                transactionCount: transactionCount,
                completedCount: completedCount,
                voidedCount: voidedCount,
                refundedCount: refundedCount,
                discountTotal: discountTotal,
                cashCollected: cashCollected,
                totalQtySold: totalQtySold,
                paymentBreakdownJson: paymentBreakdownJson,
                salesByCashierJson: salesByCashierJson,
                discountsJson: discountsJson,
                paymentLedgersJson: paymentLedgersJson,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ZReadingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ZReadingsTableTable,
      ZReadingsTableData,
      $$ZReadingsTableTableFilterComposer,
      $$ZReadingsTableTableOrderingComposer,
      $$ZReadingsTableTableAnnotationComposer,
      $$ZReadingsTableTableCreateCompanionBuilder,
      $$ZReadingsTableTableUpdateCompanionBuilder,
      (
        ZReadingsTableData,
        BaseReferences<_$AppDatabase, $ZReadingsTableTable, ZReadingsTableData>,
      ),
      ZReadingsTableData,
      PrefetchHooks Function()
    >;
typedef $$PaymentMethodsTableTableCreateCompanionBuilder =
    PaymentMethodsTableCompanion Function({
      Value<int> id,
      required String label,
      Value<String?> accountName,
      Value<String?> accountNumber,
      Value<int> sortOrder,
    });
typedef $$PaymentMethodsTableTableUpdateCompanionBuilder =
    PaymentMethodsTableCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<String?> accountName,
      Value<String?> accountNumber,
      Value<int> sortOrder,
    });

class $$PaymentMethodsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTableTable> {
  $$PaymentMethodsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentMethodsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTableTable> {
  $$PaymentMethodsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentMethodsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTableTable> {
  $$PaymentMethodsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$PaymentMethodsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentMethodsTableTable,
          PaymentMethodsTableData,
          $$PaymentMethodsTableTableFilterComposer,
          $$PaymentMethodsTableTableOrderingComposer,
          $$PaymentMethodsTableTableAnnotationComposer,
          $$PaymentMethodsTableTableCreateCompanionBuilder,
          $$PaymentMethodsTableTableUpdateCompanionBuilder,
          (
            PaymentMethodsTableData,
            BaseReferences<
              _$AppDatabase,
              $PaymentMethodsTableTable,
              PaymentMethodsTableData
            >,
          ),
          PaymentMethodsTableData,
          PrefetchHooks Function()
        > {
  $$PaymentMethodsTableTableTableManager(
    _$AppDatabase db,
    $PaymentMethodsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PaymentMethodsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$PaymentMethodsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$PaymentMethodsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> accountName = const Value.absent(),
                Value<String?> accountNumber = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => PaymentMethodsTableCompanion(
                id: id,
                label: label,
                accountName: accountName,
                accountNumber: accountNumber,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                Value<String?> accountName = const Value.absent(),
                Value<String?> accountNumber = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => PaymentMethodsTableCompanion.insert(
                id: id,
                label: label,
                accountName: accountName,
                accountNumber: accountNumber,
                sortOrder: sortOrder,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentMethodsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentMethodsTableTable,
      PaymentMethodsTableData,
      $$PaymentMethodsTableTableFilterComposer,
      $$PaymentMethodsTableTableOrderingComposer,
      $$PaymentMethodsTableTableAnnotationComposer,
      $$PaymentMethodsTableTableCreateCompanionBuilder,
      $$PaymentMethodsTableTableUpdateCompanionBuilder,
      (
        PaymentMethodsTableData,
        BaseReferences<
          _$AppDatabase,
          $PaymentMethodsTableTable,
          PaymentMethodsTableData
        >,
      ),
      PaymentMethodsTableData,
      PrefetchHooks Function()
    >;
typedef $$OrderEventsTableTableCreateCompanionBuilder =
    OrderEventsTableCompanion Function({
      required String orderId,
      required String storeId,
      required String eventType,
      required String payload,
      Value<DateTime> updatedAt,
      Value<int> syncGeneration,
      Value<int> rowid,
    });
typedef $$OrderEventsTableTableUpdateCompanionBuilder =
    OrderEventsTableCompanion Function({
      Value<String> orderId,
      Value<String> storeId,
      Value<String> eventType,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<int> syncGeneration,
      Value<int> rowid,
    });

class $$OrderEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $OrderEventsTableTable> {
  $$OrderEventsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrderEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderEventsTableTable> {
  $$OrderEventsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrderEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderEventsTableTable> {
  $$OrderEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => column,
  );
}

class $$OrderEventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrderEventsTableTable,
          OrderEventsTableData,
          $$OrderEventsTableTableFilterComposer,
          $$OrderEventsTableTableOrderingComposer,
          $$OrderEventsTableTableAnnotationComposer,
          $$OrderEventsTableTableCreateCompanionBuilder,
          $$OrderEventsTableTableUpdateCompanionBuilder,
          (
            OrderEventsTableData,
            BaseReferences<
              _$AppDatabase,
              $OrderEventsTableTable,
              OrderEventsTableData
            >,
          ),
          OrderEventsTableData,
          PrefetchHooks Function()
        > {
  $$OrderEventsTableTableTableManager(
    _$AppDatabase db,
    $OrderEventsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$OrderEventsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$OrderEventsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$OrderEventsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> orderId = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> syncGeneration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderEventsTableCompanion(
                orderId: orderId,
                storeId: storeId,
                eventType: eventType,
                payload: payload,
                updatedAt: updatedAt,
                syncGeneration: syncGeneration,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String orderId,
                required String storeId,
                required String eventType,
                required String payload,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> syncGeneration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderEventsTableCompanion.insert(
                orderId: orderId,
                storeId: storeId,
                eventType: eventType,
                payload: payload,
                updatedAt: updatedAt,
                syncGeneration: syncGeneration,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrderEventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrderEventsTableTable,
      OrderEventsTableData,
      $$OrderEventsTableTableFilterComposer,
      $$OrderEventsTableTableOrderingComposer,
      $$OrderEventsTableTableAnnotationComposer,
      $$OrderEventsTableTableCreateCompanionBuilder,
      $$OrderEventsTableTableUpdateCompanionBuilder,
      (
        OrderEventsTableData,
        BaseReferences<
          _$AppDatabase,
          $OrderEventsTableTable,
          OrderEventsTableData
        >,
      ),
      OrderEventsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db, _db.usersTable);
  $$ProductGroupsTableTableTableManager get productGroupsTable =>
      $$ProductGroupsTableTableTableManager(_db, _db.productGroupsTable);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$ProductVariantsTableTableTableManager get productVariantsTable =>
      $$ProductVariantsTableTableTableManager(_db, _db.productVariantsTable);
  $$ModifierGroupsTableTableTableManager get modifierGroupsTable =>
      $$ModifierGroupsTableTableTableManager(_db, _db.modifierGroupsTable);
  $$ModifierOptionsTableTableTableManager get modifierOptionsTable =>
      $$ModifierOptionsTableTableTableManager(_db, _db.modifierOptionsTable);
  $$ProductModifierGroupsTableTableTableManager
  get productModifierGroupsTable =>
      $$ProductModifierGroupsTableTableTableManager(
        _db,
        _db.productModifierGroupsTable,
      );
  $$SalesTableTableTableManager get salesTable =>
      $$SalesTableTableTableManager(_db, _db.salesTable);
  $$SaleItemsTableTableTableManager get saleItemsTable =>
      $$SaleItemsTableTableTableManager(_db, _db.saleItemsTable);
  $$SaleItemModifiersTableTableTableManager get saleItemModifiersTable =>
      $$SaleItemModifiersTableTableTableManager(
        _db,
        _db.saleItemModifiersTable,
      );
  $$PaymentsTableTableTableManager get paymentsTable =>
      $$PaymentsTableTableTableManager(_db, _db.paymentsTable);
  $$RefundsTableTableTableManager get refundsTable =>
      $$RefundsTableTableTableManager(_db, _db.refundsTable);
  $$RefundItemsTableTableTableManager get refundItemsTable =>
      $$RefundItemsTableTableTableManager(_db, _db.refundItemsTable);
  $$StoreInfoTableTableTableManager get storeInfoTable =>
      $$StoreInfoTableTableTableManager(_db, _db.storeInfoTable);
  $$XReadingsTableTableTableManager get xReadingsTable =>
      $$XReadingsTableTableTableManager(_db, _db.xReadingsTable);
  $$DailyReportsTableTableTableManager get dailyReportsTable =>
      $$DailyReportsTableTableTableManager(_db, _db.dailyReportsTable);
  $$ZReadingsTableTableTableManager get zReadingsTable =>
      $$ZReadingsTableTableTableManager(_db, _db.zReadingsTable);
  $$PaymentMethodsTableTableTableManager get paymentMethodsTable =>
      $$PaymentMethodsTableTableTableManager(_db, _db.paymentMethodsTable);
  $$OrderEventsTableTableTableManager get orderEventsTable =>
      $$OrderEventsTableTableTableManager(_db, _db.orderEventsTable);
}
