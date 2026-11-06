import 'dart:convert';

/// Entrada almacenada localmente con su fecha de guardado.
class CacheEntry {
  const CacheEntry({required this.value, required this.savedAt});

  /// Valor JSON decodificado (Map o List).
  final Object? value;
  final DateTime savedAt;
}

/// Almacenamiento local del último estado conocido (modo offline).
///
/// Solo guarda información operativa (inmuebles, sensores, alertas, eventos,
/// preferencias). NUNCA tokens ni contraseñas: esos van en almacenamiento
/// seguro. Se limpia completamente al cerrar sesión.
abstract interface class LocalCache {
  Future<CacheEntry?> read(String key);
  Future<void> write(String key, Object? jsonValue);
  Future<void> remove(String key);
  Future<void> clear();
}

/// Implementación en memoria (pruebas y respaldo si SQLite falla).
class InMemoryLocalCache implements LocalCache {
  InMemoryLocalCache({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, (String, DateTime)> _store = {};

  @override
  Future<CacheEntry?> read(String key) async {
    final raw = _store[key];
    if (raw == null) return null;
    return CacheEntry(value: jsonDecode(raw.$1), savedAt: raw.$2);
  }

  @override
  Future<void> write(String key, Object? jsonValue) async {
    // Se serializa para garantizar que lo almacenado es JSON válido,
    // igual que en la implementación SQLite.
    _store[key] = (jsonEncode(jsonValue), _clock());
  }

  @override
  Future<void> remove(String key) async => _store.remove(key);

  @override
  Future<void> clear() async => _store.clear();
}

/// Claves de caché. Se borran todas al cerrar sesión (salvo el tema).
class CacheKeys {
  const CacheKeys._();
  static const devices = 'devices';
  static const readings = 'readings';
  static const risks = 'risks';
  static const protocols = 'protocols';
  static const responses = 'responses';
  static const actions = 'actions';
  static const notifications = 'notifications';
  static const myNotifications = 'notifications_mine';
  static const users = 'users';
  static const configurations = 'configurations';
  static const notificationPrefs = 'notification_prefs';
  static const readNotifications = 'notifications_read';
  static const themeMode = 'theme_mode';
  static const auditLog = 'audit_log';
  static const lastEmail = 'last_email';
}
