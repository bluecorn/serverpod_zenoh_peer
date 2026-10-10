import 'dart:io';

import 'package:sensor_core/sensor_core.dart';

/// Reads a session's settings from a zenoh configuration file.
class SettingsFileService {
  /// The settings in the file at [path]. A relative path starts at the folder
  /// the server runs in, the workspace root.
  SessionSettings read(String path) =>
      SessionSettings(File(path).readAsStringSync());
}
