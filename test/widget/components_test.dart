import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safecore_mobile/core/theme/app_theme.dart';
import 'package:safecore_mobile/core/widgets/confirm_dialog.dart';
import 'package:safecore_mobile/core/widgets/visuals.dart';
import 'package:safecore_mobile/features/risks/domain/entities/risk_situation.dart';
import 'package:safecore_mobile/features/risks/presentation/widgets/risk_widgets.dart';
import 'package:safecore_mobile/shared/domain/health_status.dart';

Widget host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

RiskSituation r(Severity s, RiskStatus st) => RiskSituation(
      id: '${s.name}-${st.name}',
      riskType: RiskType.fire,
      status: st,
      severity: s,
      detectedAt: DateTime(2026, 11, 6, 10),
    );

void main() {
  testWidgets('la confirmación crítica exige marcar la casilla',
      (tester) async {
    bool? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async => result = await showCriticalConfirmDialog(
              context,
              title: '¿Prueba?',
              warning: 'Se registrarán lecturas.',
              acknowledgement: 'Entiendo',
              confirmLabel: 'Ejecutar',
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('critical-confirm-button'));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(find.byKey(const Key('critical-confirm-checkbox')));
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('riesgos urgentes se distinguen por icono y etiqueta',
      (tester) async {
    await tester.pumpWidget(
      host(
        Column(
          children: [
            RiskTile(risk: r(Severity.critical, RiskStatus.open)),
            RiskTile(risk: r(Severity.low, RiskStatus.open)),
          ],
        ),
      ),
    );
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    expect(find.text('Gravedad crítica'), findsOneWidget);
    expect(find.text('Gravedad baja'), findsOneWidget);
  });

  testWidgets('sparkline maneja series vacías y con datos', (tester) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            Sparkline(values: []),
            Sparkline(values: [24, 25, 41], threshold: 40),
          ],
        ),
      ),
    );
    expect(find.text('Sin datos'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
