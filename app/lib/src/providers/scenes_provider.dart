import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<LedScene> defaultScenes = <LedScene>[
  LedScene(
    id: 'preset_rainbow',
    name: 'Rainbow',
    mode: ActiveLedMode.effect,
    effectIndex: 10, // Seven Color Cross Fade (Hardware Rainbow! Persists on app exit)
    speed: 85,
    brightness: 100,
    isFavorite: true,
  ),
  LedScene(
    id: 'preset_rainbow_cycle',
    name: 'Rainbow Cycle',
    mode: ActiveLedMode.effect,
    effectIndex: 8, // Seven Color Jumping Change
    speed: 80,
    brightness: 100,
    isFavorite: true,
  ),
  LedScene(
    id: 'preset_rgb_fade',
    name: 'RGB Fade',
    mode: ActiveLedMode.effect,
    effectIndex: 9, // Three Color Cross Fade
    speed: 75,
    brightness: 100,
    isFavorite: true,
  ),
  LedScene(
    id: 'preset_rainbow_strobe',
    name: 'Rainbow Strobe',
    mode: ActiveLedMode.effect,
    effectIndex: 21, // Seven Color Strobe Flash
    speed: 90,
    brightness: 100,
  ),
  LedScene(
    id: 'preset_movie_night',
    name: 'Movie Night',
    mode: ActiveLedMode.color,
    r: 20,
    g: 30,
    b: 80,
    brightness: 35,
    isFavorite: true,
  ),
  LedScene(
    id: 'preset_sunset_glow',
    name: 'Sunset Glow',
    mode: ActiveLedMode.color,
    r: 255,
    g: 90,
    b: 0,
    brightness: 80,
    isFavorite: true,
  ),
  LedScene(
    id: 'preset_forest_rain',
    name: 'Forest Rain',
    mode: ActiveLedMode.color,
    r: 0,
    g: 210,
    b: 70,
    brightness: 60,
  ),
  LedScene(
    id: 'preset_ocean_depth',
    name: 'Ocean Depth',
    mode: ActiveLedMode.color,
    r: 0,
    g: 120,
    b: 255,
    brightness: 75,
    isFavorite: true,
  ),
  LedScene(
    id: 'preset_party_mode',
    name: 'Party Mode',
    mode: ActiveLedMode.effect,
    effectIndex: 8, // Seven Color Jumping
    speed: 95,
    brightness: 100,
    isFavorite: true,
  ),
  LedScene(
    id: 'preset_cozy_hearth',
    name: 'Cozy Hearth',
    mode: ActiveLedMode.color,
    r: 255,
    g: 110,
    b: 15,
    brightness: 65,
  ),
  LedScene(
    id: 'preset_cyber_gaming',
    name: 'Cyber Gaming',
    mode: ActiveLedMode.color,
    r: 255,
    g: 0,
    b: 180,
    brightness: 90,
    isFavorite: true,
  ),
  LedScene(
    id: 'preset_candle_light',
    name: 'Candle Light',
    mode: ActiveLedMode.white,
    whiteWarm: 240,
    whiteCold: 25,
    brightness: 45,
  ),
];

class ScenesNotifier extends StateNotifier<List<LedScene>> {
  static const _storageKey = 'stripctl_saved_scenes';

  ScenesNotifier() : super(defaultScenes) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((e) => LedScene.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          final existingIds = list.map((s) => s.id).toSet();
          final missingDefaults =
              defaultScenes.where((d) => !existingIds.contains(d.id)).toList();
          state = [...missingDefaults, ...list];
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(state.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (_) {}
  }

  void addScene(LedScene scene) {
    state = [...state, scene];
    _persist();
  }

  void removeScene(String id) {
    state = state.where((s) => s.id != id).toList();
    _persist();
  }

  void toggleFavorite(String id) {
    state = state.map((s) {
      if (s.id == id) {
        return LedScene(
          id: s.id,
          name: s.name,
          mode: s.mode,
          r: s.r,
          g: s.g,
          b: s.b,
          brightness: s.brightness,
          whiteWarm: s.whiteWarm,
          whiteCold: s.whiteCold,
          effectIndex: s.effectIndex,
          speed: s.speed,
          isFavorite: !s.isFavorite,
        );
      }
      return s;
    }).toList();
    _persist();
  }

  String exportJson() {
    return jsonEncode(state.map((s) => s.toJson()).toList());
  }

  bool importJson(String jsonStr) {
    try {
      final list = (jsonDecode(jsonStr) as List<dynamic>)
          .map((e) => LedScene.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
      _persist();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final scenesProvider =
    StateNotifierProvider<ScenesNotifier, List<LedScene>>((ref) {
  return ScenesNotifier();
});
