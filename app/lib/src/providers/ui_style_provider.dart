import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UiStyle {
  workspace2,
  expressiveM3,
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
