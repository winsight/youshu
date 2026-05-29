import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static SystemUiOverlayStyle systemOverlayStyle({required bool isDark}) {
    return (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
        .copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: isDark
              ? const Color(0xFF151816)
              : AppColors.background,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      shadow: Colors.black.withAlpha(20),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: systemOverlayStyle(isDark: false),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const background = Color(0xFF151816);
    const surface = Color(0xFF1D211E);
    const surfaceHigh = Color(0xFF272D29);
    const onSurface = Color(0xFFE6EDE7);
    const onSurfaceVariant = Color(0xFFB7C2B8);
    const outline = Color(0xFF879386);

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryFixedDim,
      onPrimary: const Color(0xFF062313),
      primaryContainer: AppColors.primary,
      onPrimaryContainer: AppColors.onPrimary,
      secondary: const Color(0xFFD4CCBF),
      onSecondary: const Color(0xFF241F18),
      secondaryContainer: const Color(0xFF3D372F),
      onSecondaryContainer: const Color(0xFFF0E8DB),
      tertiary: const Color(0xFFDCC48E),
      onTertiary: const Color(0xFF2B2005),
      tertiaryContainer: const Color(0xFF4B3D1E),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLowest: const Color(0xFF101310),
      surfaceContainerLow: const Color(0xFF1A1E1B),
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: const Color(0xFF323833),
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: const Color(0xFF424B43),
      inverseSurface: onSurface,
      onInverseSurface: background,
      shadow: Colors.black.withAlpha(90),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: systemOverlayStyle(isDark: true),
        iconTheme: const IconThemeData(color: onSurface),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primaryFixedDim,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryFixedDim,
        foregroundColor: const Color(0xFF062313),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primary.withAlpha(90),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (_) => const TextStyle(color: onSurface, fontSize: 12),
        ),
      ),
    );
  }
}
