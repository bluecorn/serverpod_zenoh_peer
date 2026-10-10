import 'dart:async';

/// The clock the levels are timed by.
class ClockService {
  /// The time at each whole second, in UTC, once a second, from the next whole
  /// second on. Each tick is scheduled from the one before, so a timer that
  /// fires early never repeats a second.
  Stream<DateTime> wholeSeconds() {
    Timer? timer;
    final controller = StreamController<DateTime>();
    void tickAt(DateTime second) {
      timer = Timer(second.difference(DateTime.now()), () {
        controller.add(second);
        tickAt(second.add(const Duration(seconds: 1)));
      });
    }

    controller
      ..onListen = () {
        final now = DateTime.now().millisecondsSinceEpoch;
        tickAt(
          DateTime.fromMillisecondsSinceEpoch(
            (now ~/ 1000 + 1) * 1000,
            isUtc: true,
          ),
        );
      }
      ..onCancel = () => timer?.cancel();
    return controller.stream;
  }
}
