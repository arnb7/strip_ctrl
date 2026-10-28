import 'package:led_core/led_core.dart';
import 'package:test/test.dart';

void main() {
  group('FrameCodec Section 3 Test Vectors', () {
    test('power on -> 7E 04 04 01 00 01 FF 00 EF', () {
      final bytes = FrameCodec.encodePlain(const PowerCommand(true));
      expect(bytes, [0x7E, 0x04, 0x04, 0x01, 0x00, 0x01, 0xFF, 0x00, 0xEF]);
    });

    test('power off -> 7E 04 04 00 00 00 FF 00 EF', () {
      final bytes = FrameCodec.encodePlain(const PowerCommand(false));
      expect(bytes, [0x7E, 0x04, 0x04, 0x00, 0x00, 0x00, 0xFF, 0x00, 0xEF]);
    });

    test('brightness 50 -> 7E 04 01 32 FF FF FF 00 EF', () {
      final bytes = FrameCodec.encodePlain(const BrightnessCommand(50));
      expect(bytes, [0x7E, 0x04, 0x01, 0x32, 0xFF, 0xFF, 0xFF, 0x00, 0xEF]);
    });

    test('rgb red -> 7E 07 05 03 FF 00 00 10 EF', () {
      final bytes = FrameCodec.encodePlain(const ColorCommand(255, 0, 0));
      expect(bytes, [0x7E, 0x07, 0x05, 0x03, 0xFF, 0x00, 0x00, 0x10, 0xEF]);
    });

    test('effect 3 (Static Cyan) -> 7E 05 03 83 03 FF FF 00 EF', () {
      final bytes = FrameCodec.encodePlain(const EffectCommand(3));
      expect(bytes, [0x7E, 0x05, 0x03, 0x83, 0x03, 0xFF, 0xFF, 0x00, 0xEF]);
    });

    test('effect 28 (White Strobe Flash) -> 7E 05 03 9C 03 FF FF 00 EF', () {
      final bytes = FrameCodec.encodePlain(const EffectCommand(28));
      expect(bytes, [0x7E, 0x05, 0x03, 0x9C, 0x03, 0xFF, 0xFF, 0x00, 0xEF]);
    });

    test('effect speed 80 -> 7E 04 02 50 FF FF FF 00 EF', () {
      final bytes = FrameCodec.encodePlain(const EffectSpeedCommand(80));
      expect(bytes, [0x7E, 0x04, 0x02, 0x50, 0xFF, 0xFF, 0xFF, 0x00, 0xEF]);
    });

    test('rgb channel order GRB (2, 1, 3) -> 7E 06 81 02 01 03 FF 00 EF', () {
      final bytes = FrameCodec.encodePlain(const RgbOrderCommand(2, 1, 3));
      expect(bytes, [0x7E, 0x06, 0x81, 0x02, 0x01, 0x03, 0xFF, 0x00, 0xEF]);
    });

    test('music-reactive color -> 7E 07 05 03 RR GG BB 20 EF', () {
      final bytes =
          FrameCodec.encodePlain(const MusicReactiveColorCommand(0, 255, 0));
      expect(bytes, [0x7E, 0x07, 0x05, 0x03, 0x00, 0xFF, 0x00, 0x20, 0xEF]);
    });

    test('CCT warm/cold white -> 7E 06 05 02 WW CC FF 08 EF', () {
      final bytes = FrameCodec.encodePlain(const WhiteCctCommand(100, 200));
      expect(bytes, [0x7E, 0x06, 0x05, 0x02, 0x64, 0xC8, 0xFF, 0x08, 0xEF]);
    });

    test('channel enable RGB on, W off -> 7E 04 04 E0 00 01 FF 00 EF', () {
      final bytes = FrameCodec.encodePlain(const ChannelEnableCommand(
        rgbOn: true,
        wOn: false,
        mode: 0,
        enabled: true,
      ));
      expect(bytes, [0x7E, 0x04, 0x04, 0xE0, 0x00, 0x01, 0xFF, 0x00, 0xEF]);
    });
  });

  group('FrameCodec Plain Decode Round-Trip', () {
    test('round-trips power, brightness, color, effect, speed, rgb-order', () {
      final commands = <LedCommand>[
        const PowerCommand(true),
        const PowerCommand(false),
        const BrightnessCommand(85),
        const ColorCommand(12, 34, 56),
        const WhiteCctCommand(50, 60),
        const EffectCommand(15),
        const EffectSpeedCommand(99),
        const RgbOrderCommand(1, 2, 3),
        const MusicReactiveColorCommand(10, 20, 30),
      ];

      for (final cmd in commands) {
        final encoded = FrameCodec.encodePlain(cmd);
        final decoded = FrameCodec.decodePlain(encoded);
        expect(decoded, equals(cmd));
      }
    });
  });
}
