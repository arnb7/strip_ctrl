import 'package:meta/meta.dart';

enum ActiveLedMode {
  color,
  white,
  effect,
  music,
}

@immutable
class WhiteBalanceTrim {
  final double r; // 0.0 .. 1.0 (0% .. 100%)
  final double g;
  final double b;

  const WhiteBalanceTrim({
    this.r = 1.0,
    this.g = 1.0,
    this.b = 1.0,
  })  : assert(r >= 0.0 && r <= 1.0),
        assert(g >= 0.0 && g <= 1.0),
        assert(b >= 0.0 && b <= 1.0);

  (int, int, int) apply(int rawR, int rawG, int rawB) {
    return (
      (rawR * r).round().clamp(0, 255),
      (rawG * g).round().clamp(0, 255),
      (rawB * b).round().clamp(0, 255),
    );
  }

  Map<String, dynamic> toJson() => {'r': r, 'g': g, 'b': b};

  factory WhiteBalanceTrim.fromJson(Map<String, dynamic> json) =>
      WhiteBalanceTrim(
        r: (json['r'] as num?)?.toDouble() ?? 1.0,
        g: (json['g'] as num?)?.toDouble() ?? 1.0,
        b: (json['b'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  bool operator ==(Object other) =>
      other is WhiteBalanceTrim && other.r == r && other.g == g && other.b == b;

  @override
  int get hashCode => Object.hash(r, g, b);
}

@immutable
class DeviceState {
  final String deviceId;
  final bool power;
  final ActiveLedMode mode;
  final int r;
  final int g;
  final int b;
  final int brightness; // 0..100
  final int whiteWarm; // 0..255
  final int whiteCold; // 0..255
  final int effectIndex; // 0..28
  final int speed; // 0..100
  final String pinOrder; // e.g. "GRB"
  final WhiteBalanceTrim whiteBalanceTrim;
  final bool isEncrypted;

  const DeviceState({
    required this.deviceId,
    this.power = true,
    this.mode = ActiveLedMode.color,
    this.r = 255,
    this.g = 0,
    this.b = 0,
    this.brightness = 100,
    this.whiteWarm = 128,
    this.whiteCold = 128,
    this.effectIndex = 0,
    this.speed = 80,
    this.pinOrder = 'GRB',
    this.whiteBalanceTrim = const WhiteBalanceTrim(),
    this.isEncrypted = false,
  });

  DeviceState copyWith({
    String? deviceId,
    bool? power,
    ActiveLedMode? mode,
    int? r,
    int? g,
    int? b,
    int? brightness,
    int? whiteWarm,
    int? whiteCold,
    int? effectIndex,
    int? speed,
    String? pinOrder,
    WhiteBalanceTrim? whiteBalanceTrim,
    bool? isEncrypted,
  }) {
    return DeviceState(
      deviceId: deviceId ?? this.deviceId,
      power: power ?? this.power,
      mode: mode ?? this.mode,
      r: r ?? this.r,
      g: g ?? this.g,
      b: b ?? this.b,
      brightness: brightness ?? this.brightness,
      whiteWarm: whiteWarm ?? this.whiteWarm,
      whiteCold: whiteCold ?? this.whiteCold,
      effectIndex: effectIndex ?? this.effectIndex,
      speed: speed ?? this.speed,
      pinOrder: pinOrder ?? this.pinOrder,
      whiteBalanceTrim: whiteBalanceTrim ?? this.whiteBalanceTrim,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }

  /// Calculates actual RGB bytes to transmit, applying white-balance trim.
  (int, int, int) get trimmedRgb => whiteBalanceTrim.apply(r, g, b);

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'power': power,
        'mode': mode.name,
        'r': r,
        'g': g,
        'b': b,
        'brightness': brightness,
        'whiteWarm': whiteWarm,
        'whiteCold': whiteCold,
        'effectIndex': effectIndex,
        'speed': speed,
        'pinOrder': pinOrder,
        'whiteBalanceTrim': whiteBalanceTrim.toJson(),
        'isEncrypted': isEncrypted,
      };

  factory DeviceState.fromJson(Map<String, dynamic> json) => DeviceState(
        deviceId: json['deviceId'] as String,
        power: json['power'] as bool? ?? true,
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
        pinOrder: json['pinOrder'] as String? ?? 'GRB',
        whiteBalanceTrim: json['whiteBalanceTrim'] != null
            ? WhiteBalanceTrim.fromJson(
                json['whiteBalanceTrim'] as Map<String, dynamic>)
            : const WhiteBalanceTrim(),
        isEncrypted: json['isEncrypted'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is DeviceState &&
      other.deviceId == deviceId &&
      other.power == power &&
      other.mode == mode &&
      other.r == r &&
      other.g == g &&
      other.b == b &&
      other.brightness == brightness &&
      other.whiteWarm == whiteWarm &&
      other.whiteCold == whiteCold &&
      other.effectIndex == effectIndex &&
      other.speed == speed &&
      other.pinOrder == pinOrder &&
      other.whiteBalanceTrim == whiteBalanceTrim &&
      other.isEncrypted == isEncrypted;

  @override
  int get hashCode => Object.hash(
        deviceId,
        power,
        mode,
        r,
        g,
        b,
        brightness,
        whiteWarm,
        whiteCold,
        effectIndex,
        speed,
        pinOrder,
        whiteBalanceTrim,
        isEncrypted,
      );
}
