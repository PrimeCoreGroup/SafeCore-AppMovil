import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/test_app.dart';

/// Flujo completo en dispositivo/emulador (modo demo):
/// login → riesgo urgente → reconocer → prueba de detección.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'el operador reconoce un riesgo y ejecuta una prueba de detección',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(TestEnv().app());
    await loginAs(tester, 'operador@demo.safecore.pe');

    await tester.tap(find.text('Riesgos').last);
    await settle(tester);
    await tester.tap(find.text('Gas o humo').first);
    await settle(tester);
    await tester.tap(find.byKey(const Key('ack-risk')));
    await settle(tester, steps: 2);
    await tester.tap(find.text('Reconocer').last);
    await settle(tester);
    expect(find.textContaining('reconocido'), findsWidgets);

    await tester.tap(find.text('Dispositivos').last);
    await settle(tester);
    await tester.tap(find.byTooltip('Prueba de detección'));
    await settle(tester);
    await tester.tap(find.textContaining('Nodo Torre Norte'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('run-detection-test')));
    await settle(tester, steps: 2);
    await tester.tap(find.byKey(const Key('critical-confirm-checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('critical-confirm-button')));
    await settle(tester, steps: 30);
    expect(find.text('Riesgo detectado y registrado por el servidor'),
        findsOneWidget);
    await unmount(tester);
  });
}
