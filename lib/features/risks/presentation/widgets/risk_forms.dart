import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/domain/health_status.dart';
import '../../domain/entities/risk_filter.dart';
import '../../domain/entities/risk_situation.dart';

/// Alta manual de un riesgo (Administrator, Operator).
Future<RiskDraft?> showRiskFormSheet(BuildContext context) =>
    showModalBottomSheet<RiskDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _RiskForm(),
    );

class _RiskForm extends StatefulWidget {
  const _RiskForm();

  @override
  State<_RiskForm> createState() => _RiskFormState();
}

class _RiskFormState extends State<_RiskForm> {
  RiskType _type = RiskType.fire;
  Severity _severity = Severity.high;
  DateTime _at = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelLarge;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Registrar riesgo manual',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Úsalo para incidentes reportados por personas (no detectados por sensores).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text('Tipo', style: label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in RiskType.selectable)
                ChoiceChip(
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t)),
            ],
          ),
          const SizedBox(height: 14),
          Text('Gravedad', style: label),
          const SizedBox(height: 8),
          SegmentedButton<Severity>(
            segments: [
              for (final s in Severity.values)
                ButtonSegment(value: s, label: Text(s.label))
            ],
            selected: {_severity},
            onSelectionChanged: (s) => setState(() => _severity = s.first),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _at,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (d == null || !context.mounted) return;
              final t = await showTimePicker(
                  context: context, initialTime: TimeOfDay.fromDateTime(_at));
              setState(() => _at = DateTime(d.year, d.month, d.day,
                  t?.hour ?? _at.hour, t?.minute ?? _at.minute));
            },
            icon: const Icon(Icons.event_rounded),
            label: Text('Detectado: ${DateFormatter.dateTime(_at)}'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              RiskDraft(
                  riskType: _type,
                  status: RiskStatus.open,
                  severity: _severity,
                  detectedAt: _at),
            ),
            child: const Text('Registrar riesgo'),
          ),
        ],
      ),
    );
  }
}

/// Filtros del historial: periodo, tipo, gravedad y estado.
Future<RiskFilter?> showRiskFilterSheet(
        BuildContext context, RiskFilter current) =>
    showModalBottomSheet<RiskFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: current),
    );

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final RiskFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late RiskFilter _f = widget.initial;

  Set<T> _toggle<T>(Set<T> s, T v) =>
      s.contains(v) ? ({...s}..remove(v)) : {...s, v};

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelLarge;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filtrar historial',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Periodo', style: label),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final r = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 3),
                lastDate: now,
                initialDateRange: _f.from != null && _f.to != null
                    ? DateTimeRange(start: _f.from!, end: _f.to!)
                    : null,
              );
              if (r != null) {
                setState(() => _f = _f.copyWith(from: r.start, to: r.end));
              }
            },
            icon: const Icon(Icons.date_range_rounded),
            label: Text(
              _f.from == null
                  ? 'Todas las fechas'
                  : '${DateFormatter.day(_f.from!)} – ${DateFormatter.day(_f.to ?? _f.from!)}',
            ),
          ),
          if (_f.from != null)
            TextButton(
                onPressed: () =>
                    setState(() => _f = _f.copyWith(clearDates: true)),
                child: const Text('Quitar periodo')),
          const SizedBox(height: 12),
          Text('Tipo', style: label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in RiskType.selectable)
                FilterChip(
                  label: Text(t.label),
                  selected: _f.types.contains(t),
                  onSelected: (_) => setState(
                      () => _f = _f.copyWith(types: _toggle(_f.types, t))),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Gravedad', style: label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in Severity.values)
                FilterChip(
                  label: Text(s.label),
                  selected: _f.severities.contains(s),
                  onSelected: (_) => setState(() =>
                      _f = _f.copyWith(severities: _toggle(_f.severities, s))),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Estado', style: label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in RiskStatus.values)
                FilterChip(
                  label: Text(s.label),
                  selected: _f.statuses.contains(s),
                  onSelected: (_) => setState(() =>
                      _f = _f.copyWith(statuses: _toggle(_f.statuses, s))),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(const RiskFilter()),
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_f),
                    child: const Text('Aplicar')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
