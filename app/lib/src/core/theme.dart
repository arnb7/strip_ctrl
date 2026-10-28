import 'package:flutter/material.dart';
import '../providers/ui_style_provider.dart';

class AppTheme {
  static const Color primary = Color(0xFFF97316); // Orange accent
  static const Color amoledBlack = Color(0xFF000000); // 100% Pure AMOLED Black
  static const Color amoledCard = Color(0xFF0B0B0E); // Deep black card surface
  static const Color amoledBorder = Color(0xFF1E1E22); // Subtle zinc border
  static const Color textMuted = Color(0xFFA1A1AA); // Zinc 400
  static const Color success = Color(0xFF10B981); // Emerald 500

  static ThemeData amoledTheme({
    Color accentColor = primary,
    UiStyle style = UiStyle.workspace2,
  }) {
    final isExpressive = style == UiStyle.expressiveM3;

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
        surfaceContainerLow: isExpressive ? const Color(0xFF111116) : const Color(0xFF070709),
        surfaceContainer: isExpressive ? const Color(0xFF16161D) : const Color(0xFF0B0B0E),
        surfaceContainerHigh: isExpressive ? const Color(0xFF1E1E26) : const Color(0xFF121216),
        surfaceContainerHighest: isExpressive ? const Color(0xFF262632) : const Color(0xFF18181E),
        onSurface: const Color(0xFFF4F4F5),
        error: const Color(0xFFEF4444),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: amoledBlack,
        foregroundColor: Color(0xFFF4F4F5),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: isExpressive ? const Color(0xFF121218) : amoledCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isExpressive ? 24 : 16),
          side: BorderSide(
            color: isExpressive ? accentColor.withValues(alpha: 0.22) : amoledBorder,
            width: isExpressive ? 1.5 : 1.0,
          ),
        ),
        elevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isExpressive ? 24 : 12),
            ),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: isExpressive ? 12.0 : 4.0,
        thumbShape: isExpressive
            ? const RoundSliderThumbShape(enabledThumbRadius: 10.0)
            : const RoundSliderThumbShape(enabledThumbRadius: 6.0),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isExpressive ? 20 : 8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isExpressive ? 24 : 12),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: amoledCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isExpressive ? 28 : 16),
          side: const BorderSide(color: amoledBorder),
        ),
      ),
    );
  }

  // Backward compatibility alias
  static ThemeData darkTheme({Color accentColor = primary}) =>
      amoledTheme(accentColor: accentColor);
}
