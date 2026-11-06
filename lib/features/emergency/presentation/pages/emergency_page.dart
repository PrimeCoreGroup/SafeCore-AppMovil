import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../domain/entities/emergency.dart';
import '../widgets/emergency_widgets.dart';

/// Respuestas de emergencia: activas e historial.
class EmergencyPage extends ConsumerWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(emergencyProvider);
    final all = data.valueOrNull?.data;
    int byDate(EmergencyResponse a, EmergencyResponse b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
    final active = (all?.responses.where((r) => r.status.isActive).toList() ??
        [])
      ..sort(byDate);
    final closed = (all?.responses.where((r) => !r.status.isActive).toList() ??
        [])
      ..sort(byDate);

    Widget list(List<EmergencyResponse> items, bool activeTab) =>
        RefreshIndicator(
          onRefresh: () {
            ref.invalidate(emergencyProvider);
            return settle([ref.read(emergencyProvider.future)]);
          },
          child: AsyncValueView(
            value: data,
            onRetry: () => ref.invalidate(emergencyProvider),
            data: (r) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                DataFreshnessNote(r),
                if (items.isEmpty)
                  EmptyView(
                    icon: Icons.emergency_outlined,
                    title:
                        activeTab ? 'Sin respuestas activas' : 'Sin historial',
                    message: activeTab
                        ? 'Inicia una respuesta desde el detalle de un riesgo activo.'
                        : 'Las respuestas resueltas o canceladas aparecerán aquí.',
                  ),
                for (final resp in items) ...[
                  ResponseTile(
                    response: resp,
                    protocol: r.data.protocol(resp.protocolId),
                    actions: r.data.actionsFor(resp.id),
                    onTap: () => context.go(Routes.response(resp.id)),
                  ),
                  const SizedBox(height: 10),
                ],
                if (activeTab) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Las respuestas y acciones son registros de coordinación del equipo. '
                    'El backend no envía comandos físicos; el ESP32 actúa localmente.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: ScAppBar(
          title: 'Emergencias',
          actions: [
            IconButton(
              tooltip: 'Protocolos',
              onPressed: () => context.go(Routes.protocols),
              icon: const Icon(Icons.rule_folder_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            TabBar(tabs: [
              Tab(text: 'Activas (${active.length})'),
              Tab(text: 'Historial (${closed.length})')
            ]),
            Expanded(
                child: TabBarView(
                    children: [list(active, true), list(closed, false)])),
          ],
        ),
      ),
    );
  }
}
