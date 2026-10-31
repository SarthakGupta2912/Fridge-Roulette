import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/app_sizes.dart';

/// Light and dark color themes for the whole app.
class AppTheme {
  const AppTheme._();

  /// A warm orange seed color that feels like food and sunshine.
  static const Color seed = Color(0xFFFF7A00);

  static ThemeData light() {
    return _build(Brightness.light);
  }

  static ThemeData dark() {
    return _build(Brightness.dark);
  }

  static ThemeData _build(Brightness brightness) {
    // The Poppins files are bundled in assets/google_fonts, so the app never
    // downloads a font while the child is using it.
    GoogleFonts.config.allowRuntimeFetching = false;

    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      contrastLevel: 0.35,
    );
    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
    );
    final TextTheme text = _poppinsTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(color: colors.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(64, AppSizes.touchTarget),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.md,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.touchTarget, AppSizes.touchTarget),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
          ),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.touchTarget, AppSizes.minTouchTarget),
          ),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: text.bodyLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: text.bodyLarge?.copyWith(
          color: colors.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  /// Poppins with one set of sizes for phones and tablets.
  static TextTheme _poppinsTextTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: _poppins(
        base.headlineLarge,
        size: 32,
        weight: FontWeight.w900,
        height: 1.05,
      ),
      headlineMedium: _poppins(
        base.headlineMedium,
        size: 28,
        weight: FontWeight.w900,
        height: 1.1,
      ),
      headlineSmall: _poppins(
        base.headlineSmall,
        size: 24,
        weight: FontWeight.w800,
        height: 1.15,
      ),
      titleLarge: _poppins(base.titleLarge, size: 22, weight: FontWeight.w800),
      titleMedium: _poppins(
        base.titleMedium,
        size: 18,
        weight: FontWeight.w700,
      ),
      titleSmall: _poppins(base.titleSmall, size: 16, weight: FontWeight.w700),
      bodyLarge: _poppins(
        base.bodyLarge,
        size: 18,
        weight: FontWeight.w400,
        height: 1.35,
      ),
      bodyMedium: _poppins(
        base.bodyMedium,
        size: 16,
        weight: FontWeight.w400,
        height: 1.35,
      ),
      bodySmall: _poppins(
        base.bodySmall,
        size: 13,
        weight: FontWeight.w400,
        height: 1.3,
      ),
      labelLarge: _poppins(base.labelLarge, size: 18, weight: FontWeight.w800),
      labelMedium: _poppins(
        base.labelMedium,
        size: 14,
        weight: FontWeight.w700,
      ),
      labelSmall: _poppins(base.labelSmall, size: 12, weight: FontWeight.w600),
    );
  }

  static TextStyle _poppins(
    TextStyle? base, {
    required double size,
    required FontWeight weight,
    double? height,
  }) {
    return GoogleFonts.poppins(
      textStyle: base,
      fontSize: size,
      fontWeight: weight,
      height: height,
    );
  }
}
