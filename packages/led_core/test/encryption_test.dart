import 'dart:typed_data';
import 'package:led_core/led_core.dart';
import 'package:test/test.dart';

void main() {
  group('ElkEncryption Section 4 Known-Answer Test', () {
    final fixedR = <int>[
      0x00,
      0x01,
      0x02,
      0x03,
      0x04,
      0x05,
      0x06,
      0x07,
      0x08,
      0x09,
      0x0A,
      0x0B
    ];

    test('verifies keystream calculation matches spec KS', () {
      final ks = ElkEncryption.computeKeystream(fixedR);
      expect(
        ks,
        equals(Uint8List.fromList(
            <int>[0x3B, 0x77, 0xA2, 0x91, 0x04, 0x11, 0x1C, 0xAF, 0x32])),
      );
    });

    test('encrypts power-on with fixed R into exact 21-byte C vector', () {
      // plain power-on: 7E 04 04 01 00 01 FF 00 EF
      final plain = FrameCodec.encodePlain(const PowerCommand(true));

      final ciphertext = ElkEncryption.encryptFrame(plain, fixedRandom: fixedR);

      final expectedC = <int>[
        0x91,
        0x73,
        0xA6,
        0x90,
        0x04,
        0x10,
        0xE3,
        0xAF,
        0x67,
        0x2A,
        0x7E,
        0xC3,
        0x97,
        0x37,
        0xDB,
        0x43,
        0xE7,
        0x83,
        0x18,
        0x56,
        0xAD
      ];

      expect(ciphertext, equals(Uint8List.fromList(expectedC)));
    });

    test('decrypts 21-byte C vector back to original 9-byte plain frame', () {
      final c = Uint8List.fromList(<int>[
        0x91,
        0x73,
        0xA6,
        0x90,
        0x04,
        0x10,
        0xE3,
        0xAF,
        0x67,
        0x2A,
        0x7E,
        0xC3,
        0x97,
        0x37,
        0xDB,
        0x43,
        0xE7,
        0x83,
        0x18,
        0x56,
        0xAD
      ]);

      final recovered = ElkEncryption.decryptFrame(c);
      expect(
        recovered,
        equals(Uint8List.fromList(
            <int>[0x7E, 0x04, 0x04, 0x01, 0x00, 0x01, 0xFF, 0x00, 0xEF])),
      );

      final command = FrameCodec.decodePlain(recovered);
      expect(command, equals(const PowerCommand(true)));
    });

    test('random encryption round-trip preserves command across 50 iterations',
        () {
      final commands = <LedCommand>[
        const PowerCommand(true),
        const PowerCommand(false),
        const BrightnessCommand(75),
        const EffectCommand(12),
      ];

      for (final cmd in commands) {
        for (var i = 0; i < 50; i++) {
          final plain = FrameCodec.encodePlain(cmd);
          final encrypted = ElkEncryption.encryptFrame(plain);
          expect(encrypted.length, equals(21));

          final decrypted = ElkEncryption.decryptFrame(encrypted);
          expect(decrypted, equals(plain));
          expect(FrameCodec.decodePlain(decrypted), equals(cmd));
        }
      }
    });

    test('FrameCodec.encode routes encryption only for CMD 1, 3, 4', () {
      // CMD 4 (Power) -> encrypted
      final encPower =
          FrameCodec.encode(const PowerCommand(true), isEncryptedDevice: true);
      expect(encPower.length, equals(21));

      // CMD 1 (Brightness) -> encrypted
      final encBright = FrameCodec.encode(const BrightnessCommand(50),
          isEncryptedDevice: true);
      expect(encBright.length, equals(21));

      // CMD 3 (Effect) -> encrypted
      final encEffect =
          FrameCodec.encode(const EffectCommand(7), isEncryptedDevice: true);
      expect(encEffect.length, equals(21));

      // CMD 5 (Color) -> NOT encrypted even if isEncryptedDevice is true
      final plainColor = FrameCodec.encode(const ColorCommand(255, 128, 0),
          isEncryptedDevice: true);
      expect(plainColor.length, equals(9));
      expect(plainColor[0], equals(0x7E));
      expect(plainColor[8], equals(0xEF));

      // CMD 0x81 (Pin sequence) -> NOT encrypted
      final plainPin = FrameCodec.encode(const RgbOrderCommand(2, 1, 3),
          isEncryptedDevice: true);
      expect(plainPin.length, equals(9));
    });
  });
}
