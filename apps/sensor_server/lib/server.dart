import 'dart:io';

import 'package:riverpod/riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_server/src/config/providers.dart';
import 'package:sensor_server/src/generated/serverpod.dart' as generated;
import 'package:serverpod/serverpod.dart';

/// Starts the server. It runs from the workspace root, where `zenoh_dart`
/// finds its native library, and finds its own folder from the script it
/// runs.
Future<void> run(List<String> args) async {
  final serverDirectory = Directory.fromUri(Platform.script.resolve('..'));
  final pod = generated.Serverpod(args, serverDirectory: serverDirectory);

  // The server's providers, and its zenoh session, open before the server
  // starts. Serverpod owns SIGINT and SIGTERM, so the session closes with
  // the providers in a shutdown task.
  initZenohLogging('error');
  serverContainer = ProviderContainer();
  await serverContainer.read(sessionProvider.future);
  pod.experimental.shutdownTasks.addTask(
    #zenoh,
    () async => serverContainer.dispose(),
  );

  // The web app, built into the server's web/app.
  pod.webServer.addRoute(
    FlutterRoute(Directory('${serverDirectory.path}web/app')),
  );

  await pod.start();
}
