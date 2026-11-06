import '../storage/local_cache.dart';

/// Registro local de operaciones relevantes realizadas desde la app.
///
/// Complementa (no reemplaza) la auditoría del backend. Nunca registra
/// contraseñas, tokens ni datos personales: solo el tipo de acción, el
/// recurso y el resultado.
class AuditLogger {
  AuditLogger(this._cache, {this.maxEntries = 200, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final LocalCache _cache;
  final int maxEntries;
  final DateTime Function() _clock;

  Future<void> log(
    String action, {
    String? propertyId,
    String? resourceId,
    String result = 'ok',
  }) async {
    try {
      final entry = await _cache.read(CacheKeys.auditLog);
      final current = entry?.value is List
          ? List<Object?>.from(entry!.value! as List)
          : <Object?>[];
      current.insert(0, {
        'at': _clock().toUtc().toIso8601String(),
        'action': action,
        if (propertyId != null) 'propertyId': propertyId,
        if (resourceId != null) 'resourceId': resourceId,
        'result': result,
      });
      if (current.length > maxEntries) {
        current.removeRange(maxEntries, current.length);
      }
      await _cache.write(CacheKeys.auditLog, current);
    } catch (_) {
      // La auditoría local nunca debe interrumpir una operación.
    }
  }

  Future<List<Map<String, Object?>>> entries() async {
    final entry = await _cache.read(CacheKeys.auditLog);
    final value = entry?.value;
    if (value is! List) return const [];
    return value
        .whereType<Map<Object?, Object?>>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }
}
