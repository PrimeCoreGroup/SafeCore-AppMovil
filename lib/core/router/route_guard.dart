import '../security/roles.dart';
import 'routes.dart';

enum SessionPhase { checking, authenticated, unauthenticated }

/// Lógica pura de redirección (testeable sin Flutter).
///
/// Las guardas solo evitan mostrar pantallas no autorizadas; el backend
/// valida igualmente cada operación (403).
class RouteGuard {
  const RouteGuard._();

  static const publicRoutes = {Routes.login, Routes.accessHelp};

  /// Permisos que habilitan una ruta (basta con uno).
  static Set<Permission>? requiredFor(String location) {
    bool under(String prefix) =>
        location == prefix || location.startsWith('$prefix/');
    if (under(Routes.detectionTest)) return const {Permission.postReadings};
    if (under(Routes.users)) return const {Permission.manageUsers};
    if (under(Routes.configuration)) {
      return const {Permission.viewConfiguration};
    }
    if (under(Routes.devices) ||
        under(Routes.risks) ||
        under(Routes.emergency)) {
      return const {Permission.viewOperations};
    }
    if (under(Routes.notifications)) {
      return const {
        Permission.viewAllNotifications,
        Permission.viewOwnNotifications,
      };
    }
    return null;
  }

  static String? redirect({
    required SessionPhase session,
    required Set<Permission> permissions,
    required String location,
  }) {
    switch (session) {
      case SessionPhase.checking:
        return location == Routes.splash ? null : Routes.splash;
      case SessionPhase.unauthenticated:
        return publicRoutes.contains(location) ? null : Routes.login;
      case SessionPhase.authenticated:
        break;
    }
    if (location == Routes.splash || publicRoutes.contains(location)) {
      return Routes.home;
    }
    final required = requiredFor(location);
    if (required != null && !required.any(permissions.contains)) {
      return Routes.home;
    }
    return null;
  }
}
