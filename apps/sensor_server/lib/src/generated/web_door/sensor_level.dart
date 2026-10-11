/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;

/// The vibration level of one of the phone's sensors over one second, as the
/// web door sends it.
abstract class SensorLevel
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  SensorLevel._({
    this.id,
    required this.time,
    required this.keyExpr,
    required this.level,
  });

  factory SensorLevel({
    int? id,
    required DateTime time,
    required String keyExpr,
    required double level,
  }) = _SensorLevelImpl;

  factory SensorLevel.fromJson(Map<String, dynamic> jsonSerialization) {
    return SensorLevel(
      id: jsonSerialization['id'] as int?,
      time: _is.DateTimeJsonExtension.fromJson(jsonSerialization['time']),
      keyExpr: jsonSerialization['keyExpr'] as String,
      level: (jsonSerialization['level'] as num).toDouble(),
    );
  }

  static final t = SensorLevelTable();

  static const db = SensorLevelRepository._();

  @override
  int? id;

  /// The start of the second, in UTC, by the clock of the session that stamped
  /// the readings.
  DateTime time;

  /// The key expression the readings arrived on, such as `sensor/phone/accel`.
  String keyExpr;

  /// The root mean square of the readings' magnitudes around their mean.
  double level;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [SensorLevel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SensorLevel copyWith({
    int? id,
    DateTime? time,
    String? keyExpr,
    double? level,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SensorLevel',
      if (id != null) 'id': id,
      'time': time.toJson(),
      'keyExpr': keyExpr,
      'level': level,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SensorLevel',
      if (id != null) 'id': id,
      'time': time.toJson(),
      'keyExpr': keyExpr,
      'level': level,
    };
  }

  static SensorLevelInclude include() {
    return SensorLevelInclude._();
  }

  static SensorLevelIncludeList includeList({
    _is.WhereExpressionBuilder<SensorLevelTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SensorLevelTable>? orderBy,
    _is.OrderByListBuilder<SensorLevelTable>? orderByList,
    SensorLevelInclude? include,
  }) {
    return SensorLevelIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SensorLevel.t),
      orderByList: orderByList?.call(SensorLevel.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SensorLevelImpl extends SensorLevel {
  _SensorLevelImpl({
    int? id,
    required DateTime time,
    required String keyExpr,
    required double level,
  }) : super._(id: id, time: time, keyExpr: keyExpr, level: level);

  /// Returns a shallow copy of this [SensorLevel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SensorLevel copyWith({
    Object? id = _Undefined,
    DateTime? time,
    String? keyExpr,
    double? level,
  }) {
    return SensorLevel(
      id: id is int? ? id : this.id,
      time: time ?? this.time,
      keyExpr: keyExpr ?? this.keyExpr,
      level: level ?? this.level,
    );
  }
}

class SensorLevelUpdateTable extends _is.UpdateTable<SensorLevelTable> {
  SensorLevelUpdateTable(super.table);

  _is.ColumnValue<DateTime, DateTime> time(DateTime value) =>
      _is.ColumnValue(table.time, value);

  _is.ColumnValue<String, String> keyExpr(String value) =>
      _is.ColumnValue(table.keyExpr, value);

  _is.ColumnValue<double, double> level(double value) =>
      _is.ColumnValue(table.level, value);
}

class SensorLevelTable extends _is.Table<int?> {
  SensorLevelTable({super.tableRelation}) : super(tableName: 'sensor_level') {
    updateTable = SensorLevelUpdateTable(this);
    time = _is.ColumnDateTime('time', this);
    keyExpr = _is.ColumnString('keyExpr', this);
    level = _is.ColumnDouble('level', this);
  }

  late final SensorLevelUpdateTable updateTable;

  /// The start of the second, in UTC, by the clock of the session that stamped
  /// the readings.
  late final _is.ColumnDateTime time;

  /// The key expression the readings arrived on, such as `sensor/phone/accel`.
  late final _is.ColumnString keyExpr;

  /// The root mean square of the readings' magnitudes around their mean.
  late final _is.ColumnDouble level;

  @override
  List<_is.Column> get columns => [id, time, keyExpr, level];
}

class SensorLevelInclude extends _is.IncludeObject {
  SensorLevelInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => SensorLevel.t;
}

class SensorLevelIncludeList extends _is.IncludeList {
  SensorLevelIncludeList._({
    _is.WhereExpressionBuilder<SensorLevelTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SensorLevel.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => SensorLevel.t;
}

class SensorLevelRepository {
  const SensorLevelRepository._();

  /// Returns a list of [SensorLevel]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<SensorLevel>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SensorLevelTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SensorLevelTable>? orderBy,
    _is.OrderByListBuilder<SensorLevelTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SensorLevel>(
      where: where?.call(SensorLevel.t),
      orderBy: orderBy?.call(SensorLevel.t),
      orderByList: orderByList?.call(SensorLevel.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SensorLevel] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<SensorLevel?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SensorLevelTable>? where,
    int? offset,
    _is.OrderByBuilder<SensorLevelTable>? orderBy,
    _is.OrderByListBuilder<SensorLevelTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SensorLevel>(
      where: where?.call(SensorLevel.t),
      orderBy: orderBy?.call(SensorLevel.t),
      orderByList: orderByList?.call(SensorLevel.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SensorLevel] by its [id] or null if no such row exists.
  Future<SensorLevel?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SensorLevel>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SensorLevel]s in the list and returns the inserted rows.
  ///
  /// The returned [SensorLevel]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SensorLevel>> insert(
    _is.DatabaseSession session,
    List<SensorLevel> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SensorLevel>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SensorLevel] and returns the inserted row.
  ///
  /// The returned [SensorLevel] will have its `id` field set.
  Future<SensorLevel> insertRow(
    _is.DatabaseSession session,
    SensorLevel row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SensorLevel>(row, transaction: transaction);
  }

  /// Upserts all [SensorLevel]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [SensorLevel]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SensorLevel>> upsert(
    _is.DatabaseSession session,
    List<SensorLevel> rows, {
    required _is.ColumnSelections<SensorLevelTable> conflictColumns,
    _is.ColumnSelections<SensorLevelTable>? updateColumns,
    _is.WhereExpressionBuilder<SensorLevelTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SensorLevel>(
      rows,
      conflictColumns: conflictColumns(SensorLevel.t),
      updateColumns: updateColumns?.call(SensorLevel.t),
      updateWhere: updateWhere?.call(SensorLevel.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SensorLevel] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [SensorLevel] will have its `id` field set.
  Future<SensorLevel?> upsertRow(
    _is.DatabaseSession session,
    SensorLevel row, {
    required _is.ColumnSelections<SensorLevelTable> conflictColumns,
    _is.ColumnSelections<SensorLevelTable>? updateColumns,
    _is.WhereExpressionBuilder<SensorLevelTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SensorLevel>(
      row,
      conflictColumns: conflictColumns(SensorLevel.t),
      updateColumns: updateColumns?.call(SensorLevel.t),
      updateWhere: updateWhere?.call(SensorLevel.t),
      transaction: transaction,
    );
  }

  /// Updates all [SensorLevel]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SensorLevel>> update(
    _is.DatabaseSession session,
    List<SensorLevel> rows, {
    _is.ColumnSelections<SensorLevelTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SensorLevel>(
      rows,
      columns: columns?.call(SensorLevel.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SensorLevel]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SensorLevel> updateRow(
    _is.DatabaseSession session,
    SensorLevel row, {
    _is.ColumnSelections<SensorLevelTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SensorLevel>(
      row,
      columns: columns?.call(SensorLevel.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SensorLevel] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SensorLevel?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SensorLevelUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SensorLevel>(
      id,
      columnValues: columnValues(SensorLevel.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SensorLevel]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SensorLevel>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SensorLevelUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SensorLevelTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SensorLevelTable>? orderBy,
    _is.OrderByListBuilder<SensorLevelTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SensorLevel>(
      columnValues: columnValues(SensorLevel.t.updateTable),
      where: where(SensorLevel.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SensorLevel.t),
      orderByList: orderByList?.call(SensorLevel.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SensorLevel]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SensorLevel>> delete(
    _is.DatabaseSession session,
    List<SensorLevel> rows, {
    _is.OrderByBuilder<SensorLevelTable>? orderBy,
    _is.OrderByListBuilder<SensorLevelTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SensorLevel>(
      rows,
      orderBy: orderBy?.call(SensorLevel.t),
      orderByList: orderByList?.call(SensorLevel.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SensorLevel].
  Future<SensorLevel> deleteRow(
    _is.DatabaseSession session,
    SensorLevel row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SensorLevel>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SensorLevel>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SensorLevelTable> where,
    _is.OrderByBuilder<SensorLevelTable>? orderBy,
    _is.OrderByListBuilder<SensorLevelTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SensorLevel>(
      where: where(SensorLevel.t),
      orderBy: orderBy?.call(SensorLevel.t),
      orderByList: orderByList?.call(SensorLevel.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SensorLevelTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SensorLevel>(
      where: where?.call(SensorLevel.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SensorLevel] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SensorLevelTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SensorLevel>(
      where: where(SensorLevel.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
