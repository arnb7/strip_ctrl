import 'package:meta/meta.dart';
import 'device_state.dart';

@immutable
class LedScene {
  final String id;
  final String name;
  final ActiveLedMode mode;
  final int r;
  final int g;
  final int b;
  final int brightness;
  final int whiteWarm;
  final int whiteCold;
  final int effectIndex;
  final int speed;
  final bool isFavorite;

  const LedScene({
    required this.id,
    required this.name,
    this.mode = ActiveLedMode.color,
    this.r = 255,
    this.g = 0,
    this.b = 0,
    this.brightness = 100,
    this.whiteWarm = 128,
    this.whiteCold = 128,
    this.effectIndex = 0,
    this.speed = 80,
    this.isFavorite = false,
  });

  factory LedScene.fromDeviceState({
    required String id,
    required String name,
    required DeviceState state,
    bool isFavorite = false,
  }) {
    return LedScene(
      id: id,
      name: name,
      mode: state.mode,
      r: state.r,
      g: state.g,
      b: state.b,
      brightness: state.brightness,
      whiteWarm: state.whiteWarm,
      whiteCold: state.whiteCold,
      effectIndex: state.effectIndex,
      speed: state.speed,
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode.name,
        'r': r,
        'g': g,
        'b': b,
        'brightness': brightness,
        'whiteWarm': whiteWarm,
        'whiteCold': whiteCold,
        'effectIndex': effectIndex,
        'speed': speed,
        'isFavorite': isFavorite,
      };

  factory LedScene.fromJson(Map<String, dynamic> json) => LedScene(
        id: json['id'] as String,
        name: json['name'] as String,
        mode: ActiveLedMode.values
            .byName(json['mode'] as String? ?? ActiveLedMode.color.name),
        r: json['r'] as int? ?? 255,
        g: json['g'] as int? ?? 0,
        b: json['b'] as int? ?? 0,
        brightness: json['brightness'] as int? ?? 100,
        whiteWarm: json['whiteWarm'] as int? ?? 128,
        whiteCold: json['whiteCold'] as int? ?? 128,
        effectIndex: json['effectIndex'] as int? ?? 0,
        speed: json['speed'] as int? ?? 80,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is LedScene &&
      other.id == id &&
      other.name == name &&
      other.mode == mode &&
      other.r == r &&
      other.g == g &&
      other.b == b &&
      other.brightness == brightness &&
      other.whiteWarm == whiteWarm &&
      other.whiteCold == whiteCold &&
      other.effectIndex == effectIndex &&
      other.speed == speed &&
      other.isFavorite == isFavorite;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        mode,
        r,
        g,
        b,
        brightness,
        whiteWarm,
        whiteCold,
        effectIndex,
        speed,
        isFavorite,
      );
}
