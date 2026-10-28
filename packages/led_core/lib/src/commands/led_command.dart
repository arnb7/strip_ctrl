import 'package:meta/meta.dart';

@immutable
sealed class LedCommand {
  const LedCommand();

  /// Optional coalescing key. Commands sharing the same non-null key replace
  /// prior un-dispatched commands in the scheduler queue (latest-wins).
  String? get coalescingKey => null;

  /// Whether this command type is eligible for encryption on ELK-* devices.
  /// (Only CMD byte 1, 3, or 4).
  bool get canBeEncrypted => false;
}

final class PowerCommand extends LedCommand {
  final bool on;
  const PowerCommand(this.on);

  @override
  String? get coalescingKey => 'power';

  @override
  bool get canBeEncrypted => true;

  @override
  bool operator ==(Object other) => other is PowerCommand && other.on == on;

  @override
  int get hashCode => on.hashCode;

  @override
  String toString() => 'PowerCommand(on: $on)';
}

final class BrightnessCommand extends LedCommand {
  final int percent; // 0..100
  final int lightMode; // default 255

  const BrightnessCommand(this.percent, {this.lightMode = 255})
      : assert(percent >= 0 && percent <= 100, 'percent must be 0..100');

  @override
  String? get coalescingKey => 'brightness';

  @override
  bool get canBeEncrypted => true;

  @override
  bool operator ==(Object other) =>
      other is BrightnessCommand &&
      other.percent == percent &&
      other.lightMode == lightMode;

  @override
  int get hashCode => Object.hash(percent, lightMode);

  @override
  String toString() =>
      'BrightnessCommand(percent: $percent, lightMode: $lightMode)';
}

final class ColorCommand extends LedCommand {
  final int r;
  final int g;
  final int b;
  final bool isMusic;

  const ColorCommand(this.r, this.g, this.b, {this.isMusic = false})
      : assert(r >= 0 && r <= 255),
        assert(g >= 0 && g <= 255),
        assert(b >= 0 && b <= 255);

  @override
  String? get coalescingKey => isMusic ? 'music-color' : 'color';

  @override
  bool get canBeEncrypted => false;

  @override
  bool operator ==(Object other) =>
      other is ColorCommand &&
      other.r == r &&
      other.g == g &&
      other.b == b &&
      other.isMusic == isMusic;

  @override
  int get hashCode => Object.hash(r, g, b, isMusic);

  @override
  String toString() => 'ColorCommand(r: $r, g: $g, b: $b, isMusic: $isMusic)';
}

final class WhiteCctCommand extends LedCommand {
  final int warm; // 0..255
  final int cold; // 0..255

  const WhiteCctCommand(this.warm, this.cold)
      : assert(warm >= 0 && warm <= 255),
        assert(cold >= 0 && cold <= 255);

  @override
  String? get coalescingKey => 'color';

  @override
  bool operator ==(Object other) =>
      other is WhiteCctCommand && other.warm == warm && other.cold == cold;

  @override
  int get hashCode => Object.hash(warm, cold);

  @override
  String toString() => 'WhiteCctCommand(warm: $warm, cold: $cold)';
}

final class SingleColorCommand extends LedCommand {
  final int level; // 0..255

  const SingleColorCommand(this.level) : assert(level >= 0 && level <= 255);

  @override
  String? get coalescingKey => 'brightness';

  @override
  bool operator ==(Object other) =>
      other is SingleColorCommand && other.level == level;

  @override
  int get hashCode => level.hashCode;

  @override
  String toString() => 'SingleColorCommand(level: $level)';
}

final class EffectCommand extends LedCommand {
  final int effectIndex; // 0..28

  const EffectCommand(this.effectIndex)
      : assert(effectIndex >= 0 && effectIndex <= 127);

  @override
  String? get coalescingKey => 'effect';

  @override
  bool get canBeEncrypted => true;

  @override
  bool operator ==(Object other) =>
      other is EffectCommand && other.effectIndex == effectIndex;

  @override
  int get hashCode => effectIndex.hashCode;

  @override
  String toString() => 'EffectCommand(effectIndex: $effectIndex)';
}

final class EffectSpeedCommand extends LedCommand {
  final int speed; // 0..100

  const EffectSpeedCommand(this.speed) : assert(speed >= 0 && speed <= 100);

  @override
  String? get coalescingKey => 'effect_speed';

  @override
  bool operator ==(Object other) =>
      other is EffectSpeedCommand && other.speed == speed;

  @override
  int get hashCode => speed.hashCode;

  @override
  String toString() => 'EffectSpeedCommand(speed: $speed)';
}

final class RgbOrderCommand extends LedCommand {
  final int c1; // 1..3
  final int c2; // 1..3
  final int c3; // 1..3

  const RgbOrderCommand(this.c1, this.c2, this.c3)
      : assert(c1 >= 1 && c1 <= 3),
        assert(c2 >= 1 && c2 <= 3),
        assert(c3 >= 1 && c3 <= 3);

  @override
  bool operator ==(Object other) =>
      other is RgbOrderCommand &&
      other.c1 == c1 &&
      other.c2 == c2 &&
      other.c3 == c3;

  @override
  int get hashCode => Object.hash(c1, c2, c3);

  @override
  String toString() => 'RgbOrderCommand($c1, $c2, $c3)';
}

final class ChannelEnableCommand extends LedCommand {
  final bool rgbOn;
  final bool wOn;
  final int mode; // 0..4
  final bool enabled;

  const ChannelEnableCommand({
    required this.rgbOn,
    required this.wOn,
    required this.mode,
    required this.enabled,
  });

  @override
  bool get canBeEncrypted => true;

  @override
  bool operator ==(Object other) =>
      other is ChannelEnableCommand &&
      other.rgbOn == rgbOn &&
      other.wOn == wOn &&
      other.mode == mode &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(rgbOn, wOn, mode, enabled);

  @override
  String toString() =>
      'ChannelEnableCommand(rgbOn: $rgbOn, wOn: $wOn, mode: $mode, enabled: $enabled)';
}

final class MusicReactiveColorCommand extends LedCommand {
  final int r;
  final int g;
  final int b;

  const MusicReactiveColorCommand(this.r, this.g, this.b)
      : assert(r >= 0 && r <= 255),
        assert(g >= 0 && g <= 255),
        assert(b >= 0 && b <= 255);

  @override
  String? get coalescingKey => 'color';

  @override
  bool operator ==(Object other) =>
      other is MusicReactiveColorCommand &&
      other.r == r &&
      other.g == g &&
      other.b == b;

  @override
  int get hashCode => Object.hash(r, g, b);

  @override
  String toString() => 'MusicReactiveColorCommand(r: $r, g: $g, b: $b)';
}

final class DeviceClockCommand extends LedCommand {
  final int hour;
  final int minute;
  final int second;
  final int weekday; // 1..7 or 0..6

  const DeviceClockCommand({
    required this.hour,
    required this.minute,
    required this.second,
    required this.weekday,
  });

  @override
  bool operator ==(Object other) =>
      other is DeviceClockCommand &&
      other.hour == hour &&
      other.minute == minute &&
      other.second == second &&
      other.weekday == weekday;

  @override
  int get hashCode => Object.hash(hour, minute, second, weekday);

  @override
  String toString() =>
      'DeviceClockCommand(hour: $hour, min: $minute, sec: $second, wd: $weekday)';
}

final class ScheduleSlotCommand extends LedCommand {
  final int hour;
  final int minute;
  final int second;
  final int mode; // 0 = on, 1 = off
  final int weeks; // bit 7 = enabled, bits 0..6 = days

  const ScheduleSlotCommand({
    required this.hour,
    required this.minute,
    required this.second,
    required this.mode,
    required this.weeks,
  });

  @override
  bool operator ==(Object other) =>
      other is ScheduleSlotCommand &&
      other.hour == hour &&
      other.minute == minute &&
      other.second == second &&
      other.mode == mode &&
      other.weeks == weeks;

  @override
  int get hashCode => Object.hash(hour, minute, second, mode, weeks);

  @override
  String toString() =>
      'ScheduleSlotCommand(hour: $hour, min: $minute, sec: $second, mode: $mode, weeks: $weeks)';
}

final class CountdownCommand extends LedCommand {
  final int secondsTimestamp; // 24-bit
  final int mode;

  const CountdownCommand({
    required this.secondsTimestamp,
    required this.mode,
  });

  @override
  bool operator ==(Object other) =>
      other is CountdownCommand &&
      other.secondsTimestamp == secondsTimestamp &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(secondsTimestamp, mode);

  @override
  String toString() =>
      'CountdownCommand(timestamp: $secondsTimestamp, mode: $mode)';
}

final class RawCommand extends LedCommand {
  final List<int> bytes;

  const RawCommand(this.bytes)
      : assert(bytes.length == 9, 'Raw command must be exactly 9 bytes');

  @override
  bool operator ==(Object other) =>
      other is RawCommand &&
      other.bytes.length == bytes.length &&
      other.bytes.every((b) => bytes.contains(b));

  @override
  int get hashCode => Object.hashAll(bytes);

  @override
  String toString() => 'RawCommand($bytes)';
}
