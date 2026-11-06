/// Reloj controlable para pruebas deterministas.
class TestClock {
  TestClock([DateTime? start]) : now = start ?? DateTime(2026, 10, 9, 10, 30);

  DateTime now;

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}
