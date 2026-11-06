/// Rutas del backend SafeCore (ASP.NET Core). Contratos tomados del README
/// del backend; las rutas no distinguen mayúsculas.
class ApiEndpoints {
  const ApiEndpoints._();

  // IAM
  static const login = '/api/iam/auth/login';
  static const me = '/api/iam/auth/me';

  // Administración de usuarios (Administrator)
  static const users = '/api/users';
  static String user(String id) => '/api/users/$id';

  // Dispositivos
  static const devices = '/api/devices';
  static String device(String id) => '/api/devices/$id';
  static String rotateSecret(String id) => '/api/devices/$id/rotate-secret';

  // Telemetría
  static const sensorReadings = '/api/SensorReadings';
  static String sensorReading(String id) => '/api/SensorReadings/$id';

  // Riesgos
  static const riskSituations = '/api/RiskSituations';
  static String riskSituation(String id) => '/api/RiskSituations/$id';

  // Emergencias
  static const protocols = '/api/emergency/protocols';
  static String protocol(String id) => '/api/emergency/protocols/$id';
  static const responses = '/api/EmergencyResponses';
  static String response(String id) => '/api/EmergencyResponses/$id';
  static const actions = '/api/emergency/actions';
  static String action(String id) => '/api/emergency/actions/$id';

  // Notificaciones
  static const notifications = '/api/Notifications';
  static const myNotifications = '/api/Notifications/mine';
  static String notification(String id) => '/api/Notifications/$id';

  // Configuración de monitoreo
  static const configurations = '/api/SystemConfigurations';
  static String configuration(String id) => '/api/SystemConfigurations/$id';

  // Salud (públicos)
  static const healthLive = '/health/live';
  static const healthReady = '/health/ready';
}
