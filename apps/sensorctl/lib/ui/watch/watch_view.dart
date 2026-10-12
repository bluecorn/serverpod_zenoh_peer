import 'dart:io';
import 'dart:math';

import 'package:dart_console/dart_console.dart';
import 'package:sensorctl/ui/watch/watch_view_model.dart';

/// The lines `watch` shows for [state]: one for each key, with the key, its
/// latest reading to three decimals, the node's number for it and how many
/// readings arrived here, or one that says so before the first reading.
List<String> watchLines(WatchState state) {
  if (state.sensors.isEmpty) return const ['no readings yet'];
  final width = state.sensors.keys.map((key) => key.length).reduce(max);
  return [
    for (final MapEntry(key: keyExpr, value: sensor) in state.sensors.entries)
      _line(keyExpr.padRight(width), sensor),
  ];
}

/// The line for one key: [key], its latest reading, the node's number for
/// it, and how many arrived here.
String _line(String key, SensorState sensor) =>
    '$key  x ${_fixed(sensor.latest.x)}  y ${_fixed(sensor.latest.y)}  '
    'z ${_fixed(sensor.latest.z)}  ${sensor.latest.number} readings · '
    '${sensor.count} received here';

/// [value] to three decimals, seven characters wide, so that the columns stay
/// in place when a value turns negative.
String _fixed(double value) => value.toStringAsFixed(3).padLeft(7);

/// The terminal as the view: the lines for each state, redrawn in place on a
/// terminal, and printed once for each state when the output is not one.
class WatchView {
  /// A view on [console].
  new(this.console);

  /// The terminal it draws on.
  final Console console;

  /// How many lines the last state took on the terminal.
  int _shown = 0;

  /// Says how to stop, and hides the cursor on a terminal.
  void open() {
    stdout.writeln('Press Ctrl-C to stop.');
    if (console.hasTerminal) console.hideCursor();
  }

  /// Shows [state]: on a terminal, each line over the one it replaces.
  void show(WatchState state) {
    final lines = watchLines(state);
    if (console.hasTerminal) {
      for (var i = 0; i < _shown; i++) {
        console.cursorUp();
      }
      for (final line in lines) {
        console.eraseLine();
        stdout.writeln(line);
      }
      _shown = lines.length;
    } else {
      lines.forEach(stdout.writeln);
    }
  }

  /// Leaves the terminal ready for the next command, with the cursor shown.
  void close() {
    if (console.hasTerminal) console.showCursor();
  }
}
