import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/sc_page.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../domain/entities/risk_filter.dart';
import '../widgets/risk_forms.dart';
import '../widgets/risk_widgets.dart';

final riskFilterProvider =
    StateProvider<RiskFilter>((ref) => const RiskFilter());

/// Historial completo de riesgos con filtros (US20).
class RiskHistoryPage extends ConsumerWidget {
  const RiskHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risks = ref.watch(risksProvider);
    final devices = ref.watch(devicesProvider).valueOrNull?.data;
    final filter = ref.watch(riskFilterProvider);
    return ScPage(
      title: 'Historial de riesgos',
      subtitle: 'Ordenado del más reciente al más antiguo',
      onRefresh: () {
        ref.invalidate(risksProvider);
        return settle([ref.read(risksProvider.future)]);
      },
      headerTrailing: Badge(
        isLabelVisible: filter.activeCount > 0,
        label: Text('${filter.activeCount}'),
        child: IconButton.filledTonal(
          tooltip: 'Filtrar',
          icon: const Icon(Icons.tune_rounded),
          onPressed: () async {
            final f = await showRiskFilterSheet(context, filter);
            if (f != null) ref.read(riskFilterProvider.notifier).state = f;
          },
        ),
      ),
      children: [
        AsyncValueView(
          value: risks,
          onRetry: () => ref.invalidate(risksProvider),
          data: (r) {
            final list = filter.apply(r.data);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DataFreshnessNote(r),
                Text('${list.length} de ${r.data.length} registros',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                if (list.isEmpty)
                  EmptyView(
                    icon: Icons.manage_search_rounded,
                    title: 'Sin resultados',
                    message: filter.isEmpty
                        ? 'No hay riesgos registrados.'
                        : 'Ningún riesgo coincide con los filtros.',
                    action: filter.isEmpty
                        ? null
                        : OutlinedButton(
                            onPressed: () => ref
                                .read(riskFilterProvider.notifier)
                                .state = const RiskFilter(),
                            child: const Text('Quitar filtros'),
                          ),
                  ),
                for (final x in list) ...[
                  RiskTile(
                    risk: x,
                    deviceName: deviceById(devices, x.deviceId)?.name,
                    onTap: () => context.go(Routes.risk(x.id)),
                  ),
                  kGap,
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
