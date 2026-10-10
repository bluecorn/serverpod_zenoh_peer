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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// The vibration level of one of the phone's sensors over one second, as the
/// web door sends it.
abstract class SensorLevel
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SensorLevel._({
    required this.time,
    required this.keyExpr,
    required this.level,
  });

  factory SensorLevel({
    required DateTime time,
    required String keyExpr,
    required double level,
  }) = _SensorLevelImpl;

  factory SensorLevel.fromJson(Map<String, dynamic> jsonSerialization) {
    return SensorLevel(
      time: _isc.DateTimeJsonExtension.fromJson(jsonSerialization['time']),
      keyExpr: jsonSerialization['keyExpr'] as String,
      level: (jsonSerialization['level'] as num).toDouble(),
    );
  }

  /// The end of the second, in UTC.
  DateTime time;

  /// The key expression the readings arrived on, such as `sensor/phone/accel`.
  String keyExpr;

  /// The root mean square of the readings' magnitudes around their mean.
  double level;

  /// Returns a shallow copy of this [SensorLevel]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SensorLevel copyWith({DateTime? time, String? keyExpr, double? level});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SensorLevel',
      'time': time.toJson(),
      'keyExpr': keyExpr,
      'level': level,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SensorLevel',
      'time': time.toJson(),
      'keyExpr': keyExpr,
      'level': level,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _SensorLevelImpl extends SensorLevel {
  _SensorLevelImpl({
    required DateTime time,
    required String keyExpr,
    required double level,
  }) : super._(time: time, keyExpr: keyExpr, level: level);

  /// Returns a shallow copy of this [SensorLevel]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SensorLevel copyWith({DateTime? time, String? keyExpr, double? level}) {
    return SensorLevel(
      time: time ?? this.time,
      keyExpr: keyExpr ?? this.keyExpr,
      level: level ?? this.level,
    );
  }
}
