import 'dart:async';

/// Canal desacoplado para avisar que la sesión expiró (401 / JWT vencido)
/// desde la capa de red hacia el controlador de autenticación.
class SessionEvents {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _controller.stream;

  void notifySessionExpired() {
    if (!_controller.isClosed) _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}
