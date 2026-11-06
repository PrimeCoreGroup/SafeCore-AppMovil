import 'dart:convert';

/// Lectura (no verificación) de los claims de un JWT.
///
/// La firma la valida exclusivamente el backend. En el móvil solo se lee
/// `exp` para anticipar la expiración de sesión y evitar peticiones inútiles.
class JwtClaims {
  const JwtClaims({this.subject, this.expiresAt, this.raw = const {}});

  final String? subject;
  final DateTime? expiresAt;
  final Map<String, dynamic> raw;

  /// Se considera expirado con un margen de seguridad para evitar que el
  /// token caduque en medio de una petición.
  bool isExpired(
      {DateTime? now, Duration leeway = const Duration(seconds: 30)}) {
    final exp = expiresAt;
    if (exp == null) return false;
    return !(now ?? DateTime.now()).toUtc().add(leeway).isBefore(exp.toUtc());
  }
}

class JwtDecoder {
  const JwtDecoder._();

  /// Devuelve null si el token no tiene formato JWT válido.
  static JwtClaims? tryDecode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final map = decoded.map((k, v) => MapEntry(k.toString(), v));
      final exp = map['exp'];
      return JwtClaims(
        subject: map['sub']?.toString(),
        expiresAt: exp is num
            ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000,
                isUtc: true)
            : null,
        raw: map,
      );
    } on FormatException {
      return null;
    }
  }

  /// Crea un token sin firma, SOLO para el modo demostración.
  /// Nunca se envía a un backend real.
  static String buildUnsignedDemoToken({
    required String subject,
    required DateTime expiresAt,
  }) {
    String enc(Map<String, Object> m) =>
        base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    final header = enc({'alg': 'none', 'typ': 'JWT'});
    final payload = enc({
      'sub': subject,
      'exp': expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000,
      'demo': true,
    });
    return '$header.$payload.demo';
  }
}
