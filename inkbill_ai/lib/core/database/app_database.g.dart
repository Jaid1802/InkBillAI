// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $InkStrokesTable extends InkStrokes
    with TableInfo<$InkStrokesTable, InkStrokeData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InkStrokesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
      'width', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _pointsJsonMeta =
      const VerificationMeta('pointsJson');
  @override
  late final GeneratedColumn<String> pointsJson = GeneratedColumn<String>(
      'points_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isErasedMeta =
      const VerificationMeta('isErased');
  @override
  late final GeneratedColumn<bool> isErased = GeneratedColumn<bool>(
      'is_erased', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_erased" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, pageId, color, width, pointsJson, createdAt, isErased];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ink_strokes';
  @override
  VerificationContext validateIntegrity(Insertable<InkStrokeData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('points_json')) {
      context.handle(
          _pointsJsonMeta,
          pointsJson.isAcceptableOrUnknown(
              data['points_json']!, _pointsJsonMeta));
    } else if (isInserting) {
      context.missing(_pointsJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_erased')) {
      context.handle(_isErasedMeta,
          isErased.isAcceptableOrUnknown(data['is_erased']!, _isErasedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InkStrokeData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InkStrokeData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}width'])!,
      pointsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}points_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      isErased: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_erased'])!,
    );
  }

  @override
  $InkStrokesTable createAlias(String alias) {
    return $InkStrokesTable(attachedDatabase, alias);
  }
}

class InkStrokeData extends DataClass implements Insertable<InkStrokeData> {
  final String id;
  final String pageId;
  final int color;
  final double width;
  final String pointsJson;
  final int createdAt;
  final bool isErased;
  const InkStrokeData(
      {required this.id,
      required this.pageId,
      required this.color,
      required this.width,
      required this.pointsJson,
      required this.createdAt,
      required this.isErased});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['color'] = Variable<int>(color);
    map['width'] = Variable<double>(width);
    map['points_json'] = Variable<String>(pointsJson);
    map['created_at'] = Variable<int>(createdAt);
    map['is_erased'] = Variable<bool>(isErased);
    return map;
  }

  InkStrokesCompanion toCompanion(bool nullToAbsent) {
    return InkStrokesCompanion(
      id: Value(id),
      pageId: Value(pageId),
      color: Value(color),
      width: Value(width),
      pointsJson: Value(pointsJson),
      createdAt: Value(createdAt),
      isErased: Value(isErased),
    );
  }

  factory InkStrokeData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InkStrokeData(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      color: serializer.fromJson<int>(json['color']),
      width: serializer.fromJson<double>(json['width']),
      pointsJson: serializer.fromJson<String>(json['pointsJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      isErased: serializer.fromJson<bool>(json['isErased']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'color': serializer.toJson<int>(color),
      'width': serializer.toJson<double>(width),
      'pointsJson': serializer.toJson<String>(pointsJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'isErased': serializer.toJson<bool>(isErased),
    };
  }

  InkStrokeData copyWith(
          {String? id,
          String? pageId,
          int? color,
          double? width,
          String? pointsJson,
          int? createdAt,
          bool? isErased}) =>
      InkStrokeData(
        id: id ?? this.id,
        pageId: pageId ?? this.pageId,
        color: color ?? this.color,
        width: width ?? this.width,
        pointsJson: pointsJson ?? this.pointsJson,
        createdAt: createdAt ?? this.createdAt,
        isErased: isErased ?? this.isErased,
      );
  InkStrokeData copyWithCompanion(InkStrokesCompanion data) {
    return InkStrokeData(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      color: data.color.present ? data.color.value : this.color,
      width: data.width.present ? data.width.value : this.width,
      pointsJson:
          data.pointsJson.present ? data.pointsJson.value : this.pointsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isErased: data.isErased.present ? data.isErased.value : this.isErased,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InkStrokeData(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('color: $color, ')
          ..write('width: $width, ')
          ..write('pointsJson: $pointsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('isErased: $isErased')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, pageId, color, width, pointsJson, createdAt, isErased);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InkStrokeData &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.color == this.color &&
          other.width == this.width &&
          other.pointsJson == this.pointsJson &&
          other.createdAt == this.createdAt &&
          other.isErased == this.isErased);
}

class InkStrokesCompanion extends UpdateCompanion<InkStrokeData> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<int> color;
  final Value<double> width;
  final Value<String> pointsJson;
  final Value<int> createdAt;
  final Value<bool> isErased;
  final Value<int> rowid;
  const InkStrokesCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.color = const Value.absent(),
    this.width = const Value.absent(),
    this.pointsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isErased = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InkStrokesCompanion.insert({
    required String id,
    required String pageId,
    required int color,
    required double width,
    required String pointsJson,
    required int createdAt,
    this.isErased = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        pageId = Value(pageId),
        color = Value(color),
        width = Value(width),
        pointsJson = Value(pointsJson),
        createdAt = Value(createdAt);
  static Insertable<InkStrokeData> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<int>? color,
    Expression<double>? width,
    Expression<String>? pointsJson,
    Expression<int>? createdAt,
    Expression<bool>? isErased,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (color != null) 'color': color,
      if (width != null) 'width': width,
      if (pointsJson != null) 'points_json': pointsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (isErased != null) 'is_erased': isErased,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InkStrokesCompanion copyWith(
      {Value<String>? id,
      Value<String>? pageId,
      Value<int>? color,
      Value<double>? width,
      Value<String>? pointsJson,
      Value<int>? createdAt,
      Value<bool>? isErased,
      Value<int>? rowid}) {
    return InkStrokesCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      color: color ?? this.color,
      width: width ?? this.width,
      pointsJson: pointsJson ?? this.pointsJson,
      createdAt: createdAt ?? this.createdAt,
      isErased: isErased ?? this.isErased,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (pointsJson.present) {
      map['points_json'] = Variable<String>(pointsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (isErased.present) {
      map['is_erased'] = Variable<bool>(isErased.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InkStrokesCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('color: $color, ')
          ..write('width: $width, ')
          ..write('pointsJson: $pointsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('isErased: $isErased, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InkPagesTable extends InkPages
    with TableInfo<$InkPagesTable, InkPageData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InkPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
      'bill_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, billId, createdAt, updatedAt, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ink_pages';
  @override
  VerificationContext validateIntegrity(Insertable<InkPageData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(_billIdMeta,
          billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InkPageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InkPageData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      billId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bill_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label']),
    );
  }

  @override
  $InkPagesTable createAlias(String alias) {
    return $InkPagesTable(attachedDatabase, alias);
  }
}

class InkPageData extends DataClass implements Insertable<InkPageData> {
  final String id;
  final String? billId;
  final int createdAt;
  final int updatedAt;
  final String? label;
  const InkPageData(
      {required this.id,
      this.billId,
      required this.createdAt,
      required this.updatedAt,
      this.label});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || billId != null) {
      map['bill_id'] = Variable<String>(billId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    return map;
  }

  InkPagesCompanion toCompanion(bool nullToAbsent) {
    return InkPagesCompanion(
      id: Value(id),
      billId:
          billId == null && nullToAbsent ? const Value.absent() : Value(billId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
    );
  }

  factory InkPageData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InkPageData(
      id: serializer.fromJson<String>(json['id']),
      billId: serializer.fromJson<String?>(json['billId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      label: serializer.fromJson<String?>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billId': serializer.toJson<String?>(billId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'label': serializer.toJson<String?>(label),
    };
  }

  InkPageData copyWith(
          {String? id,
          Value<String?> billId = const Value.absent(),
          int? createdAt,
          int? updatedAt,
          Value<String?> label = const Value.absent()}) =>
      InkPageData(
        id: id ?? this.id,
        billId: billId.present ? billId.value : this.billId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        label: label.present ? label.value : this.label,
      );
  InkPageData copyWithCompanion(InkPagesCompanion data) {
    return InkPageData(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InkPageData(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, billId, createdAt, updatedAt, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InkPageData &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.label == this.label);
}

class InkPagesCompanion extends UpdateCompanion<InkPageData> {
  final Value<String> id;
  final Value<String?> billId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String?> label;
  final Value<int> rowid;
  const InkPagesCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InkPagesCompanion.insert({
    required String id,
    this.billId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<InkPageData> custom({
    Expression<String>? id,
    Expression<String>? billId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InkPagesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? billId,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<String?>? label,
      Value<int>? rowid}) {
    return InkPagesCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InkPagesCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InkTimelineEventsTable extends InkTimelineEvents
    with TableInfo<$InkTimelineEventsTable, InkTimelineEventData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InkTimelineEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _strokeIdMeta =
      const VerificationMeta('strokeId');
  @override
  late final GeneratedColumn<String> strokeId = GeneratedColumn<String>(
      'stroke_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMsMeta =
      const VerificationMeta('timestampMs');
  @override
  late final GeneratedColumn<int> timestampMs = GeneratedColumn<int>(
      'timestamp_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _metadataJsonMeta =
      const VerificationMeta('metadataJson');
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
      'metadata_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, strokeId, pageId, timestampMs, metadataJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ink_timeline_events';
  @override
  VerificationContext validateIntegrity(
      Insertable<InkTimelineEventData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('stroke_id')) {
      context.handle(_strokeIdMeta,
          strokeId.isAcceptableOrUnknown(data['stroke_id']!, _strokeIdMeta));
    } else if (isInserting) {
      context.missing(_strokeIdMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('timestamp_ms')) {
      context.handle(
          _timestampMsMeta,
          timestampMs.isAcceptableOrUnknown(
              data['timestamp_ms']!, _timestampMsMeta));
    } else if (isInserting) {
      context.missing(_timestampMsMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
          _metadataJsonMeta,
          metadataJson.isAcceptableOrUnknown(
              data['metadata_json']!, _metadataJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InkTimelineEventData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InkTimelineEventData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      strokeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stroke_id'])!,
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      timestampMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp_ms'])!,
      metadataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata_json']),
    );
  }

  @override
  $InkTimelineEventsTable createAlias(String alias) {
    return $InkTimelineEventsTable(attachedDatabase, alias);
  }
}

class InkTimelineEventData extends DataClass
    implements Insertable<InkTimelineEventData> {
  final String id;
  final String type;
  final String strokeId;
  final String pageId;
  final int timestampMs;
  final String? metadataJson;
  const InkTimelineEventData(
      {required this.id,
      required this.type,
      required this.strokeId,
      required this.pageId,
      required this.timestampMs,
      this.metadataJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['stroke_id'] = Variable<String>(strokeId);
    map['page_id'] = Variable<String>(pageId);
    map['timestamp_ms'] = Variable<int>(timestampMs);
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    return map;
  }

  InkTimelineEventsCompanion toCompanion(bool nullToAbsent) {
    return InkTimelineEventsCompanion(
      id: Value(id),
      type: Value(type),
      strokeId: Value(strokeId),
      pageId: Value(pageId),
      timestampMs: Value(timestampMs),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
    );
  }

  factory InkTimelineEventData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InkTimelineEventData(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      strokeId: serializer.fromJson<String>(json['strokeId']),
      pageId: serializer.fromJson<String>(json['pageId']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'strokeId': serializer.toJson<String>(strokeId),
      'pageId': serializer.toJson<String>(pageId),
      'timestampMs': serializer.toJson<int>(timestampMs),
      'metadataJson': serializer.toJson<String?>(metadataJson),
    };
  }

  InkTimelineEventData copyWith(
          {String? id,
          String? type,
          String? strokeId,
          String? pageId,
          int? timestampMs,
          Value<String?> metadataJson = const Value.absent()}) =>
      InkTimelineEventData(
        id: id ?? this.id,
        type: type ?? this.type,
        strokeId: strokeId ?? this.strokeId,
        pageId: pageId ?? this.pageId,
        timestampMs: timestampMs ?? this.timestampMs,
        metadataJson:
            metadataJson.present ? metadataJson.value : this.metadataJson,
      );
  InkTimelineEventData copyWithCompanion(InkTimelineEventsCompanion data) {
    return InkTimelineEventData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      strokeId: data.strokeId.present ? data.strokeId.value : this.strokeId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      timestampMs:
          data.timestampMs.present ? data.timestampMs.value : this.timestampMs,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InkTimelineEventData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('strokeId: $strokeId, ')
          ..write('pageId: $pageId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, strokeId, pageId, timestampMs, metadataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InkTimelineEventData &&
          other.id == this.id &&
          other.type == this.type &&
          other.strokeId == this.strokeId &&
          other.pageId == this.pageId &&
          other.timestampMs == this.timestampMs &&
          other.metadataJson == this.metadataJson);
}

class InkTimelineEventsCompanion extends UpdateCompanion<InkTimelineEventData> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> strokeId;
  final Value<String> pageId;
  final Value<int> timestampMs;
  final Value<String?> metadataJson;
  final Value<int> rowid;
  const InkTimelineEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.strokeId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InkTimelineEventsCompanion.insert({
    required String id,
    required String type,
    required String strokeId,
    required String pageId,
    required int timestampMs,
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        strokeId = Value(strokeId),
        pageId = Value(pageId),
        timestampMs = Value(timestampMs);
  static Insertable<InkTimelineEventData> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? strokeId,
    Expression<String>? pageId,
    Expression<int>? timestampMs,
    Expression<String>? metadataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (strokeId != null) 'stroke_id': strokeId,
      if (pageId != null) 'page_id': pageId,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InkTimelineEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String>? strokeId,
      Value<String>? pageId,
      Value<int>? timestampMs,
      Value<String?>? metadataJson,
      Value<int>? rowid}) {
    return InkTimelineEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      strokeId: strokeId ?? this.strokeId,
      pageId: pageId ?? this.pageId,
      timestampMs: timestampMs ?? this.timestampMs,
      metadataJson: metadataJson ?? this.metadataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (strokeId.present) {
      map['stroke_id'] = Variable<String>(strokeId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InkTimelineEventsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('strokeId: $strokeId, ')
          ..write('pageId: $pageId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillsTable extends Bills with TableInfo<$BillsTable, BillsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _taxRateMeta =
      const VerificationMeta('taxRate');
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
      'tax_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _taxAmountMeta =
      const VerificationMeta('taxAmount');
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
      'tax_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
      'discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _inkPageIdMeta =
      const VerificationMeta('inkPageId');
  @override
  late final GeneratedColumn<String> inkPageId = GeneratedColumn<String>(
      'ink_page_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        customerId,
        customerName,
        subtotal,
        taxRate,
        taxAmount,
        discount,
        total,
        status,
        createdAt,
        updatedAt,
        notes,
        inkPageId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(Insertable<BillsData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    }
    if (data.containsKey('tax_rate')) {
      context.handle(_taxRateMeta,
          taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta));
    }
    if (data.containsKey('tax_amount')) {
      context.handle(_taxAmountMeta,
          taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('ink_page_id')) {
      context.handle(
          _inkPageIdMeta,
          inkPageId.isAcceptableOrUnknown(
              data['ink_page_id']!, _inkPageIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id']),
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name']),
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
      taxRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_rate'])!,
      taxAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_amount'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      inkPageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ink_page_id']),
    );
  }

  @override
  $BillsTable createAlias(String alias) {
    return $BillsTable(attachedDatabase, alias);
  }
}

class BillsData extends DataClass implements Insertable<BillsData> {
  final String id;
  final String? customerId;
  final String? customerName;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double discount;
  final double total;
  final String status;
  final int createdAt;
  final int updatedAt;
  final String? notes;
  final String? inkPageId;
  const BillsData(
      {required this.id,
      this.customerId,
      this.customerName,
      required this.subtotal,
      required this.taxRate,
      required this.taxAmount,
      required this.discount,
      required this.total,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      this.notes,
      this.inkPageId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['tax_rate'] = Variable<double>(taxRate);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['discount'] = Variable<double>(discount);
    map['total'] = Variable<double>(total);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || inkPageId != null) {
      map['ink_page_id'] = Variable<String>(inkPageId);
    }
    return map;
  }

  BillsCompanion toCompanion(bool nullToAbsent) {
    return BillsCompanion(
      id: Value(id),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      subtotal: Value(subtotal),
      taxRate: Value(taxRate),
      taxAmount: Value(taxAmount),
      discount: Value(discount),
      total: Value(total),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      inkPageId: inkPageId == null && nullToAbsent
          ? const Value.absent()
          : Value(inkPageId),
    );
  }

  factory BillsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillsData(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      taxRate: serializer.fromJson<double>(json['taxRate']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      discount: serializer.fromJson<double>(json['discount']),
      total: serializer.fromJson<double>(json['total']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      inkPageId: serializer.fromJson<String?>(json['inkPageId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String?>(customerId),
      'customerName': serializer.toJson<String?>(customerName),
      'subtotal': serializer.toJson<double>(subtotal),
      'taxRate': serializer.toJson<double>(taxRate),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'discount': serializer.toJson<double>(discount),
      'total': serializer.toJson<double>(total),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'notes': serializer.toJson<String?>(notes),
      'inkPageId': serializer.toJson<String?>(inkPageId),
    };
  }

  BillsData copyWith(
          {String? id,
          Value<String?> customerId = const Value.absent(),
          Value<String?> customerName = const Value.absent(),
          double? subtotal,
          double? taxRate,
          double? taxAmount,
          double? discount,
          double? total,
          String? status,
          int? createdAt,
          int? updatedAt,
          Value<String?> notes = const Value.absent(),
          Value<String?> inkPageId = const Value.absent()}) =>
      BillsData(
        id: id ?? this.id,
        customerId: customerId.present ? customerId.value : this.customerId,
        customerName:
            customerName.present ? customerName.value : this.customerName,
        subtotal: subtotal ?? this.subtotal,
        taxRate: taxRate ?? this.taxRate,
        taxAmount: taxAmount ?? this.taxAmount,
        discount: discount ?? this.discount,
        total: total ?? this.total,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        notes: notes.present ? notes.value : this.notes,
        inkPageId: inkPageId.present ? inkPageId.value : this.inkPageId,
      );
  BillsData copyWithCompanion(BillsCompanion data) {
    return BillsData(
      id: data.id.present ? data.id.value : this.id,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      discount: data.discount.present ? data.discount.value : this.discount,
      total: data.total.present ? data.total.value : this.total,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      inkPageId: data.inkPageId.present ? data.inkPageId.value : this.inkPageId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillsData(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('subtotal: $subtotal, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('discount: $discount, ')
          ..write('total: $total, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notes: $notes, ')
          ..write('inkPageId: $inkPageId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      customerId,
      customerName,
      subtotal,
      taxRate,
      taxAmount,
      discount,
      total,
      status,
      createdAt,
      updatedAt,
      notes,
      inkPageId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillsData &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.subtotal == this.subtotal &&
          other.taxRate == this.taxRate &&
          other.taxAmount == this.taxAmount &&
          other.discount == this.discount &&
          other.total == this.total &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.notes == this.notes &&
          other.inkPageId == this.inkPageId);
}

class BillsCompanion extends UpdateCompanion<BillsData> {
  final Value<String> id;
  final Value<String?> customerId;
  final Value<String?> customerName;
  final Value<double> subtotal;
  final Value<double> taxRate;
  final Value<double> taxAmount;
  final Value<double> discount;
  final Value<double> total;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String?> notes;
  final Value<String?> inkPageId;
  final Value<int> rowid;
  const BillsCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.discount = const Value.absent(),
    this.total = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.inkPageId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillsCompanion.insert({
    required String id,
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.discount = const Value.absent(),
    this.total = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.notes = const Value.absent(),
    this.inkPageId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<BillsData> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<double>? subtotal,
    Expression<double>? taxRate,
    Expression<double>? taxAmount,
    Expression<double>? discount,
    Expression<double>? total,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? notes,
    Expression<String>? inkPageId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (subtotal != null) 'subtotal': subtotal,
      if (taxRate != null) 'tax_rate': taxRate,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (discount != null) 'discount': discount,
      if (total != null) 'total': total,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (notes != null) 'notes': notes,
      if (inkPageId != null) 'ink_page_id': inkPageId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? customerId,
      Value<String?>? customerName,
      Value<double>? subtotal,
      Value<double>? taxRate,
      Value<double>? taxAmount,
      Value<double>? discount,
      Value<double>? total,
      Value<String>? status,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<String?>? notes,
      Value<String?>? inkPageId,
      Value<int>? rowid}) {
    return BillsCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      inkPageId: inkPageId ?? this.inkPageId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (inkPageId.present) {
      map['ink_page_id'] = Variable<String>(inkPageId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillsCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('subtotal: $subtotal, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('discount: $discount, ')
          ..write('total: $total, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notes: $notes, ')
          ..write('inkPageId: $inkPageId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillItemsTable extends BillItems
    with TableInfo<$BillItemsTable, BillItemsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
      'bill_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
      'rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gstRateMeta =
      const VerificationMeta('gstRate');
  @override
  late final GeneratedColumn<double> gstRate = GeneratedColumn<double>(
      'gst_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _hsnCodeMeta =
      const VerificationMeta('hsnCode');
  @override
  late final GeneratedColumn<String> hsnCode = GeneratedColumn<String>(
      'hsn_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, billId, name, quantity, rate, amount, unit, gstRate, hsnCode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_items';
  @override
  VerificationContext validateIntegrity(Insertable<BillItemsData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(_billIdMeta,
          billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta));
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('rate')) {
      context.handle(
          _rateMeta, rate.isAcceptableOrUnknown(data['rate']!, _rateMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('gst_rate')) {
      context.handle(_gstRateMeta,
          gstRate.isAcceptableOrUnknown(data['gst_rate']!, _gstRateMeta));
    }
    if (data.containsKey('hsn_code')) {
      context.handle(_hsnCodeMeta,
          hsnCode.isAcceptableOrUnknown(data['hsn_code']!, _hsnCodeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillItemsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillItemsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      billId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bill_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      rate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rate'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      gstRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gst_rate']),
      hsnCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hsn_code']),
    );
  }

  @override
  $BillItemsTable createAlias(String alias) {
    return $BillItemsTable(attachedDatabase, alias);
  }
}

class BillItemsData extends DataClass implements Insertable<BillItemsData> {
  final String id;
  final String billId;
  final String name;
  final double quantity;
  final double rate;
  final double amount;
  final String? unit;
  final double? gstRate;
  final String? hsnCode;
  const BillItemsData(
      {required this.id,
      required this.billId,
      required this.name,
      required this.quantity,
      required this.rate,
      required this.amount,
      this.unit,
      this.gstRate,
      this.hsnCode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bill_id'] = Variable<String>(billId);
    map['name'] = Variable<String>(name);
    map['quantity'] = Variable<double>(quantity);
    map['rate'] = Variable<double>(rate);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || gstRate != null) {
      map['gst_rate'] = Variable<double>(gstRate);
    }
    if (!nullToAbsent || hsnCode != null) {
      map['hsn_code'] = Variable<String>(hsnCode);
    }
    return map;
  }

  BillItemsCompanion toCompanion(bool nullToAbsent) {
    return BillItemsCompanion(
      id: Value(id),
      billId: Value(billId),
      name: Value(name),
      quantity: Value(quantity),
      rate: Value(rate),
      amount: Value(amount),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      gstRate: gstRate == null && nullToAbsent
          ? const Value.absent()
          : Value(gstRate),
      hsnCode: hsnCode == null && nullToAbsent
          ? const Value.absent()
          : Value(hsnCode),
    );
  }

  factory BillItemsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillItemsData(
      id: serializer.fromJson<String>(json['id']),
      billId: serializer.fromJson<String>(json['billId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<double>(json['quantity']),
      rate: serializer.fromJson<double>(json['rate']),
      amount: serializer.fromJson<double>(json['amount']),
      unit: serializer.fromJson<String?>(json['unit']),
      gstRate: serializer.fromJson<double?>(json['gstRate']),
      hsnCode: serializer.fromJson<String?>(json['hsnCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billId': serializer.toJson<String>(billId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<double>(quantity),
      'rate': serializer.toJson<double>(rate),
      'amount': serializer.toJson<double>(amount),
      'unit': serializer.toJson<String?>(unit),
      'gstRate': serializer.toJson<double?>(gstRate),
      'hsnCode': serializer.toJson<String?>(hsnCode),
    };
  }

  BillItemsData copyWith(
          {String? id,
          String? billId,
          String? name,
          double? quantity,
          double? rate,
          double? amount,
          Value<String?> unit = const Value.absent(),
          Value<double?> gstRate = const Value.absent(),
          Value<String?> hsnCode = const Value.absent()}) =>
      BillItemsData(
        id: id ?? this.id,
        billId: billId ?? this.billId,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        rate: rate ?? this.rate,
        amount: amount ?? this.amount,
        unit: unit.present ? unit.value : this.unit,
        gstRate: gstRate.present ? gstRate.value : this.gstRate,
        hsnCode: hsnCode.present ? hsnCode.value : this.hsnCode,
      );
  BillItemsData copyWithCompanion(BillItemsCompanion data) {
    return BillItemsData(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      rate: data.rate.present ? data.rate.value : this.rate,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      gstRate: data.gstRate.present ? data.gstRate.value : this.gstRate,
      hsnCode: data.hsnCode.present ? data.hsnCode.value : this.hsnCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillItemsData(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('rate: $rate, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('gstRate: $gstRate, ')
          ..write('hsnCode: $hsnCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, billId, name, quantity, rate, amount, unit, gstRate, hsnCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillItemsData &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.rate == this.rate &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.gstRate == this.gstRate &&
          other.hsnCode == this.hsnCode);
}

class BillItemsCompanion extends UpdateCompanion<BillItemsData> {
  final Value<String> id;
  final Value<String> billId;
  final Value<String> name;
  final Value<double> quantity;
  final Value<double> rate;
  final Value<double> amount;
  final Value<String?> unit;
  final Value<double?> gstRate;
  final Value<String?> hsnCode;
  final Value<int> rowid;
  const BillItemsCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.rate = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.gstRate = const Value.absent(),
    this.hsnCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillItemsCompanion.insert({
    required String id,
    required String billId,
    required String name,
    this.quantity = const Value.absent(),
    this.rate = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.gstRate = const Value.absent(),
    this.hsnCode = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        billId = Value(billId),
        name = Value(name);
  static Insertable<BillItemsData> custom({
    Expression<String>? id,
    Expression<String>? billId,
    Expression<String>? name,
    Expression<double>? quantity,
    Expression<double>? rate,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<double>? gstRate,
    Expression<String>? hsnCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (rate != null) 'rate': rate,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (gstRate != null) 'gst_rate': gstRate,
      if (hsnCode != null) 'hsn_code': hsnCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? billId,
      Value<String>? name,
      Value<double>? quantity,
      Value<double>? rate,
      Value<double>? amount,
      Value<String?>? unit,
      Value<double?>? gstRate,
      Value<String?>? hsnCode,
      Value<int>? rowid}) {
    return BillItemsCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      gstRate: gstRate ?? this.gstRate,
      hsnCode: hsnCode ?? this.hsnCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (gstRate.present) {
      map['gst_rate'] = Variable<double>(gstRate.value);
    }
    if (hsnCode.present) {
      map['hsn_code'] = Variable<String>(hsnCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillItemsCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('rate: $rate, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('gstRate: $gstRate, ')
          ..write('hsnCode: $hsnCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, CustomersData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gstinMeta = const VerificationMeta('gstin');
  @override
  late final GeneratedColumn<String> gstin = GeneratedColumn<String>(
      'gstin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _balanceMeta =
      const VerificationMeta('balance');
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
      'balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _totalPurchasesMeta =
      const VerificationMeta('totalPurchases');
  @override
  late final GeneratedColumn<double> totalPurchases = GeneratedColumn<double>(
      'total_purchases', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        phone,
        email,
        address,
        gstin,
        balance,
        totalPurchases,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<CustomersData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('gstin')) {
      context.handle(
          _gstinMeta, gstin.isAcceptableOrUnknown(data['gstin']!, _gstinMeta));
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    }
    if (data.containsKey('total_purchases')) {
      context.handle(
          _totalPurchasesMeta,
          totalPurchases.isAcceptableOrUnknown(
              data['total_purchases']!, _totalPurchasesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomersData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomersData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      gstin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gstin']),
      balance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}balance'])!,
      totalPurchases: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_purchases'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class CustomersData extends DataClass implements Insertable<CustomersData> {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstin;
  final double balance;
  final double totalPurchases;
  final int createdAt;
  final int updatedAt;
  const CustomersData(
      {required this.id,
      required this.name,
      this.phone,
      this.email,
      this.address,
      this.gstin,
      required this.balance,
      required this.totalPurchases,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || gstin != null) {
      map['gstin'] = Variable<String>(gstin);
    }
    map['balance'] = Variable<double>(balance);
    map['total_purchases'] = Variable<double>(totalPurchases);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      gstin:
          gstin == null && nullToAbsent ? const Value.absent() : Value(gstin),
      balance: Value(balance),
      totalPurchases: Value(totalPurchases),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomersData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomersData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      gstin: serializer.fromJson<String?>(json['gstin']),
      balance: serializer.fromJson<double>(json['balance']),
      totalPurchases: serializer.fromJson<double>(json['totalPurchases']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'gstin': serializer.toJson<String?>(gstin),
      'balance': serializer.toJson<double>(balance),
      'totalPurchases': serializer.toJson<double>(totalPurchases),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CustomersData copyWith(
          {String? id,
          String? name,
          Value<String?> phone = const Value.absent(),
          Value<String?> email = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> gstin = const Value.absent(),
          double? balance,
          double? totalPurchases,
          int? createdAt,
          int? updatedAt}) =>
      CustomersData(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone.present ? phone.value : this.phone,
        email: email.present ? email.value : this.email,
        address: address.present ? address.value : this.address,
        gstin: gstin.present ? gstin.value : this.gstin,
        balance: balance ?? this.balance,
        totalPurchases: totalPurchases ?? this.totalPurchases,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CustomersData copyWithCompanion(CustomersCompanion data) {
    return CustomersData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      gstin: data.gstin.present ? data.gstin.value : this.gstin,
      balance: data.balance.present ? data.balance.value : this.balance,
      totalPurchases: data.totalPurchases.present
          ? data.totalPurchases.value
          : this.totalPurchases,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomersData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('gstin: $gstin, ')
          ..write('balance: $balance, ')
          ..write('totalPurchases: $totalPurchases, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, email, address, gstin,
      balance, totalPurchases, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomersData &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.gstin == this.gstin &&
          other.balance == this.balance &&
          other.totalPurchases == this.totalPurchases &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomersCompanion extends UpdateCompanion<CustomersData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> address;
  final Value<String?> gstin;
  final Value<double> balance;
  final Value<double> totalPurchases;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.gstin = const Value.absent(),
    this.balance = const Value.absent(),
    this.totalPurchases = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.gstin = const Value.absent(),
    this.balance = const Value.absent(),
    this.totalPurchases = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CustomersData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? gstin,
    Expression<double>? balance,
    Expression<double>? totalPurchases,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (gstin != null) 'gstin': gstin,
      if (balance != null) 'balance': balance,
      if (totalPurchases != null) 'total_purchases': totalPurchases,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? phone,
      Value<String?>? email,
      Value<String?>? address,
      Value<String?>? gstin,
      Value<double>? balance,
      Value<double>? totalPurchases,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      balance: balance ?? this.balance,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (gstin.present) {
      map['gstin'] = Variable<String>(gstin.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (totalPurchases.present) {
      map['total_purchases'] = Variable<double>(totalPurchases.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('gstin: $gstin, ')
          ..write('balance: $balance, ')
          ..write('totalPurchases: $totalPurchases, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _gstRateMeta =
      const VerificationMeta('gstRate');
  @override
  late final GeneratedColumn<double> gstRate = GeneratedColumn<double>(
      'gst_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _hsnCodeMeta =
      const VerificationMeta('hsnCode');
  @override
  late final GeneratedColumn<String> hsnCode = GeneratedColumn<String>(
      'hsn_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<int> stock = GeneratedColumn<int>(
      'stock', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        price,
        gstRate,
        hsnCode,
        unit,
        stock,
        barcode,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<ProductsData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    }
    if (data.containsKey('gst_rate')) {
      context.handle(_gstRateMeta,
          gstRate.isAcceptableOrUnknown(data['gst_rate']!, _gstRateMeta));
    }
    if (data.containsKey('hsn_code')) {
      context.handle(_hsnCodeMeta,
          hsnCode.isAcceptableOrUnknown(data['hsn_code']!, _hsnCodeMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('stock')) {
      context.handle(
          _stockMeta, stock.isAcceptableOrUnknown(data['stock']!, _stockMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      gstRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gst_rate']),
      hsnCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hsn_code']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      stock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductsData extends DataClass implements Insertable<ProductsData> {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? gstRate;
  final String? hsnCode;
  final String? unit;
  final int stock;
  final String? barcode;
  final int createdAt;
  final int updatedAt;
  const ProductsData(
      {required this.id,
      required this.name,
      this.description,
      required this.price,
      this.gstRate,
      this.hsnCode,
      this.unit,
      required this.stock,
      this.barcode,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['price'] = Variable<double>(price);
    if (!nullToAbsent || gstRate != null) {
      map['gst_rate'] = Variable<double>(gstRate);
    }
    if (!nullToAbsent || hsnCode != null) {
      map['hsn_code'] = Variable<String>(hsnCode);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['stock'] = Variable<int>(stock);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      price: Value(price),
      gstRate: gstRate == null && nullToAbsent
          ? const Value.absent()
          : Value(gstRate),
      hsnCode: hsnCode == null && nullToAbsent
          ? const Value.absent()
          : Value(hsnCode),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      stock: Value(stock),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      price: serializer.fromJson<double>(json['price']),
      gstRate: serializer.fromJson<double?>(json['gstRate']),
      hsnCode: serializer.fromJson<String?>(json['hsnCode']),
      unit: serializer.fromJson<String?>(json['unit']),
      stock: serializer.fromJson<int>(json['stock']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'price': serializer.toJson<double>(price),
      'gstRate': serializer.toJson<double?>(gstRate),
      'hsnCode': serializer.toJson<String?>(hsnCode),
      'unit': serializer.toJson<String?>(unit),
      'stock': serializer.toJson<int>(stock),
      'barcode': serializer.toJson<String?>(barcode),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProductsData copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent(),
          double? price,
          Value<double?> gstRate = const Value.absent(),
          Value<String?> hsnCode = const Value.absent(),
          Value<String?> unit = const Value.absent(),
          int? stock,
          Value<String?> barcode = const Value.absent(),
          int? createdAt,
          int? updatedAt}) =>
      ProductsData(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        price: price ?? this.price,
        gstRate: gstRate.present ? gstRate.value : this.gstRate,
        hsnCode: hsnCode.present ? hsnCode.value : this.hsnCode,
        unit: unit.present ? unit.value : this.unit,
        stock: stock ?? this.stock,
        barcode: barcode.present ? barcode.value : this.barcode,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProductsData copyWithCompanion(ProductsCompanion data) {
    return ProductsData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      price: data.price.present ? data.price.value : this.price,
      gstRate: data.gstRate.present ? data.gstRate.value : this.gstRate,
      hsnCode: data.hsnCode.present ? data.hsnCode.value : this.hsnCode,
      unit: data.unit.present ? data.unit.value : this.unit,
      stock: data.stock.present ? data.stock.value : this.stock,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductsData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('gstRate: $gstRate, ')
          ..write('hsnCode: $hsnCode, ')
          ..write('unit: $unit, ')
          ..write('stock: $stock, ')
          ..write('barcode: $barcode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, price, gstRate,
      hsnCode, unit, stock, barcode, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.price == this.price &&
          other.gstRate == this.gstRate &&
          other.hsnCode == this.hsnCode &&
          other.unit == this.unit &&
          other.stock == this.stock &&
          other.barcode == this.barcode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<ProductsData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<double> price;
  final Value<double?> gstRate;
  final Value<String?> hsnCode;
  final Value<String?> unit;
  final Value<int> stock;
  final Value<String?> barcode;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.gstRate = const Value.absent(),
    this.hsnCode = const Value.absent(),
    this.unit = const Value.absent(),
    this.stock = const Value.absent(),
    this.barcode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.gstRate = const Value.absent(),
    this.hsnCode = const Value.absent(),
    this.unit = const Value.absent(),
    this.stock = const Value.absent(),
    this.barcode = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ProductsData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? price,
    Expression<double>? gstRate,
    Expression<String>? hsnCode,
    Expression<String>? unit,
    Expression<int>? stock,
    Expression<String>? barcode,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (gstRate != null) 'gst_rate': gstRate,
      if (hsnCode != null) 'hsn_code': hsnCode,
      if (unit != null) 'unit': unit,
      if (stock != null) 'stock': stock,
      if (barcode != null) 'barcode': barcode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<double>? price,
      Value<double?>? gstRate,
      Value<String?>? hsnCode,
      Value<String?>? unit,
      Value<int>? stock,
      Value<String?>? barcode,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
      hsnCode: hsnCode ?? this.hsnCode,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (gstRate.present) {
      map['gst_rate'] = Variable<double>(gstRate.value);
    }
    if (hsnCode.present) {
      map['hsn_code'] = Variable<String>(hsnCode.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (stock.present) {
      map['stock'] = Variable<int>(stock.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('gstRate: $gstRate, ')
          ..write('hsnCode: $hsnCode, ')
          ..write('unit: $unit, ')
          ..write('stock: $stock, ')
          ..write('barcode: $barcode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $InkStrokesTable inkStrokes = $InkStrokesTable(this);
  late final $InkPagesTable inkPages = $InkPagesTable(this);
  late final $InkTimelineEventsTable inkTimelineEvents =
      $InkTimelineEventsTable(this);
  late final $BillsTable bills = $BillsTable(this);
  late final $BillItemsTable billItems = $BillItemsTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        inkStrokes,
        inkPages,
        inkTimelineEvents,
        bills,
        billItems,
        customers,
        products
      ];
}

typedef $$InkStrokesTableCreateCompanionBuilder = InkStrokesCompanion Function({
  required String id,
  required String pageId,
  required int color,
  required double width,
  required String pointsJson,
  required int createdAt,
  Value<bool> isErased,
  Value<int> rowid,
});
typedef $$InkStrokesTableUpdateCompanionBuilder = InkStrokesCompanion Function({
  Value<String> id,
  Value<String> pageId,
  Value<int> color,
  Value<double> width,
  Value<String> pointsJson,
  Value<int> createdAt,
  Value<bool> isErased,
  Value<int> rowid,
});

class $$InkStrokesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InkStrokesTable,
    InkStrokeData,
    $$InkStrokesTableFilterComposer,
    $$InkStrokesTableOrderingComposer,
    $$InkStrokesTableCreateCompanionBuilder,
    $$InkStrokesTableUpdateCompanionBuilder> {
  $$InkStrokesTableTableManager(_$AppDatabase db, $InkStrokesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$InkStrokesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$InkStrokesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> pageId = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<double> width = const Value.absent(),
            Value<String> pointsJson = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<bool> isErased = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InkStrokesCompanion(
            id: id,
            pageId: pageId,
            color: color,
            width: width,
            pointsJson: pointsJson,
            createdAt: createdAt,
            isErased: isErased,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String pageId,
            required int color,
            required double width,
            required String pointsJson,
            required int createdAt,
            Value<bool> isErased = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InkStrokesCompanion.insert(
            id: id,
            pageId: pageId,
            color: color,
            width: width,
            pointsJson: pointsJson,
            createdAt: createdAt,
            isErased: isErased,
            rowid: rowid,
          ),
        ));
}

class $$InkStrokesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $InkStrokesTable> {
  $$InkStrokesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pageId => $state.composableBuilder(
      column: $state.table.pageId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get width => $state.composableBuilder(
      column: $state.table.width,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pointsJson => $state.composableBuilder(
      column: $state.table.pointsJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isErased => $state.composableBuilder(
      column: $state.table.isErased,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$InkStrokesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $InkStrokesTable> {
  $$InkStrokesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pageId => $state.composableBuilder(
      column: $state.table.pageId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get width => $state.composableBuilder(
      column: $state.table.width,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pointsJson => $state.composableBuilder(
      column: $state.table.pointsJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isErased => $state.composableBuilder(
      column: $state.table.isErased,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$InkPagesTableCreateCompanionBuilder = InkPagesCompanion Function({
  required String id,
  Value<String?> billId,
  required int createdAt,
  required int updatedAt,
  Value<String?> label,
  Value<int> rowid,
});
typedef $$InkPagesTableUpdateCompanionBuilder = InkPagesCompanion Function({
  Value<String> id,
  Value<String?> billId,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String?> label,
  Value<int> rowid,
});

class $$InkPagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InkPagesTable,
    InkPageData,
    $$InkPagesTableFilterComposer,
    $$InkPagesTableOrderingComposer,
    $$InkPagesTableCreateCompanionBuilder,
    $$InkPagesTableUpdateCompanionBuilder> {
  $$InkPagesTableTableManager(_$AppDatabase db, $InkPagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$InkPagesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$InkPagesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> billId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<String?> label = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InkPagesCompanion(
            id: id,
            billId: billId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            label: label,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> billId = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<String?> label = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InkPagesCompanion.insert(
            id: id,
            billId: billId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            label: label,
            rowid: rowid,
          ),
        ));
}

class $$InkPagesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $InkPagesTable> {
  $$InkPagesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get billId => $state.composableBuilder(
      column: $state.table.billId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get label => $state.composableBuilder(
      column: $state.table.label,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$InkPagesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $InkPagesTable> {
  $$InkPagesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get billId => $state.composableBuilder(
      column: $state.table.billId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get label => $state.composableBuilder(
      column: $state.table.label,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$InkTimelineEventsTableCreateCompanionBuilder
    = InkTimelineEventsCompanion Function({
  required String id,
  required String type,
  required String strokeId,
  required String pageId,
  required int timestampMs,
  Value<String?> metadataJson,
  Value<int> rowid,
});
typedef $$InkTimelineEventsTableUpdateCompanionBuilder
    = InkTimelineEventsCompanion Function({
  Value<String> id,
  Value<String> type,
  Value<String> strokeId,
  Value<String> pageId,
  Value<int> timestampMs,
  Value<String?> metadataJson,
  Value<int> rowid,
});

class $$InkTimelineEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InkTimelineEventsTable,
    InkTimelineEventData,
    $$InkTimelineEventsTableFilterComposer,
    $$InkTimelineEventsTableOrderingComposer,
    $$InkTimelineEventsTableCreateCompanionBuilder,
    $$InkTimelineEventsTableUpdateCompanionBuilder> {
  $$InkTimelineEventsTableTableManager(
      _$AppDatabase db, $InkTimelineEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$InkTimelineEventsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$InkTimelineEventsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> strokeId = const Value.absent(),
            Value<String> pageId = const Value.absent(),
            Value<int> timestampMs = const Value.absent(),
            Value<String?> metadataJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InkTimelineEventsCompanion(
            id: id,
            type: type,
            strokeId: strokeId,
            pageId: pageId,
            timestampMs: timestampMs,
            metadataJson: metadataJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String type,
            required String strokeId,
            required String pageId,
            required int timestampMs,
            Value<String?> metadataJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InkTimelineEventsCompanion.insert(
            id: id,
            type: type,
            strokeId: strokeId,
            pageId: pageId,
            timestampMs: timestampMs,
            metadataJson: metadataJson,
            rowid: rowid,
          ),
        ));
}

class $$InkTimelineEventsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $InkTimelineEventsTable> {
  $$InkTimelineEventsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get strokeId => $state.composableBuilder(
      column: $state.table.strokeId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pageId => $state.composableBuilder(
      column: $state.table.pageId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get timestampMs => $state.composableBuilder(
      column: $state.table.timestampMs,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get metadataJson => $state.composableBuilder(
      column: $state.table.metadataJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$InkTimelineEventsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $InkTimelineEventsTable> {
  $$InkTimelineEventsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get strokeId => $state.composableBuilder(
      column: $state.table.strokeId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pageId => $state.composableBuilder(
      column: $state.table.pageId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get timestampMs => $state.composableBuilder(
      column: $state.table.timestampMs,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get metadataJson => $state.composableBuilder(
      column: $state.table.metadataJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$BillsTableCreateCompanionBuilder = BillsCompanion Function({
  required String id,
  Value<String?> customerId,
  Value<String?> customerName,
  Value<double> subtotal,
  Value<double> taxRate,
  Value<double> taxAmount,
  Value<double> discount,
  Value<double> total,
  Value<String> status,
  required int createdAt,
  required int updatedAt,
  Value<String?> notes,
  Value<String?> inkPageId,
  Value<int> rowid,
});
typedef $$BillsTableUpdateCompanionBuilder = BillsCompanion Function({
  Value<String> id,
  Value<String?> customerId,
  Value<String?> customerName,
  Value<double> subtotal,
  Value<double> taxRate,
  Value<double> taxAmount,
  Value<double> discount,
  Value<double> total,
  Value<String> status,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String?> notes,
  Value<String?> inkPageId,
  Value<int> rowid,
});

class $$BillsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BillsTable,
    BillsData,
    $$BillsTableFilterComposer,
    $$BillsTableOrderingComposer,
    $$BillsTableCreateCompanionBuilder,
    $$BillsTableUpdateCompanionBuilder> {
  $$BillsTableTableManager(_$AppDatabase db, $BillsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BillsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BillsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> taxRate = const Value.absent(),
            Value<double> taxAmount = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> inkPageId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BillsCompanion(
            id: id,
            customerId: customerId,
            customerName: customerName,
            subtotal: subtotal,
            taxRate: taxRate,
            taxAmount: taxAmount,
            discount: discount,
            total: total,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            notes: notes,
            inkPageId: inkPageId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> customerId = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> taxRate = const Value.absent(),
            Value<double> taxAmount = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<String> status = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<String?> notes = const Value.absent(),
            Value<String?> inkPageId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BillsCompanion.insert(
            id: id,
            customerId: customerId,
            customerName: customerName,
            subtotal: subtotal,
            taxRate: taxRate,
            taxAmount: taxAmount,
            discount: discount,
            total: total,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            notes: notes,
            inkPageId: inkPageId,
            rowid: rowid,
          ),
        ));
}

class $$BillsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BillsTable> {
  $$BillsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerId => $state.composableBuilder(
      column: $state.table.customerId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerName => $state.composableBuilder(
      column: $state.table.customerName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get taxRate => $state.composableBuilder(
      column: $state.table.taxRate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get taxAmount => $state.composableBuilder(
      column: $state.table.taxAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get discount => $state.composableBuilder(
      column: $state.table.discount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get inkPageId => $state.composableBuilder(
      column: $state.table.inkPageId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$BillsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BillsTable> {
  $$BillsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerId => $state.composableBuilder(
      column: $state.table.customerId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerName => $state.composableBuilder(
      column: $state.table.customerName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get taxRate => $state.composableBuilder(
      column: $state.table.taxRate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get taxAmount => $state.composableBuilder(
      column: $state.table.taxAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get discount => $state.composableBuilder(
      column: $state.table.discount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get inkPageId => $state.composableBuilder(
      column: $state.table.inkPageId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$BillItemsTableCreateCompanionBuilder = BillItemsCompanion Function({
  required String id,
  required String billId,
  required String name,
  Value<double> quantity,
  Value<double> rate,
  Value<double> amount,
  Value<String?> unit,
  Value<double?> gstRate,
  Value<String?> hsnCode,
  Value<int> rowid,
});
typedef $$BillItemsTableUpdateCompanionBuilder = BillItemsCompanion Function({
  Value<String> id,
  Value<String> billId,
  Value<String> name,
  Value<double> quantity,
  Value<double> rate,
  Value<double> amount,
  Value<String?> unit,
  Value<double?> gstRate,
  Value<String?> hsnCode,
  Value<int> rowid,
});

class $$BillItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BillItemsTable,
    BillItemsData,
    $$BillItemsTableFilterComposer,
    $$BillItemsTableOrderingComposer,
    $$BillItemsTableCreateCompanionBuilder,
    $$BillItemsTableUpdateCompanionBuilder> {
  $$BillItemsTableTableManager(_$AppDatabase db, $BillItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BillItemsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BillItemsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> billId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> rate = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<double?> gstRate = const Value.absent(),
            Value<String?> hsnCode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BillItemsCompanion(
            id: id,
            billId: billId,
            name: name,
            quantity: quantity,
            rate: rate,
            amount: amount,
            unit: unit,
            gstRate: gstRate,
            hsnCode: hsnCode,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String billId,
            required String name,
            Value<double> quantity = const Value.absent(),
            Value<double> rate = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<double?> gstRate = const Value.absent(),
            Value<String?> hsnCode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BillItemsCompanion.insert(
            id: id,
            billId: billId,
            name: name,
            quantity: quantity,
            rate: rate,
            amount: amount,
            unit: unit,
            gstRate: gstRate,
            hsnCode: hsnCode,
            rowid: rowid,
          ),
        ));
}

class $$BillItemsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BillItemsTable> {
  $$BillItemsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get billId => $state.composableBuilder(
      column: $state.table.billId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get rate => $state.composableBuilder(
      column: $state.table.rate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get gstRate => $state.composableBuilder(
      column: $state.table.gstRate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get hsnCode => $state.composableBuilder(
      column: $state.table.hsnCode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$BillItemsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BillItemsTable> {
  $$BillItemsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get billId => $state.composableBuilder(
      column: $state.table.billId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get rate => $state.composableBuilder(
      column: $state.table.rate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get gstRate => $state.composableBuilder(
      column: $state.table.gstRate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get hsnCode => $state.composableBuilder(
      column: $state.table.hsnCode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  required String id,
  required String name,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> address,
  Value<String?> gstin,
  Value<double> balance,
  Value<double> totalPurchases,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> address,
  Value<String?> gstin,
  Value<double> balance,
  Value<double> totalPurchases,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$CustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomersTable,
    CustomersData,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder> {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CustomersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CustomersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> gstin = const Value.absent(),
            Value<double> balance = const Value.absent(),
            Value<double> totalPurchases = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            name: name,
            phone: phone,
            email: email,
            address: address,
            gstin: gstin,
            balance: balance,
            totalPurchases: totalPurchases,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> gstin = const Value.absent(),
            Value<double> balance = const Value.absent(),
            Value<double> totalPurchases = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            email: email,
            address: address,
            gstin: gstin,
            balance: balance,
            totalPurchases: totalPurchases,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$CustomersTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get address => $state.composableBuilder(
      column: $state.table.address,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get gstin => $state.composableBuilder(
      column: $state.table.gstin,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get balance => $state.composableBuilder(
      column: $state.table.balance,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get totalPurchases => $state.composableBuilder(
      column: $state.table.totalPurchases,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$CustomersTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get address => $state.composableBuilder(
      column: $state.table.address,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get gstin => $state.composableBuilder(
      column: $state.table.gstin,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get balance => $state.composableBuilder(
      column: $state.table.balance,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get totalPurchases => $state.composableBuilder(
      column: $state.table.totalPurchases,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  Value<double> price,
  Value<double?> gstRate,
  Value<String?> hsnCode,
  Value<String?> unit,
  Value<int> stock,
  Value<String?> barcode,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<double> price,
  Value<double?> gstRate,
  Value<String?> hsnCode,
  Value<String?> unit,
  Value<int> stock,
  Value<String?> barcode,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    ProductsData,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ProductsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ProductsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double?> gstRate = const Value.absent(),
            Value<String?> hsnCode = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<int> stock = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            name: name,
            description: description,
            price: price,
            gstRate: gstRate,
            hsnCode: hsnCode,
            unit: unit,
            stock: stock,
            barcode: barcode,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> description = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double?> gstRate = const Value.absent(),
            Value<String?> hsnCode = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<int> stock = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            name: name,
            description: description,
            price: price,
            gstRate: gstRate,
            hsnCode: hsnCode,
            unit: unit,
            stock: stock,
            barcode: barcode,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$ProductsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get gstRate => $state.composableBuilder(
      column: $state.table.gstRate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get hsnCode => $state.composableBuilder(
      column: $state.table.hsnCode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get stock => $state.composableBuilder(
      column: $state.table.stock,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get barcode => $state.composableBuilder(
      column: $state.table.barcode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ProductsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get gstRate => $state.composableBuilder(
      column: $state.table.gstRate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get hsnCode => $state.composableBuilder(
      column: $state.table.hsnCode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get stock => $state.composableBuilder(
      column: $state.table.stock,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get barcode => $state.composableBuilder(
      column: $state.table.barcode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$InkStrokesTableTableManager get inkStrokes =>
      $$InkStrokesTableTableManager(_db, _db.inkStrokes);
  $$InkPagesTableTableManager get inkPages =>
      $$InkPagesTableTableManager(_db, _db.inkPages);
  $$InkTimelineEventsTableTableManager get inkTimelineEvents =>
      $$InkTimelineEventsTableTableManager(_db, _db.inkTimelineEvents);
  $$BillsTableTableManager get bills =>
      $$BillsTableTableManager(_db, _db.bills);
  $$BillItemsTableTableManager get billItems =>
      $$BillItemsTableTableManager(_db, _db.billItems);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
}
