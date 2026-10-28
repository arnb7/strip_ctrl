import 'package:meta/meta.dart';

enum ScheduleAction {
  turnOn,
  turnOff,
  applyScene,
}

enum ScheduleEngine {
  phoneSide,
  onDevice,
}

@immutable
class LedSchedule {
  final String id;
  final String label;
  final bool enabled;
  final int hour; // 0..23
  final int minute; // 0..59
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday
  final ScheduleAction action;
  final String? sceneId;
  final int fadeDurationSeconds;
  final ScheduleEngine engine;

  const LedSchedule({
    required this.id,
    required this.label,
    this.enabled = true,
    required this.hour,
    required this.minute,
    this.daysOfWeek = const <int>[1, 2, 3, 4, 5, 6, 7],
    this.action = ScheduleAction.turnOn,
    this.sceneId,
    this.fadeDurationSeconds = 0,
    this.engine = ScheduleEngine.phoneSide,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
        'daysOfWeek': daysOfWeek,
        'action': action.name,
        'sceneId': sceneId,
        'fadeDurationSeconds': fadeDurationSeconds,
        'engine': engine.name,
      };

  factory LedSchedule.fromJson(Map<String, dynamic> json) => LedSchedule(
        id: json['id'] as String,
        label: json['label'] as String,
        enabled: json['enabled'] as bool? ?? true,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const <int>[1, 2, 3, 4, 5, 6, 7],
        action: ScheduleAction.values
            .byName(json['action'] as String? ?? ScheduleAction.turnOn.name),
        sceneId: json['sceneId'] as String?,
        fadeDurationSeconds: json['fadeDurationSeconds'] as int? ?? 0,
        engine: ScheduleEngine.values
            .byName(json['engine'] as String? ?? ScheduleEngine.phoneSide.name),
      );

  @override
  bool operator ==(Object other) =>
      other is LedSchedule &&
      other.id == id &&
      other.label == label &&
      other.enabled == enabled &&
      other.hour == hour &&
      other.minute == minute &&
      other.action == action &&
      other.sceneId == sceneId &&
      other.fadeDurationSeconds == fadeDurationSeconds &&
      other.engine == engine;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        enabled,
        hour,
        minute,
        action,
        sceneId,
        fadeDurationSeconds,
        engine,
      );
}
