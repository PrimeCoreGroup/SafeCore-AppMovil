import 'package:flutter/material.dart';

import '../theme/status_colors.dart';

/// Tarjeta con borde izquierdo de color y fondo tintado (estilo Figma de
/// alertas y notas). Las críticas destacan por color, icono y grosor.
class TintedCard extends StatelessWidget {
  const TintedCard({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    this.subtitle,
    this.footer,
    this.onTap,
    this.emphasized = false,
  });

  final StatusTone tone;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? footer;
  final VoidCallback? onTap;

  /// Alertas críticas: borde más grueso y título en color de estado.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: tone.background,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left:
                  BorderSide(color: tone.foreground, width: emphasized ? 4 : 3),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: tone.foreground, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: emphasized ? tone.foreground : null,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: textTheme.bodySmall),
                    ],
                    if (footer != null) ...[const SizedBox(height: 8), footer!],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right,
                    color: tone.foreground.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nota informativa (p. ej. "Datos de demostración", "Sin confirmación").
class InfoNote extends StatelessWidget {
  const InfoNote({
    super.key,
    required this.title,
    required this.message,
    this.tone,
    this.icon = Icons.info_outline,
  });

  final String title;
  final String message;
  final StatusTone? tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) => TintedCard(
        tone: tone ?? context.status.info,
        icon: icon,
        title: title,
        subtitle: message,
      );
}
