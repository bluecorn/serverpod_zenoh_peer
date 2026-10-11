/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:sensor_client/src/protocol/web_door/sensor_level.dart'
    as _i63isrvn;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'web_door/sensor_level.dart' as _i4cxm9sa;
import 'web_door/sensor_reading.dart' as _ixh9crma;
export 'web_door/sensor_level.dart';
export 'web_door/sensor_reading.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(dynamic data, [Type? t]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i4cxm9sa.SensorLevel) {
      return _i4cxm9sa.SensorLevel.fromJson(data) as T;
    }
    if (t == _ixh9crma.SensorReading) {
      return _ixh9crma.SensorReading.fromJson(data) as T;
    }
    if (t == _isc.getType<_i4cxm9sa.SensorLevel?>()) {
      return (data != null ? _i4cxm9sa.SensorLevel.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ixh9crma.SensorReading?>()) {
      return (data != null ? _ixh9crma.SensorReading.fromJson(data) : null)
          as T;
    }
    if (t == List<_i63isrvn.SensorLevel>) {
      return (data as List)
              .map((e) => deserialize<_i63isrvn.SensorLevel>(e))
              .toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i4cxm9sa.SensorLevel => 'SensorLevel',
      _ixh9crma.SensorReading => 'SensorReading',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('sensor.', '');
    }

    switch (data) {
      case _i4cxm9sa.SensorLevel():
        return 'SensorLevel';
      case _ixh9crma.SensorReading():
        return 'SensorReading';
    }
    if (data is List<_i63isrvn.SensorLevel>) {
      return 'List<SensorLevel>';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'SensorLevel') {
      return deserialize<_i4cxm9sa.SensorLevel>(data['data']);
    }
    if (dataClassName == 'SensorReading') {
      return deserialize<_ixh9crma.SensorReading>(data['data']);
    }
    if (dataClassName == 'List<SensorLevel>') {
      return deserialize<List<_i63isrvn.SensorLevel>>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  @override
  String getModuleName() => 'sensor';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
