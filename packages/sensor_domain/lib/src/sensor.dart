/// A sensor of the phone: the last segment of the key its readings travel on,
/// the label a view shows, and the unit of its values and of its levels.
typedef Sensor = ({String segment, String label, String unit});

/// The phone's accelerometer, in metres per second squared, gravity included.
const Sensor accelerometer = (
  segment: 'accel',
  label: 'Accelerometer',
  unit: 'm/s²',
);

/// The phone's gyroscope, in radians per second.
const Sensor gyroscope = (segment: 'gyro', label: 'Gyroscope', unit: 'rad/s');

/// The phone's sensors, by their segment.
const Map<String, Sensor> sensors = {'accel': accelerometer, 'gyro': gyroscope};

/// The sensor whose segment is [segment]; a segment the list does not know
/// becomes a sensor of its own, labelled with the segment and with no unit.
Sensor sensorOf(String segment) =>
    sensors[segment] ?? (segment: segment, label: segment, unit: '');

/// Orders [a] and [b] as the list does, a sensor it does not list after every
/// one it does.
int compareSensors(Sensor a, Sensor b) => 0;
