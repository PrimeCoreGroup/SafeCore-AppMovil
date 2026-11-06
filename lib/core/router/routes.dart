/// Rutas de la aplicación.
class Routes {
  const Routes._();

  static const splash = '/splash';
  static const login = '/login';
  static const accessHelp = '/access-help';

  // Pestañas
  static const home = '/home';
  static const devices = '/devices';
  static const risks = '/risks';
  static const emergency = '/emergency';
  static const notifications = '/notifications';
  static const profile = '/profile';

  // Detalles y subpantallas
  static const detectionTest = '/devices/detection-test';
  static String device(String id) => '/devices/$id';
  static const riskHistory = '/risks/history';
  static String risk(String id) => '/risks/$id';
  static const protocols = '/emergency/protocols';
  static String response(String id) => '/emergency/$id';
  static const users = '/profile/users';
  static const configuration = '/profile/configuration';
  static const notificationSettings = '/profile/notification-settings';
}
