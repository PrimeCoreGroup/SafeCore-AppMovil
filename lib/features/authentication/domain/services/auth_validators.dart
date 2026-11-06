/// Validaciones de formularios de acceso y de alta de usuarios.
class AuthValidators {
  const AuthValidators._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static bool isEmail(String v) => _email.hasMatch(v.trim());

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo electrónico.';
    return isEmail(v) ? null : 'El correo electrónico no es válido.';
  }

  static String? loginPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Ingresa tu contraseña.' : null;

  /// Política del backend para nuevas cuentas: 12–128 caracteres con
  /// mayúscula, minúscula, número y carácter no alfanumérico.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.length < 12) return 'Mínimo 12 caracteres.';
    if (v.length > 128) return 'Máximo 128 caracteres.';
    if (!RegExp('[A-Z]').hasMatch(v)) return 'Incluye al menos una mayúscula.';
    if (!RegExp('[a-z]').hasMatch(v)) return 'Incluye al menos una minúscula.';
    if (!RegExp(r'\d').hasMatch(v)) return 'Incluye al menos un número.';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
      return 'Incluye al menos un símbolo (por ejemplo - ! # @).';
    }
    return null;
  }

  static String? personName(String? value, {String field = 'nombre'}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa el $field.';
    if (v.length > 100) return 'Máximo 100 caracteres.';
    return null;
  }

  static String normalizeEmail(String v) => v.trim().toLowerCase();
}
