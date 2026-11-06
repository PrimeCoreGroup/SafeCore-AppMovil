/// Persistencia del token de sesión.
///
/// En producción se usa Flutter Secure Storage (Keychain / Keystore). Nunca
/// se guardan contraseñas: solo el JWT y metadatos no sensibles.
abstract interface class TokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<String?> readUserJson();
  Future<void> writeUserJson(String json);
  Future<void> clear();
}

/// Implementación en memoria para pruebas.
class InMemoryTokenStorage implements TokenStorage {
  String? _token;
  String? _user;

  @override
  Future<void> clear() async {
    _token = null;
    _user = null;
  }

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<String?> readUserJson() async => _user;

  @override
  Future<void> writeToken(String token) async => _token = token;

  @override
  Future<void> writeUserJson(String json) async => _user = json;
}
