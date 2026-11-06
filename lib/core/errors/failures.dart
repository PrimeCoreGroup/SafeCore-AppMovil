/// Errores controlados de la aplicación.
///
/// Las capas de datos traducen excepciones técnicas (Dio, SQLite, etc.) a
/// estos tipos para que la presentación muestre mensajes comprensibles sin
/// exponer detalles internos.
sealed class Failure implements Exception {
  const Failure(this.message);

  /// Mensaje apto para mostrar al usuario (español).
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Sin conectividad en el dispositivo móvil.
class OfflineFailure extends Failure {
  const OfflineFailure([
    super.message =
        'Sin conexión a Internet. Esta acción requiere conexión con la nube.',
  ]);
}

/// La nube no respondió o no es alcanzable.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No fue posible comunicarse con el servidor de SafeCore.',
  ]);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'El servidor tardó demasiado en responder.',
  ]);
}

/// Credenciales inválidas (401 en login).
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([
    super.message = 'Correo/celular o contraseña incorrectos.',
  ]);
}

/// Token ausente, inválido o expirado.
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([
    super.message = 'Tu sesión expiró. Inicia sesión nuevamente.',
  ]);
}

/// El usuario no tiene permisos para la operación (403 o validación local).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
    super.message =
        'No tienes permisos para realizar esta acción en este inmueble.',
  ]);
}

/// 429: límite de intentos de login (10/min por IP; bloqueo de 15 min tras
/// cinco fallos consecutivos).
class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure([
    super.message =
        'Demasiados intentos. Espera unos minutos antes de volver a intentarlo.',
  ]);
}

/// 503: el backend responde pero su base de datos no está disponible.
class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure([
    super.message =
        'El servidor de SafeCore no está disponible en este momento. Intenta más tarde.',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'El recurso solicitado no existe.']);
}

/// Datos rechazados por validación (local o 400/422 del backend).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
  final Map<String, String> fieldErrors;
}

class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'El servidor presentó un error. Intenta nuevamente.',
    this.statusCode,
  ]);
  final int? statusCode;
}

/// El endpoint aún no existe en el backend (contrato pendiente).
class NotImplementedFailure extends Failure {
  const NotImplementedFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'No hay información almacenada localmente para mostrar.',
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocurrió un error inesperado.']);
}

/// Convierte cualquier error en un [Failure] seguro para la UI.
Failure asFailure(Object error) =>
    error is Failure ? error : const UnknownFailure();

/// Errores de conectividad que permiten recurrir al último estado conocido.
bool isConnectivityFailure(Object error) =>
    error is OfflineFailure ||
    error is NetworkFailure ||
    error is TimeoutFailure ||
    error is ServiceUnavailableFailure;
