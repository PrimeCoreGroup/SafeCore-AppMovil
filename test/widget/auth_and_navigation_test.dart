import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safecore_mobile/core/connectivity/connectivity_status.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('login: valida el formulario antes de enviar', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(TestEnv().app());
    await settle(tester);
    expect(find.text('Iniciar sesión'), findsWidgets);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('login: credenciales inválidas muestran el motivo',
      (tester) async {
    useTallScreen(tester);
    final env = TestEnv();
    await tester.pumpWidget(env.app());
    await settle(tester);
    await tester.enterText(
        find.byKey(const Key('login-email')), 'admin@demo.safecore.pe');
    await tester.enterText(
        find.byKey(const Key('login-password')), 'incorrecta');
    await tester.tap(find.byKey(const Key('login-submit')));
    await settle(tester);
    expect(
        find.textContaining('Correo o contraseña incorrectos'), findsOneWidget);
    expect(await env.tokens.readToken(), isNull);
    await unmount(tester);
  });

  testWidgets('con el servidor real se puede pasar al modo demostración',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(TestEnv(demo: false).app());
    await settle(tester);
    await tester.tap(find.byKey(const Key('enter-demo')));
    await settle(tester, steps: 2);
    expect(find.text('Cuentas de demostración'), findsOneWidget);
    expect(find.text('DEMO'), findsNothing);
    await unmount(tester);
  });

  testWidgets('administrador: dashboard con riesgo urgente y navegación',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(TestEnv().app());
    await loginAs(tester, 'admin@demo.safecore.pe');
    expect(find.text('Hola, Carlos'), findsOneWidget);
    expect(find.text('Estado del sistema'), findsOneWidget);
    expect(find.text('Crítico · Requiere revisión'), findsOneWidget);

    await tester.tap(find.text('Dispositivos').last);
    await settle(tester);
    expect(find.text('Nodo Cocina comunal'), findsWidgets);

    await tester.tap(find.text('Riesgos').last);
    await settle(tester);
    expect(find.textContaining('Activos ('), findsOneWidget);
    expect(find.text('Gas o humo'), findsWidgets);

    await tester.tap(find.text('Emergencias').last);
    await settle(tester);
    expect(find.textContaining('Activas ('), findsOneWidget);

    await tester.tap(find.text('Perfil').last);
    await settle(tester);
    expect(find.text('Usuarios'), findsOneWidget);
    expect(find.text('Configuración'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('residente: solo Inicio, Avisos y Perfil', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(TestEnv().app());
    await loginAs(tester, 'residente@demo.safecore.pe');
    expect(find.text('Hola, Rosa'), findsOneWidget);
    expect(find.text('Dispositivos'), findsNothing);
    expect(find.text('Riesgos'), findsNothing);
    await tester.tap(find.text('Avisos').last);
    await settle(tester);
    expect(find.text('Mis avisos'), findsOneWidget);
    expect(find.text('Alerta de gas en cocina comunal'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('respondedor: no ve gestión de usuarios ni pruebas de detección',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(TestEnv().app());
    await loginAs(tester, 'respondedor@demo.safecore.pe');
    expect(find.text('Prueba de detección'), findsNothing);
    await tester.tap(find.text('Perfil').last);
    await settle(tester);
    expect(find.text('Usuarios'), findsNothing);
    expect(find.text('Configuración'), findsNothing);
    await unmount(tester);
  });

  testWidgets('sin conexión: banner offline y el riesgo urgente prevalece',
      (tester) async {
    useTallScreen(tester);
    final env = TestEnv();
    await tester.pumpWidget(env.app());
    await loginAs(tester, 'operador@demo.safecore.pe');
    expect(find.text(kLocalOperationMessage), findsNothing);
    env.probe.set(false);
    await settle(tester);
    expect(find.text(kLocalOperationMessage), findsOneWidget);
    expect(find.text('Este teléfono no tiene conexión a Internet'),
        findsOneWidget);
    expect(find.text('Crítico · Requiere revisión'), findsOneWidget);
    expect(find.text('Sin riesgos activos'), findsNothing);
    env.probe.set(true);
    await settle(tester);
    expect(find.text(kLocalOperationMessage), findsNothing);
    await unmount(tester);
  });
}
