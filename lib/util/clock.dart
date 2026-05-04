/// Indirection over `DateTime.now()` so tests can freeze and advance time.
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
