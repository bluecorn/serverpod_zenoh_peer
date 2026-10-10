import 'dart:io';

import 'package:sensor_core/sensor_core.dart';

/// The server's folder, from the workspace root, where the tests run.
final serverDirectory = Directory('apps/sensor_server');

/// The server's configuration file in the tests: it connects to the phone.
const serverConfigPath = 'apps/sensor_server/test/config/server.json5';

/// The phone's settings in the tests: it listens on the loopback.
SessionSettings phoneSettings() => SessionSettings(
  File('apps/sensor_server/test/config/phone.json5').readAsStringSync(),
);

/// Long enough for a sample, or a declaration, to cross the loopback, which
/// takes milliseconds.
const delivery = Duration(milliseconds: 500);
