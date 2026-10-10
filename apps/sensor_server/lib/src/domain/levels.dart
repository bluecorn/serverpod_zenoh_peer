import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/generated/protocol.dart';

/// A level for each key and each second of its readings' own times: the root
/// mean square of their magnitudes around their mean, labelled with the start
/// of the second.
Stream<SensorLevel> levelsPerSecond(Stream<KeyedReading> readings) =>
    const Stream.empty();
