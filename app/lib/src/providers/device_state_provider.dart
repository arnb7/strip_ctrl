import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'transport_provider.dart';

class DeviceStateNotifier extends StateNotifier<DeviceState> {
  final CommandScheduler scheduler;

  DeviceStateNotifier(this.scheduler)
      : super(const DeviceState(deviceId: 'default', pinOrder: 'GRB')) {
    _loadSavedPinOrder();
  }

  Future<void> _loadSavedPinOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('pin_order');
      if (saved != null && saved.isNotEmpty) {
        state = state.copyWith(pinOrder: saved);
      } else {
        state = state.copyWith(pinOrder: 'GRB');
        await prefs.setString('pin_order', 'GRB');
      }
    } catch (_) {}
  }

  static (int, int, int) mapRgbForPinOrder(int r, int g, int b, String order) {
    switch (order.toUpperCase()) {
      case 'GRB':
        return (g, r, b);
      case 'RBG':
        return (r, b, g);
      case 'GBR':
        return (g, b, r);
      case 'BRG':
        return (b, r, g);
      case 'BGR':
        return (b, g, r);
      case 'RGB':
      default:
        return (r, g, b);
    }
  }

  Color get currentColor => Color.fromARGB(255, state.r, state.g, state.b);

  Future<void> _safeSubmit(LedCommand cmd) async {
    try {
      await scheduler.submit(cmd);
    } catch (_) {
      // Ignore transport errors if disconnected or in transition
    }
  }

  Future<void> setPower(bool on) async {
    state = state.copyWith(power: on);
    await _safeSubmit(PowerCommand(on));
  }

  Future<void> togglePower() async {
    await setPower(!state.power);
  }

  Future<void> setRgb(int r, int g, int b) async {
    state = state.copyWith(
      mode: ActiveLedMode.color,
      r: r,
      g: g,
      b: b,
    );
    final (tr, tg, tb) = state.trimmedRgb;
    final (mr, mg, mb) = mapRgbForPinOrder(tr, tg, tb, state.pinOrder);
    await _safeSubmit(ColorCommand(mr, mg, mb));
  }

  Future<void> sendMusicColor(int r, int g, int b) async {
    state = state.copyWith(
      mode: ActiveLedMode.color,
      r: r,
      g: g,
      b: b,
    );
    final (tr, tg, tb) = state.trimmedRgb;
    final (mr, mg, mb) = mapRgbForPinOrder(tr, tg, tb, state.pinOrder);
    await _safeSubmit(ColorCommand(mr, mg, mb, isMusic: true));
  }

  Future<void> sendDirectMusicFrame(int r, int g, int b,
      {bool useMusicByte = true}) async {
    final (tr, tg, tb) = state.whiteBalanceTrim.apply(r, g, b);
    final (mr, mg, mb) = mapRgbForPinOrder(tr, tg, tb, state.pinOrder);
    await _safeSubmit(ColorCommand(mr, mg, mb, isMusic: useMusicByte));
  }

  Future<void> setBrightness(int percent) async {
    state = state.copyWith(brightness: percent);
    await _safeSubmit(BrightnessCommand(percent));
  }

  Future<void> setWhite(int warm, int cold) async {
    state = state.copyWith(
      mode: ActiveLedMode.white,
      whiteWarm: warm,
      whiteCold: cold,
    );
    await _safeSubmit(WhiteCctCommand(warm, cold));
  }

  Future<void> setEffect(int effectIndex) async {
    state = state.copyWith(
      mode: ActiveLedMode.effect,
      effectIndex: effectIndex,
    );
    await _safeSubmit(EffectCommand(effectIndex));
  }

  Future<void> setSpeed(int speed) async {
    state = state.copyWith(speed: speed);
    await _safeSubmit(EffectSpeedCommand(speed));
  }

  Future<void> setPinOrder(String order) async {
    state = state.copyWith(pinOrder: order);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pin_order', order);
    } catch (_) {}

    const pinMap = <String, (int, int, int)>{
      'RGB': (1, 2, 3),
      'RBG': (1, 3, 2),
      'GRB': (2, 1, 3),
      'GBR': (2, 3, 1),
      'BRG': (3, 1, 2),
      'BGR': (3, 2, 1),
    };
    final seq = pinMap[order.toUpperCase()] ?? (2, 1, 3);
    await _safeSubmit(RgbOrderCommand(seq.$1, seq.$2, seq.$3));

    // Re-apply active color through new software mapping
    if (state.mode == ActiveLedMode.color) {
      final (tr, tg, tb) = state.trimmedRgb;
      final (mr, mg, mb) = mapRgbForPinOrder(tr, tg, tb, state.pinOrder);
      await _safeSubmit(ColorCommand(mr, mg, mb));
    }
  }

  Future<void> setWhiteBalanceTrim(WhiteBalanceTrim trim) async {
    state = state.copyWith(whiteBalanceTrim: trim);
    if (state.mode == ActiveLedMode.color) {
      final (tr, tg, tb) = state.trimmedRgb;
      final (mr, mg, mb) = mapRgbForPinOrder(tr, tg, tb, state.pinOrder);
      await _safeSubmit(ColorCommand(mr, mg, mb));
    }
  }

  Future<void> syncStripToApp() async {
    await _safeSubmit(PowerCommand(state.power));
    if (state.power) {
      if (state.mode == ActiveLedMode.color) {
        final (tr, tg, tb) = state.trimmedRgb;
        final (mr, mg, mb) = mapRgbForPinOrder(tr, tg, tb, state.pinOrder);
        await _safeSubmit(ColorCommand(mr, mg, mb));
      } else if (state.mode == ActiveLedMode.white) {
        await _safeSubmit(WhiteCctCommand(state.whiteWarm, state.whiteCold));
      } else if (state.mode == ActiveLedMode.effect) {
        await _safeSubmit(EffectCommand(state.effectIndex));
      }
      await _safeSubmit(BrightnessCommand(state.brightness));
      await _safeSubmit(EffectSpeedCommand(state.speed));
    }
  }

  void updateFromScene(LedScene scene) {
    state = state.copyWith(
      mode: scene.mode,
      r: scene.r,
      g: scene.g,
      b: scene.b,
      brightness: scene.brightness,
      whiteWarm: scene.whiteWarm,
      whiteCold: scene.whiteCold,
      effectIndex: scene.effectIndex,
      speed: scene.speed,
    );
    syncStripToApp();
  }
}

final deviceStateProvider =
    StateNotifierProvider<DeviceStateNotifier, DeviceState>((ref) {
  final scheduler = ref.watch(schedulerProvider);
  return DeviceStateNotifier(scheduler);
});
