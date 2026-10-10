import 'package:sensor_server/src/data/services/clock_service.dart';
import 'package:test/test.dart';

void main() {
  test('the clock ticks on whole seconds, in UTC, one a second', () async {
    // The code to implement: the clock's next two ticks, on the real clock,
    // which takes up to two seconds.
    final ticks = await ClockService().wholeSeconds().take(2).toList();

    // The claim: two whole seconds in UTC, one second apart.
    final shapes = ticks
        .map((tick) => (tick.isUtc, tick.millisecond, tick.microsecond))
        .toList();
    expect(shapes, [(true, 0, 0), (true, 0, 0)]);
    expect(ticks.last.difference(ticks.first), const Duration(seconds: 1));
  });
}
