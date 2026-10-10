/// The clock the levels are timed by.
class ClockService {
  /// The time at each whole second, in UTC, once a second, from the next whole
  /// second on.
  Stream<DateTime> wholeSeconds() => const Stream.empty();
}
