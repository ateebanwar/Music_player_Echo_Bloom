/// Contract for retrieving current system time.
/// Allows deterministic time mocking in unit and integration tests.
abstract class Clock {
  DateTime now();
  int nowMillisecondsSinceEpoch();
}

/// Production system clock using [DateTime.now].
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  int nowMillisecondsSinceEpoch() => DateTime.now().millisecondsSinceEpoch;
}

/// Deterministic mock clock for testing time-dependent logic.
class FixedClock implements Clock {
  DateTime _current;

  FixedClock([DateTime? initial]) : _current = initial ?? DateTime(2026, 1, 1);

  @override
  DateTime now() => _current;

  @override
  int nowMillisecondsSinceEpoch() => _current.millisecondsSinceEpoch;

  void advance(Duration duration) {
    _current = _current.add(duration);
  }

  void set(DateTime dateTime) {
    _current = dateTime;
  }
}
