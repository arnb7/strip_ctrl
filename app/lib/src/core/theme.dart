import 'package:flutter/material.dart';
import '../providers/ui_style_provider.dart';

class AppTheme {
  static const Color primary = Color(0xFFF97316); // Orange accent
  static const Color amoledBlack = Color(0xFF000000); // 100% Pure AMOLED Black
  static const Color amoledCard = Color(0xFF0B0B0E); // Deep black card surface
  static const Color amoledBorder = Color(0xFF1E1E22); // Zinc border
  static const Color textMuted = Color(0xFFA1A1AA); // Zinc 400
  static const Color success = Color(0xFF10B981); // Emerald 500

  static ThemeData buildTheme({
    required UiStyle style,
    Color accentColor = primary,
    ColorScheme? systemDarkScheme,
    M3ThemePreset preset = M3ThemePreset.system,
  }) {
    final isExpressive = style == UiStyle.expressiveM3;

    if (!isExpressive) {
      // Classic Default (Workspace 2) Pure AMOLED Theme
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: amoledBlack,
        canvasColor: amoledBlack,
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          onPrimary: Colors.white,
          secondary: accentColor,
          surface: amoledCard,
          surfaceContainerLowest: amoledBlack,
          surfaceContainerLow: const Color(0xFF070709),
          surfaceContainer: const Color(0xFF0B0B0E),
          surfaceContainerHigh: const Color(0xFF121216),
          surfaceContainerHighest: const Color(0xFF18181E),
          onSurface: const Color(0xFFF4F4F5),
          error: const Color(0xFFEF4444),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: amoledBlack,
          foregroundColor: Color(0xFFF4F4F5),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: amoledCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: amoledBorder, width: 1.0),
          ),
          elevation: 0,
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        sliderTheme: const SliderThemeData(
          trackHeight: 4.0,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: amoledCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: amoledBorder),
          ),
        ),
      );
    }

    // Material 3 Expressive Colorful Theme
    ColorScheme scheme;
    if (preset == M3ThemePreset.system && systemDarkScheme != null) {
      // Dynamically extract and use Android 12+ wallpaper Monet color scheme
      scheme = systemDarkScheme;
    } else if (preset == M3ThemePreset.stripSync) {
      // Dynamic live LED light sync
      scheme = ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
      );
    } else if (preset == M3ThemePreset.system) {
      // Fallback when system Monet is not available on device
      scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B5CF6),
        secondary: const Color(0xFF06B6D4),
        tertiary: const Color(0xFFEC4899),
        brightness: Brightness.dark,
      );
    } else {
      // Premade curated colorful expressive palettes
      scheme = ColorScheme.fromSeed(
        seedColor: preset.primary,
        secondary: preset.secondary,
        tertiary: preset.tertiary,
        brightness: Brightness.dark,
      );
    }

    final bgSurface = scheme.surfaceContainerLowest;
    final cardSurface = scheme.surfaceContainer;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgSurface,
      canvasColor: bgSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: bgSurface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: scheme.primary.withOpacity(0.35),
            width: 1.5,
          ),
        ),
        elevation: 2,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 12.0,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: scheme.primary.withOpacity(0.40),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // Backward compatibility method
  static ThemeData amoledTheme({
    Color accentColor = primary,
    UiStyle style = UiStyle.workspace2,
  }) {
    return buildTheme(
      style: style,
      accentColor: accentColor,
    );
  }

  // Backward compatibility alias
  static ThemeData darkTheme({Color accentColor = primary}) =>
      amoledTheme(accentColor: accentColor);
}
