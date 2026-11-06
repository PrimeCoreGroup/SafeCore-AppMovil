import 'package:flutter/material.dart';

import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/visuals.dart';
import '../../../telemetry/domain/entities/sensor_reading.dart';
import '../../../telemetry/domain/services/risk_evaluator.dart';
import '../../../telemetry/domain/services/telemetry_summary.dart';
import '../../domain/entities/device.dart';

StatusTone connectivityTone(BuildContext c, DeviceConnectivity s) =>
    switch (s) {
      DeviceConnectivity.online => c.status.normal,
      DeviceConnectivity.degraded => c.status.warning,
      DeviceConnectivity.maintenance => c.status.info,
      DeviceConnectivity.offline ||
      DeviceConnectivity.unknown =>
        c.status.offline,
    };

IconData connectivityIcon(DeviceConnectivity s) => switch (s) {
      DeviceConnectivity.online => Icons.wifi_rounded,
      DeviceConnectivity.degraded => Icons.network_check_rounded,
      DeviceConnectivity.maintenance => Icons.build_circle_outlined,
      DeviceConnectivity.offline ||
      DeviceConnectivity.unknown =>
        Icons.wifi_off_rounded,
    };

IconData sensorIcon(SensorType t) => switch (t) {
      SensorType.temperature => Icons.thermostat_rounded,
      SensorType.gas => Icons.air_rounded,
      SensorType.accelerometer => Icons.vibration_rounded,
      SensorType.gyroscope => Icons.threesixty_rounded,
      SensorType.unknown => Icons.sensors_rounded,
    };

/// Tarjeta de dispositivo con su última telemetría.
class DeviceCard extends StatelessWidget {
  const DeviceCard(
      {super.key,
      required this.device,
      this.telemetry,
      this.openRisks = 0,
      this.onTap});

  final Device device;
  final DeviceTelemetry? telemetry;
  final int openRisks;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = connectivityTone(context, device.connectivity);
    final last = telemetry?.lastSeen;
    final temp = telemetry?.latest(SensorType.temperature);
    final gas = telemetry?.latest(SensorType.gas);
    return SectionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                  icon: Icons.memory_rounded,
                  tone: context.status.info,
                  size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('${device.serialNumber} · ${device.category}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              StatusChip(
                  label: device.connectivity.label,
                  tone: tone,
                  icon: connectivityIcon(device.connectivity)),
            ],
          ),
          if (temp != null || gas != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (temp != null) Expanded(child: _MiniReading(reading: temp)),
                if (temp != null && gas != null) const SizedBox(width: 10),
                if (gas != null) Expanded(child: _MiniReading(reading: gas)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  last == null
                      ? 'Sin lecturas recientes'
                      : 'Última lectura ${DateFormatter.relative(last)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (openRisks > 0)
                StatusChip(
                  label: '$openRisks riesgo(s)',
                  tone: context.status.critical,
                  icon: Icons.warning_amber_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniReading extends StatelessWidget {
  const _MiniReading({required this.reading});
  final SensorReading reading;

  @override
  Widget build(BuildContext context) {
    final alarm = reading.isSensorFault ||
        reading.digitalAlarm == true ||
        (reading.sensorType == SensorType.temperature &&
            (reading.measuredValue ?? 0) >= DetectionThresholds.fireCelsius);
    final tone = alarm ? context.status.critical : context.status.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: tone.background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(sensorIcon(reading.sensorType),
              size: 18, color: tone.foreground),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              reading.displayValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: tone.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloque de una serie de telemetría con gráfico y umbral.
class TelemetrySeriesCard extends StatelessWidget {
  const TelemetrySeriesCard(
      {super.key, required this.type, required this.series});

  final SensorType type;
  final List<SensorReading> series;

  double? get _threshold => switch (type) {
        SensorType.temperature => DetectionThresholds.fireCelsius,
        _ => null,
      };

  String get _hint => switch (type) {
        SensorType.temperature =>
          'Umbral de fuego: ≥ ${DetectionThresholds.fireCelsius.toStringAsFixed(0)} °C · -127 °C = falla del sensor',
        SensorType.gas =>
          'Alerta: salida digital activa o subida > ${DetectionThresholds.gasRiseAdcCounts.toStringAsFixed(0)} cuentas ADC',
        SensorType.accelerometer =>
          'Impacto: cambio de magnitud > ${DetectionThresholds.impactDeltaCounts.toStringAsFixed(0)} cuentas',
        _ => 'Lecturas reportadas por el dispositivo',
      };

  @override
  Widget build(BuildContext context) {
    final last = series.isEmpty ? null : series.last;
    final values = [
      for (final r in series)
        if (r.plotValue != null && !r.isSensorFault) r.plotValue!
    ];
    return SectionCard(
      title: type.label,
      icon: sensorIcon(type),
      trailing: last == null
          ? null
          : Text(
              last.displayValue,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Sparkline(values: values, threshold: _threshold, height: 56),
          const SizedBox(height: 8),
          Text(_hint, style: Theme.of(context).textTheme.bodySmall),
          if (last != null)
            Text(
              'Capturada: ${DateFormatter.dateTime(last.capturedAt)} · ${series.length} lecturas',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
