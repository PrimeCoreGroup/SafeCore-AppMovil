import 'package:flutter/material.dart';

/// Paleta SafeCore tomada del diseño de Figma y del logotipo oficial.
class AppColors {
  const AppColors._();

  // Marca
  static const brandBlue = Color(0xFF0057FF);
  static const brandGreen = Color(0xFF10B981);
  static const primary = Color(0xFF0065CA);
  static const primaryDark = Color(0xFF4C9BFF);

  // Neutros (claro)
  static const ink = Color(0xFF1E293B);
  static const muted = Color(0xFF64748B);
  static const background = Color(0xFFF3F5F8);
  static const surface = Color(0xFFFFFFFF);
  static const outline = Color(0xFFDDE3EA);
  static const navIndicator = Color(0xFFE5F0FF);

  // Neutros (oscuro)
  static const inkDark = Color(0xFFE2E8F0);
  static const mutedDark = Color(0xFF94A3B8);
  static const backgroundDark = Color(0xFF0B1220);
  static const surfaceDark = Color(0xFF151F31);
  static const outlineDark = Color(0xFF2A3850);

  // Estados
  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFEAF7EF);
  static const warning = Color(0xFF9A6200);
  static const warningBg = Color(0xFFFFF4DE);
  static const critical = Color(0xFFC62828);
  static const criticalBg = Color(0xFFFFEEEE);
  static const offline = Color(0xFF475569);
  static const offlineBg = Color(0xFFEEF1F4);
  static const info = Color(0xFF0065CA);
  static const infoBg = Color(0xFFE8F1FC);

  static const brandGradient = LinearGradient(
    colors: [brandBlue, brandGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
