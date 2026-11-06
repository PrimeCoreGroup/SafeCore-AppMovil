import 'package:flutter/material.dart';

/// Logotipo oficial SafeCore (escudo del SVG de marca + nombre).
class ScLogo extends StatelessWidget {
  const ScLogo(
      {super.key, this.size = 24, this.showName = true, this.fontSize});

  final double size;
  final bool showName;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final shield = Image.asset(
      'assets/logos/safecore-shield.png',
      height: size,
      semanticLabel: showName ? null : 'SafeCore',
      errorBuilder: (_, __, ___) => Icon(
        Icons.shield_outlined,
        size: size,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    if (!showName) return shield;
    return Semantics(
      label: 'SafeCore',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            shield,
            SizedBox(width: size * 0.33),
            Text(
              'SafeCore',
              style: TextStyle(
                fontSize: fontSize ?? size * 0.85,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
