import 'dart:io';

import 'package:sensor_server/src/generated/serverpod.dart';

/// Starts the server. It runs from the workspace root, where `zenoh_dart`
/// finds its native library, and finds its own folder from the script it
/// runs.
Future<void> run(List<String> args) async {
  final serverDirectory = Directory.fromUri(Platform.script.resolve('..'));
  final pod = Serverpod(args, serverDirectory: serverDirectory);
  await pod.start();
}
