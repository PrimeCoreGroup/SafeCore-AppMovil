// @pure-dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safecore_mobile/core/config/app_config.dart';
import 'package:safecore_mobile/core/security/jwt_decoder.dart';

AppConfig config({
  String url = 'https://api.safecore.pe',
  bool demo = false,
  bool insecure = false,
  String env = 'development',
}) =>
    AppConfig.fromEnvironment().copyWith(
      apiBaseUrl: url,
      demoMode: demo,
      allowInsecureHttp: insecure,
      environment: env,
    );

void main() {
  group('JwtDecoder', () {
    test('lee sub y exp de un token válido', () {
      final exp = DateTime.utc(2030, 1, 1);
      final token =
          JwtDecoder.buildUnsignedDemoToken(subject: 'u1', expiresAt: exp);
      final claims = JwtDecoder.tryDecode(token)!;
      expect(claims.subject, 'u1');
      expect(claims.expiresAt, exp);
      expect(claims.isExpired(now: DateTime.utc(2029)), isFalse);
    });

    test('considera expirado el token dentro del margen de seguridad', () {
      final exp = DateTime.utc(2030, 1, 1, 12);
      final claims = JwtDecoder.tryDecode(
        JwtDecoder.buildUnsignedDemoToken(subject: 'u1', expiresAt: exp),
      )!;
      expect(
        claims.isExpired(now: exp.subtract(const Duration(seconds: 10))),
        isTrue,
      );
      expect(
          claims.isExpired(now: exp.add(const Duration(minutes: 1))), isTrue);
    });

    test('devuelve null con tokens malformados', () {
      expect(JwtDecoder.tryDecode('no-es-un-jwt'), isNull);
      expect(JwtDecoder.tryDecode('a.b.c'), isNull);
    });
  });

  group('AppConfig.validate', () {
    test('exige HTTPS fuera del modo demo', () {
      expect(config(url: 'http://10.0.2.2:8080').validate(), isNotEmpty);
      expect(config().validate(), isEmpty);
    });

    test('permite HTTP solo si se habilita y no es producción', () {
      expect(
        config(url: 'http://10.0.2.2:8080', insecure: true).validate(),
        isEmpty,
      );
      expect(
        config(url: 'http://api', insecure: true, env: 'production').validate(),
        isNotEmpty,
      );
    });

    test('el modo demo no requiere URL', () {
      expect(config(url: '', demo: true).validate(), isEmpty);
      expect(config(url: '').validate(), isNotEmpty);
    });
  });
}
