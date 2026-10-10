import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_client/sensor_client.dart';

/// The levels the web door streams, as they arrive.
final levelsProvider = StreamProvider<SensorLevel>(
  (ref) => const Stream.empty(),
);
