import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'status_colors.dart';

/// Tema Material 3 de SafeCore (claro y oscuro).
class AppTheme {
  const AppTheme._();

  static const radius = 16.0;
  static const minTouchTarget = 48.0;

  static ThemeData light() => _build(
        brightness: Brightness.light,
        primary: AppColors.primary,
        ink: AppColors.ink,
        muted: AppColors.muted,
        background: AppColors.background,
        surface: AppColors.surface,
        outline: AppColors.outline,
        indicator: AppColors.navIndicator,
        status: StatusColors.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        ink: AppColors.inkDark,
        muted: AppColors.mutedDark,
        background: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        outline: AppColors.outlineDark,
        indicator: const Color(0xFF1C3358),
        status: StatusColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color ink,
    required Color muted,
    required Color background,
    required Color surface,
    required Color outline,
    required Color indicator,
    required StatusColors status,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF00172F),
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: outline,
      error: status.critical.foreground,
      surfaceContainerHighest: background,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [status],
    );

    final text =
        base.textTheme.apply(bodyColor: ink, displayColor: ink).copyWith(
              headlineSmall: base.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: ink,
                letterSpacing: -0.2,
              ),
              titleLarge: base.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: ink,
              ),
              titleMedium: base.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ink,
              ),
              bodySmall: base.textTheme.bodySmall?.copyWith(color: muted),
            );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius - 4),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: rounded,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, minTouchTarget),
          shape: rounded,
          side: BorderSide(color: outline),
          foregroundColor: primary,
          backgroundColor: surface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, minTouchTarget),
          foregroundColor: primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: BorderSide(color: status.critical.foreground),
        ),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: indicator,
        height: 70,
        elevation: 3,
        shadowColor: Colors.black26,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        minVerticalPadding: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
