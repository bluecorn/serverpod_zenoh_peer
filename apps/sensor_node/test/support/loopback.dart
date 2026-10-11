import 'dart:io';

import 'package:sensor_core/sensor_core.dart';

/// The settings of the phone's and the archive's session in the tests: it
/// listens on the loopback and stamps what it puts.
SessionSettings archiveSettings() => _read('archive');

/// The monitor's settings in the tests: it connects to the archive's session.
SessionSettings monitorSettings() => _read('monitor');

/// The file called [name] under the app's test configuration. The path is
/// from the workspace root, where the tests run.
SessionSettings _read(String name) => SessionSettings(
  File('apps/sensor_node/test/config/$name.json5').readAsStringSync(),
);

/// Long enough for a sample, or a declaration, to cross the loopback, which
/// takes milliseconds.
const delivery = Duration(milliseconds: 500);
