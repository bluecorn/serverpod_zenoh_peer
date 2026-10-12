import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_core/sensor_core.dart';
import 'package:sensor_node/config/providers.dart';
import 'package:sensor_node/ui/core/theme.dart';
import 'package:sensor_node/ui/node/node_screen.dart';
import 'package:sensor_node/ui/phone/phone_shell.dart';
import 'package:sensor_node/ui/recent/recent_panel.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The node keeps the phone's screen on, since Android takes an app's
  // network away soon after its screen goes off; the monitor needs no lock.
  if (buildRole == NodeRole.node) unawaited(WakelockPlus.enable());
  zenohLog('error').listen(debugPrint);

  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      child: MaterialApp(
        title: 'Sensor node',
        theme: themeOf(Brightness.light),
        darkTheme: themeOf(Brightness.dark),
        home: switch (buildRole) {
          NodeRole.node => const PhoneShell(),
          // The monitor: the phone's screen, and the archive's levels beside
          // it.
          NodeRole.monitor => const Scaffold(
            body: Row(
              children: [
                Expanded(child: NodeScreen()),
                VerticalDivider(width: 1),
                Expanded(child: RecentPanel()),
              ],
            ),
          ),
        },
      ),
    ),
  );
}
