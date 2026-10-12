import 'package:sensor_client/sensor_client.dart';
import 'package:sensor_domain/sensor_domain.dart';

/// A reading from the web door, with the sensor its key names.
typedef SensedReading = ({Sensor sensor, SensorReading reading});

/// A level from the web door, with the sensor its key names.
typedef SensedLevel = ({Sensor sensor, SensorLevel level});
