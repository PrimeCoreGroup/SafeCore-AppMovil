// @pure-dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safecore_mobile/core/config/app_config.dart';
import 'package:safecore_mobile/core/errors/failures.dart';
import 'package:safecore_mobile/core/network/api_client.dart';
import 'package:safecore_mobile/core/network/api_endpoints.dart';
import 'package:safecore_mobile/core/network/dio_factory.dart';
import 'package:safecore_mobile/core/network/pagination.dart';
import 'package:safecore_mobile/core/security/jwt_decoder.dart';
import 'package:safecore_mobile/core/security/token_storage.dart';
import 'package:safecore_mobile/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:safecore_mobile/features/dashboard/data/datasources/health_data_source.dart';

import '../helpers/fake_http.dart';

void main() {
  late InMemoryTokenStorage tokens;
  late FakeHttpAdapter adapter;
  late ApiClient api;
  late List<bool> reach;
  var expired = 0;

  Future<void> withToken({Duration valid = const Duration(minutes: 15)}) =>
      tokens.writeToken(
        JwtDecoder.buildUnsignedDemoToken(
            subject: 'u1', expiresAt: DateTime.now().add(valid)),
      );

  setUp(() {
    tokens = InMemoryTokenStorage();
    expired = 0;
    reach = [];
    adapter = FakeHttpAdapter((_) async => jsonBody(200, []));
    final dio = createDio(
      config: AppConfig.fromEnvironment()
          .copyWith(apiBaseUrl: 'https://api.test', demoMode: false),
      tokenStorage: tokens,
      onSessionExpired: () => expired++,
    )..httpClientAdapter = adapter;
    api = ApiClient(dio, onReachability: reach.add);
  });

  group('Autenticación contra el contrato del backend', () {
    test('login envía email/password y lee token.accessToken y user.roles',
        () async {
      adapter.handler = (o) async => jsonBody(200, {
            'token': {
              'accessToken': 'jwt.x.y',
              'tokenType': 'Bearer',
              'expiresInSeconds': 900
            },
            'user': {
              'id': '00000000-0000-0000-0000-000000000001',
              'email': 'operador@example.com',
              'firstName': 'Ana',
              'lastName': 'Pérez',
              'roles': ['Operator'],
            },
          });
      final r =
          await AuthRemoteDataSource(api).login('operador@example.com', 'x');
      final req = adapter.requests.single;
      expect(req.path, ApiEndpoints.login);
      expect(
          req.data, equals({'email': 'operador@example.com', 'password': 'x'}));
      expect(req.headers.containsKey('Authorization'), isFalse);
      expect(r.accessToken, 'jwt.x.y');
      expect(r.expiresIn, const Duration(seconds: 900));
      expect(r.user.fullName, 'Ana Pérez');
      expect(r.user.roles.single.name, 'operator');
    });

    test('401 en login = credenciales inválidas (sin cerrar sesión)', () async {
      adapter.handler = (_) async => jsonBody(401, {});
      await expectLater(
        () => AuthRemoteDataSource(api).login('a@b.pe', 'x'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
      expect(expired, 0);
    });

    test('429 = demasiados intentos', () async {
      adapter.handler = (_) async => jsonBody(429, {});
      await expectLater(
        () => AuthRemoteDataSource(api).login('a@b.pe', 'x'),
        throwsA(isA<TooManyRequestsFailure>()),
      );
    });
  });

  group('Errores HTTP', () {
    Future<Failure> failFor(int status, [Object? body]) async {
      await withToken();
      adapter.handler = (_) async => jsonBody(status, body ?? {});
      try {
        await api.get('/api/devices');
      } on Failure catch (f) {
        return f;
      }
      throw StateError('no falló');
    }

    test('ValidationProblemDetails de ASP.NET se traduce por campo', () async {
      final f = await failFor(400, {
        'title': 'One or more validation errors occurred.',
        'status': 400,
        'errors': {
          'SerialNumber': ['The SerialNumber field is required.'],
        },
      });
      expect(f, isA<ValidationFailure>());
      expect((f as ValidationFailure).fieldErrors['serialNumber'],
          'The SerialNumber field is required.');
      expect(f.message, 'The SerialNumber field is required.');
    });

    test('403, 404, 409 y 503', () async {
      expect(await failFor(403), isA<ForbiddenFailure>());
      expect(await failFor(404), isA<NotFoundFailure>());
      expect(await failFor(409), isA<ConflictFailure>());
      expect(await failFor(503), isA<ServiceUnavailableFailure>());
      expect(reach.last, isFalse);
    });

    test('401 en ruta protegida cierra la sesión', () async {
      final f = await failFor(401);
      expect(f, isA<SessionExpiredFailure>());
      expect(expired, 1);
      expect(await tokens.readToken(), isNull);
    });

    test('token vencido se rechaza sin enviar la petición', () async {
      await withToken(valid: const Duration(minutes: -1));
      await expectLater(
          () => api.get('/api/devices'), throwsA(isA<SessionExpiredFailure>()));
      expect(adapter.requests, isEmpty);
    });

    test('sin red: nube no alcanzable', () async {
      await withToken();
      adapter.handler = (_) async => throw const SocketException('sin red');
      await expectLater(
          () => api.get('/api/devices'), throwsA(isA<NetworkFailure>()));
      expect(reach.last, isFalse);
    });
  });

  group('Health checks (públicos)', () {
    test('/health/ready sin token: listo', () async {
      adapter.handler = (_) async => jsonBody(200, {'status': 'ready'});
      final h = await HealthRemoteDataSource(api).check();
      expect(h.ready, isTrue);
      expect(adapter.requests.single.headers.containsKey('Authorization'),
          isFalse);
    });

    test('503: servidor activo pero base de datos caída', () async {
      adapter.handler = (_) async => jsonBody(503, {'status': 'unhealthy'});
      final h = await HealthRemoteDataSource(api).check();
      expect(h.ready, isFalse);
    });
  });

  group('Paginación sin total de registros', () {
    List<int> range(int a, int b) => [for (var i = a; i < b; i++) i];

    test('fetchAllPages se detiene en la página incompleta', () async {
      final pages = <int>[];
      final all = await fetchAllPages<int>((p, s) async {
        pages.add(p);
        return range((p - 1) * s, p == 3 ? (p - 1) * s + 5 : p * s);
      }, pageSize: 10);
      expect(all, hasLength(25));
      expect(pages, equals([1, 2, 3]));
    });

    test('fetchNewest con orden descendente usa la primera página', () async {
      final calls = <int>[];
      final base = DateTime(2026);
      final r = await fetchNewest<int>(
        (p, s) async {
          calls.add(p);
          return range((p - 1) * s, p * s).map((i) => 10000 - i).toList();
        },
        (v) => base.add(Duration(seconds: v)),
        pageSize: 10,
        keep: 10,
      );
      expect(calls, equals([1]));
      expect(r.first, 10000);
    });

    test('fetchNewest con orden ascendente encuentra las últimas páginas',
        () async {
      const total = 1234;
      final calls = <int>[];
      final base = DateTime(2026);
      final r = await fetchNewest<int>(
        (p, s) async {
          calls.add(p);
          final start = (p - 1) * s;
          if (start >= total) return [];
          return range(start, start + s > total ? total : start + s);
        },
        (v) => base.add(Duration(seconds: v)),
        pageSize: 10,
        keep: 25,
      );
      expect(r.first, total - 1);
      expect(r, hasLength(25));
      expect(r.last, total - 25);
      expect(calls.length, lessThan(30));
    });
  });
}
