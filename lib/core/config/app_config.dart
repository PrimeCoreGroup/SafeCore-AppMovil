/// Configuración de compilación de SafeCore.
///
/// Los valores se leen de `--dart-define` / `--dart-define-from-file=.env`.
/// No se deben colocar secretos aquí: todo lo que entra por dart-define
/// queda embebido en el binario.
/// URL pública del backend SafeCore (ASP.NET Core en Render).
const kDefaultApiBaseUrl = 'https://backend-safecore.onrender.com';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.demoMode,
    required this.firebaseEnabled,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.pollInterval,
    required this.staleAfter,
    required this.edgeConfirmationTimeout,
    required this.allowInsecureHttp,
  });

  factory AppConfig.fromEnvironment() {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    // Backend de producción en Render. Se puede sobrescribir con dart-define.
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: kDefaultApiBaseUrl,
    );
    // El modo demostración también puede activarse en tiempo de ejecución
    // desde la pantalla de inicio de sesión.
    const demo = bool.fromEnvironment('DEMO_MODE', defaultValue: baseUrl == '');
    return const AppConfig(
      environment: env,
      apiBaseUrl: baseUrl,
      demoMode: demo,
      firebaseEnabled: bool.fromEnvironment('FIREBASE_ENABLED'),
      connectTimeout: Duration(
        milliseconds:
            int.fromEnvironment('CONNECT_TIMEOUT_MS', defaultValue: 15000),
      ),
      receiveTimeout: Duration(
        milliseconds:
            int.fromEnvironment('RECEIVE_TIMEOUT_MS', defaultValue: 20000),
      ),
      pollInterval: Duration(
        seconds: int.fromEnvironment('POLL_INTERVAL_SECONDS', defaultValue: 30),
      ),
      staleAfter: Duration(
        seconds: int.fromEnvironment('STALE_AFTER_SECONDS', defaultValue: 300),
      ),
      edgeConfirmationTimeout: Duration(
        seconds: int.fromEnvironment(
          'EDGE_CONFIRMATION_TIMEOUT_SECONDS',
          defaultValue: 60,
        ),
      ),
      allowInsecureHttp: bool.fromEnvironment('ALLOW_INSECURE_HTTP'),
    );
  }

  final String environment;
  final String apiBaseUrl;
  final bool demoMode;
  final bool firebaseEnabled;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration pollInterval;
  final Duration staleAfter;
  final Duration edgeConfirmationTimeout;
  final bool allowInsecureHttp;

  bool get isProduction => environment == 'production';

  /// Valida la configuración. Devuelve la lista de problemas encontrados.
  ///
  /// Regla de seguridad: fuera de modo demo la URL debe ser HTTPS, salvo que
  /// se habilite explícitamente HTTP en un entorno que no sea producción.
  List<String> validate() {
    final problems = <String>[];
    if (demoMode) return problems;
    if (apiBaseUrl.isEmpty) {
      problems.add('API_BASE_URL no está configurada.');
      return problems;
    }
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      problems.add('API_BASE_URL no es una URL válida.');
      return problems;
    }
    final insecureAllowed = allowInsecureHttp && !isProduction;
    if (uri.scheme != 'https' && !insecureAllowed) {
      problems.add('API_BASE_URL debe usar HTTPS.');
    }
    return problems;
  }

  AppConfig copyWith({
    String? environment,
    String? apiBaseUrl,
    bool? demoMode,
    bool? firebaseEnabled,
    Duration? pollInterval,
    Duration? staleAfter,
    Duration? edgeConfirmationTimeout,
    bool? allowInsecureHttp,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      demoMode: demoMode ?? this.demoMode,
      firebaseEnabled: firebaseEnabled ?? this.firebaseEnabled,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      pollInterval: pollInterval ?? this.pollInterval,
      staleAfter: staleAfter ?? this.staleAfter,
      edgeConfirmationTimeout:
          edgeConfirmationTimeout ?? this.edgeConfirmationTimeout,
      allowInsecureHttp: allowInsecureHttp ?? this.allowInsecureHttp,
    );
  }
}
