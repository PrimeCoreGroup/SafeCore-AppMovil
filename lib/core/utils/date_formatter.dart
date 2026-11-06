/// Formateo de fechas en español sin dependencias externas.
///
/// Todas las fechas se muestran en hora local del dispositivo.
class DateFormatter {
  const DateFormatter._();

  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static const _fullMonths = [
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SETIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// 09 oct, 10:35
  static String shortDateTime(DateTime date) {
    final d = date.toLocal();
    return '${_two(d.day)} ${_months[d.month - 1]}, ${time(d)}';
  }

  /// 09/10/2026 · 10:30
  static String dateTime(DateTime date) => '${day(date)} · ${time(date)}';

  /// 09/10/2026
  static String day(DateTime date) {
    final d = date.toLocal();
    return '${_two(d.day)}/${_two(d.month)}/${d.year}';
  }

  /// 10:30
  static String time(DateTime date) {
    final d = date.toLocal();
    return '${_two(d.hour)}:${_two(d.minute)}';
  }

  /// Etiqueta de agrupación: "HOY · 09 OCTUBRE", "AYER · 08 OCTUBRE".
  static String dayHeader(DateTime date, {DateTime? now}) {
    final d = date.toLocal();
    final ref = (now ?? DateTime.now()).toLocal();
    final dDay = DateTime(d.year, d.month, d.day);
    final today = DateTime(ref.year, ref.month, ref.day);
    final diff = today.difference(dDay).inDays;
    final label = '${_two(d.day)} ${_fullMonths[d.month - 1]}';
    if (diff == 0) return 'HOY · $label';
    if (diff == 1) return 'AYER · $label';
    return '$label ${d.year}';
  }

  /// "hace 3 min", "hace 2 h", "hace 4 d".
  static String relative(DateTime date, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(date);
    if (diff.isNegative || diff.inSeconds < 45) return 'hace instantes';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  /// Parseo tolerante de ISO-8601 o epoch en ms; null si no es válido.
  static DateTime? tryParse(Object? value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
