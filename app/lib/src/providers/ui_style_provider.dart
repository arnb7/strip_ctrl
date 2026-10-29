import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UiStyle {
  workspace2,
  expressiveM3;

  /// User-facing display title ('Default' for Workspace 2)
  String get displayName {
    switch (this) {
      case UiStyle.workspace2:
        return 'Default';
      case UiStyle.expressiveM3:
        return 'M3 Expressive';
    }
  }
}

enum M3ThemePreset {
  system(
    id: 'system',
    title: 'System Monet',
    description: 'Dynamic Android wallpaper colors',
    primary: Color(0xFF6750A4),
    secondary: Color(0xFF625B71),
    tertiary: Color(0xFF7D5260),
    icon: Icons.auto_awesome,
  ),
  cyberpunk(
    id: 'cyberpunk',
    title: 'Electric Violet',
    description: 'Neon violet & electric cyan',
    primary: Color(0xFF8B5CF6),
    secondary: Color(0xFF06B6D4),
    tertiary: Color(0xFFEC4899),
    icon: Icons.electric_bolt,
  ),
  sunset(
    id: 'sunset',
    title: 'Sunset Blaze',
    description: 'Vivid orange & radiant rose',
    primary: Color(0xFFF97316),
    secondary: Color(0xFFF43F5E),
    tertiary: Color(0xFFFBBF24),
    icon: Icons.wb_twilight,
  ),
  aurora(
    id: 'aurora',
    title: 'Emerald Aurora',
    description: 'Neon mint & electric lime',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF06B6D4),
    tertiary: Color(0xFF84CC16),
    icon: Icons.spa,
  ),
  ocean(
    id: 'ocean',
    title: 'Deep Ocean',
    description: 'Vibrant cobalt & radiant sky',
    primary: Color(0xFF3B82F6),
    secondary: Color(0xFF6366F1),
    tertiary: Color(0xFF38BDF8),
    icon: Icons.water_drop,
  ),
  plum(
    id: 'plum',
    title: 'Midnight Plum',
    description: 'Electric magenta & hot violet',
    primary: Color(0xFFD946EF),
    secondary: Color(0xFFA855F7),
    tertiary: Color(0xFFF43F5E),
    icon: Icons.nightlife,
  ),
  stripSync(
    id: 'stripSync',
    title: 'LED Color Sync',
    description: 'Matches active LED strip color',
    primary: Color(0xFFF97316),
    secondary: Color(0xFFFBBF24),
    tertiary: Color(0xFFEC4899),
    icon: Icons.lightbulb,
  );

  final String id;
  final String title;
  final String description;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final IconData icon;

  const M3ThemePreset({
    required this.id,
    required this.title,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.icon,
  });
}

class UiStyleNotifier extends StateNotifier<UiStyle> {
  UiStyleNotifier() : super(UiStyle.workspace2) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('ui_style');
    if (saved == 'expressiveM3') {
      state = UiStyle.expressiveM3;
    } else {
      state = UiStyle.workspace2;
    }
  }

  Future<void> setStyle(UiStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ui_style',
      style == UiStyle.expressiveM3 ? 'expressiveM3' : 'workspace2',
    );
  }
}

final uiStyleProvider =
    StateNotifierProvider<UiStyleNotifier, UiStyle>((ref) {
  return UiStyleNotifier();
});

class M3PresetNotifier extends StateNotifier<M3ThemePreset> {
  M3PresetNotifier() : super(M3ThemePreset.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('m3_theme_preset');
    if (saved != null) {
      final found = M3ThemePreset.values.firstWhere(
        (p) => p.id == saved,
        orElse: () => M3ThemePreset.system,
      );
      state = found;
    }
  }

  Future<void> setPreset(M3ThemePreset preset) async {
    state = preset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('m3_theme_preset', preset.id);
  }
}

final m3ThemePresetProvider =
    StateNotifierProvider<M3PresetNotifier, M3ThemePreset>((ref) {
  return M3PresetNotifier();
});
