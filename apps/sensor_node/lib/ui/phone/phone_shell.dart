import 'package:flutter/material.dart';
import 'package:sensor_node/ui/node/node_screen.dart';
import 'package:sensor_node/ui/recent/recent_panel.dart';

/// The phone's app around its screens: a title bar, "Sensor node", and two
/// tabs in a navigation bar at the bottom, Live and History. Only the open
/// tab is built, so History asks the archive when it is first opened.
class PhoneShell extends StatefulWidget {
  /// The shell, Live open.
  const new({super.key});

  @override
  State<PhoneShell> createState() => _PhoneShellState();
}

class _PhoneShellState extends State<PhoneShell> {
  /// The open tab: 0 for Live, 1 for History.
  var _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sensor node')),
    body: switch (_tab) {
      0 => const NodeScreen(),
      _ => const RecentPanel(),
    },
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (tab) => setState(() => _tab = tab),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.sensors), label: 'Live'),
        NavigationDestination(icon: Icon(Icons.history), label: 'History'),
      ],
    ),
  );
}
