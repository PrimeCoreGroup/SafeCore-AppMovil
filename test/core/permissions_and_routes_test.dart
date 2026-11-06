// @pure-dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safecore_mobile/core/router/route_guard.dart';
import 'package:safecore_mobile/core/router/routes.dart';
import 'package:safecore_mobile/core/security/roles.dart';

String? go(
  String location, {
  SessionPhase session = SessionPhase.authenticated,
  List<UserRole> roles = const [UserRole.administrator],
}) =>
    RouteGuard.redirect(
      session: session,
      permissions: RolePermissions.forRoles(roles),
      location: location,
    );

void main() {
  group('Matriz de roles del backend', () {
    test('Residente: solo sus notificaciones', () {
      final p = RolePermissions.forRoles([UserRole.resident]);
      expect(p, equals({Permission.viewOwnNotifications}));
    });

    test(
        'Respondedor: consulta y registra respuestas/acciones, no cambia riesgos',
        () {
      const r = [UserRole.responder];
      expect(RolePermissions.can(r, Permission.viewOperations), isTrue);
      expect(RolePermissions.can(r, Permission.createResponses), isTrue);
      expect(RolePermissions.can(r, Permission.manageActions), isTrue);
      expect(RolePermissions.can(r, Permission.manageRisks), isFalse);
      expect(RolePermissions.can(r, Permission.updateResponses), isFalse);
      expect(RolePermissions.can(r, Permission.postReadings), isFalse);
    });

    test(
        'Operador: riesgos, protocolos y lecturas; no usuarios ni dispositivos',
        () {
      const r = [UserRole.operator];
      expect(RolePermissions.can(r, Permission.manageRisks), isTrue);
      expect(RolePermissions.can(r, Permission.postReadings), isTrue);
      expect(RolePermissions.can(r, Permission.manageProtocols), isTrue);
      expect(RolePermissions.can(r, Permission.manageUsers), isFalse);
      expect(RolePermissions.can(r, Permission.manageDevices), isFalse);
      expect(RolePermissions.can(r, Permission.deleteRisks), isFalse);
      expect(RolePermissions.can(r, Permission.editConfiguration), isFalse);
    });

    test('Administrador: todo', () {
      expect(
        RolePermissions.forRoles([UserRole.administrator]),
        equals(Permission.values.toSet()),
      );
    });

    test('roles múltiples se combinan y se elige el principal', () {
      const r = [UserRole.resident, UserRole.operator];
      expect(RolePermissions.can(r, Permission.viewOwnNotifications), isTrue);
      expect(RolePermissions.can(r, Permission.manageRisks), isTrue);
      expect(RolePermissions.primary(r), UserRole.operator);
    });

    test('mapea los valores exactos del API', () {
      expect(UserRole.fromApi('Administrator'), UserRole.administrator);
      expect(UserRole.fromApi('Responder'), UserRole.responder);
      expect(UserRole.fromApi('Device'), UserRole.unknown);
    });
  });

  group('RouteGuard (navegación)', () {
    test('sin sesión envía al login y permite la ayuda de acceso', () {
      expect(
          go(Routes.home, session: SessionPhase.unauthenticated), Routes.login);
      expect(
          go(Routes.accessHelp, session: SessionPhase.unauthenticated), isNull);
    });

    test('verificando sesión muestra el splash', () {
      expect(go(Routes.risks, session: SessionPhase.checking), Routes.splash);
    });

    test('autenticado sale del login', () {
      expect(go(Routes.login), Routes.home);
      expect(go(Routes.splash), Routes.home);
    });

    test('el residente no accede a operación, pero sí a sus avisos', () {
      const r = [UserRole.resident];
      expect(go(Routes.devices, roles: r), Routes.home);
      expect(go(Routes.risk('x'), roles: r), Routes.home);
      expect(go(Routes.emergency, roles: r), Routes.home);
      expect(go(Routes.notifications, roles: r), isNull);
      expect(go(Routes.home, roles: r), isNull);
    });

    test('rutas restringidas por permiso', () {
      expect(go(Routes.users, roles: [UserRole.operator]), Routes.home);
      expect(go(Routes.configuration, roles: [UserRole.operator]), isNull);
      expect(
          go(Routes.configuration, roles: [UserRole.responder]), Routes.home);
      expect(
          go(Routes.detectionTest, roles: [UserRole.responder]), Routes.home);
      expect(go(Routes.detectionTest, roles: [UserRole.operator]), isNull);
      expect(go(Routes.users), isNull);
    });
  });
}
