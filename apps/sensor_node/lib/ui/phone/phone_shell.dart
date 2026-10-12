import 'package:flutter/material.dart';
import 'package:sensor_node/ui/node/node_screen.dart';

/// The phone's app around its screens.
class PhoneShell extends StatelessWidget {
  /// The shell.
  const new({super.key});

  @override
  Widget build(BuildContext context) => const NodeScreen();
}
