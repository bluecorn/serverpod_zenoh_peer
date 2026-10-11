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
  // starts.
  initZenohLogging('error');
  serverContainer = ProviderContainer();
  await serverContainer.read(sessionProvider.future);

  // The web app, built into the server's web/app.
  pod.webServer.addRoute(
    FlutterRoute(Directory('${serverDirectory.path}web/app')),
  );

  await pod.start();

  // The recorder, once the server and its database have started: it keeps the
  // phone's levels in the archive through a session of its own, with logging
  // off; and the zenoh door, which answers from the archive through the same
  // session and publishes each level kept. Serverpod owns SIGINT and SIGTERM,
  // so the door and the recording stop, their session closes and zenoh closes
  // with the providers in a shutdown task.
  final archiveSession = await pod.createSession(enableLogging: false);
  final recording = serverContainer
      .read(recorderProvider)
      .start(archiveSession);
  final door = serverContainer.read(zenohDoorProvider).open(archiveSession);
  pod.experimental.shutdownTasks.addTask(#zenoh, () async {
    await door.cancel();
    await recording.cancel();
    await archiveSession.close();
    serverContainer.dispose();
  });
}
