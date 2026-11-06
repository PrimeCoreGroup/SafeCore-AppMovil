import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/status_colors.dart';

/// Encabezado con degradado de marca (azul → verde SafeCore).
class GradientHero extends StatelessWidget {
  const GradientHero({
    super.key,
    required this.child,
    this.colors,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final List<Color>? colors;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius + 4),
          gradient: LinearGradient(
            colors: colors ??
                const [
                  AppColors.brandBlue,
                  Color(0xFF0B7FD1),
                  AppColors.brandGreen
                ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (colors?.first ?? AppColors.brandBlue)
                  .withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: IconTheme.merge(
            data: const IconThemeData(color: Colors.white),
            child: child,
          ),
        ),
      );
}

/// Indicador circular de estado para el encabezado.
class StatusRing extends StatelessWidget {
  const StatusRing(
      {super.key, required this.icon, this.progress = 1, this.size = 64});

  final IconData icon;
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: size,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 5,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
            Icon(icon, size: size * 0.45, color: Colors.white),
          ],
        ),
      );
}

/// Indicador numérico compacto (KPI).
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.tone,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final StatusTone? tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = tone?.foreground ?? scheme.primary;
    final bg = tone?.background ?? scheme.primary.withValues(alpha: 0.08);
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: fg),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini gráfico de línea para series de telemetría.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.color,
    this.height = 44,
    this.threshold,
  });

  final List<double> values;
  final Color? color;
  final double height;

  /// Línea punteada del umbral de detección (si aplica).
  final double? threshold;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: values.isEmpty
          ? 'Sin datos para graficar'
          : 'Gráfico de ${values.length} lecturas, última ${values.last.toStringAsFixed(1)}',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: values.length < 2
            ? Center(
                child: Text(
                  values.isEmpty ? 'Sin datos' : 'Pocos datos',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            : CustomPaint(
                painter: _SparkPainter(
                  values,
                  c,
                  threshold,
                  Theme.of(context).colorScheme.error,
                ),
              ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.threshold, this.thresholdColor);

  final List<double> values;
  final Color color;
  final double? threshold;
  final Color thresholdColor;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    final t = threshold;
    if (t != null) {
      lo = math.min(lo, t);
      hi = math.max(hi, t);
    }
    if (hi - lo < 1e-6) {
      hi += 1;
      lo -= 1;
    }
    double y(double v) =>
        size.height - (v - lo) / (hi - lo) * (size.height - 4) - 2;
    final dx = size.width / (values.length - 1);
    final path = Path()..moveTo(0, y(values.first));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(i * dx, y(values[i]));
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    if (t != null) {
      final ty = y(t);
      final p = Paint()
        ..color = thresholdColor.withValues(alpha: 0.7)
        ..strokeWidth = 1;
      for (double x = 0; x < size.width; x += 8) {
        canvas.drawLine(
            Offset(x, ty), Offset(math.min(x + 4, size.width), ty), p);
      }
    }
    canvas.drawCircle(
      Offset(size.width, y(values.last)),
      3.5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.values != values || old.color != color || old.threshold != threshold;
}

/// Bloque animado de carga (esqueleto).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox(
      {super.key, this.height = 80, this.width = double.infinity});
  final double height;
  final double width;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.outline;
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 0.8).animate(_c),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: base.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
      ),
    );
  }
}

/// Lista de esqueletos para estados de carga de pantallas completas.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.height = 84});
  final int count;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Cargando',
        child: Column(
          children: [
            for (var i = 0; i < count; i++) ...[
              SkeletonBox(height: height),
              const SizedBox(height: 12),
            ],
          ],
        ),
      );
}

/// Icono en recuadro tintado.
class IconBadge extends StatelessWidget {
  const IconBadge(
      {super.key, required this.icon, required this.tone, this.size = 40});
  final IconData icon;
  final StatusTone tone;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, color: tone.foreground, size: size * 0.55),
      );
}
