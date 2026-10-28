import 'package:led_core/led_core.dart';
import 'package:test/test.dart';

void main() {
  group('EffectCatalog Tests', () {
    test('contains exactly 29 effects from Section 3.3', () {
      expect(EffectCatalog.effects.length, equals(29));
    });

    test('all effect indices are unique 0..28', () {
      final indices = EffectCatalog.effects.map((e) => e.index).toSet();
      expect(indices.length, equals(29));
      for (var i = 0; i < 29; i++) {
        expect(indices.contains(i), isTrue);
      }
    });

    test('effect protocolByte is (index + 0x80)', () {
      for (final effect in EffectCatalog.effects) {
        expect(effect.protocolByte, equals(effect.index + 0x80));
      }
    });

    test('verifies strobe classification for indices 21..28', () {
      for (var i = 0; i <= 20; i++) {
        expect(EffectCatalog.byIndex(i)!.isStrobe, isFalse);
      }
      for (var i = 21; i <= 28; i++) {
        expect(EffectCatalog.byIndex(i)!.isStrobe, isTrue);
      }
    });

    test('search and category filtering work correctly', () {
      final strobes = EffectCatalog.byCategory(EffectCategory.strobe);
      expect(strobes.length, equals(8));

      final cyanSearch = EffectCatalog.search('cyan');
      expect(cyanSearch.length,
          equals(3)); // Static Cyan, Cyan Gradual, Cyan Strobe
    });
  });

  group('DeviceState & WhiteBalanceTrim Tests', () {
    test('white-balance trim scales channels accurately', () {
      const trim = WhiteBalanceTrim(r: 1.0, g: 0.8, b: 0.5);
      final (r, g, b) = trim.apply(200, 200, 200);
      expect(r, equals(200));
      expect(g, equals(160));
      expect(b, equals(100));
    });

    test('DeviceState copyWith and trimmedRgb property', () {
      final state = const DeviceState(
        deviceId: 'TEST_ADDR',
        r: 255,
        g: 255,
        b: 255,
        whiteBalanceTrim: WhiteBalanceTrim(r: 0.5, g: 1.0, b: 0.0),
      );

      final (r, g, b) = state.trimmedRgb;
      expect(r, equals(128));
      expect(g, equals(255));
      expect(b, equals(0));

      final updated = state.copyWith(brightness: 42);
      expect(updated.brightness, equals(42));
      expect(updated.deviceId, equals('TEST_ADDR'));
    });

    test('DeviceState JSON serialization round-trip', () {
      const state = DeviceState(
        deviceId: 'TEST_ADDR',
        power: false,
        mode: ActiveLedMode.effect,
        r: 10,
        g: 20,
        b: 30,
        brightness: 75,
        whiteWarm: 50,
        whiteCold: 60,
        effectIndex: 9,
        speed: 40,
        pinOrder: 'RBG',
        whiteBalanceTrim: WhiteBalanceTrim(r: 0.9, g: 0.9, b: 0.9),
        isEncrypted: true,
      );

      final json = state.toJson();
      final restored = DeviceState.fromJson(json);
      expect(restored, equals(state));
    });

    test('LedScene and LedSchedule JSON round-trips', () {
      const scene = LedScene(
        id: 'scene_1',
        name: 'Chill Blue',
        mode: ActiveLedMode.color,
        r: 0,
        g: 100,
        b: 255,
        brightness: 60,
        isFavorite: true,
      );
      expect(LedScene.fromJson(scene.toJson()), equals(scene));

      const schedule = LedSchedule(
        id: 'sched_1',
        label: 'Evening Off',
        hour: 23,
        minute: 30,
        action: ScheduleAction.turnOff,
      );
      expect(LedSchedule.fromJson(schedule.toJson()), equals(schedule));
    });
  });
}
