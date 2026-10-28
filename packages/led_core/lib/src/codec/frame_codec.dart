import 'dart:typed_data';
import '../commands/led_command.dart';
import 'encryption.dart';

class FrameCodec {
  static const int headerByte = 0x7E;
  static const int footerByte = 0xEF;
  static const int unusedByte = 0xFF;

  /// Encodes a typed [LedCommand] into an exact 9-byte plain frame.
  static Uint8List encodePlain(LedCommand command) {
    switch (command) {
      case PowerCommand(:final on):
        final state = on ? 0x01 : 0x00;
        return Uint8List.fromList(<int>[
          headerByte,
          0x04,
          0x04,
          state,
          0x00,
          state,
          unusedByte,
          0x00,
          footerByte,
        ]);

      case BrightnessCommand(:final percent):
        return Uint8List.fromList(<int>[
          headerByte,
          0x04,
          0x01,
          percent,
          unusedByte,
          unusedByte,
          unusedByte,
          0x00,
          footerByte,
        ]);

      case ColorCommand(:final r, :final g, :final b, :final isMusic):
        return Uint8List.fromList(<int>[
          headerByte,
          0x07,
          0x05,
          0x03,
          r,
          g,
          b,
          isMusic ? 0x20 : 0x10,
          footerByte,
        ]);

      case WhiteCctCommand(:final warm, :final cold):
        return Uint8List.fromList(<int>[
          headerByte,
          0x06,
          0x05,
          0x02,
          warm,
          cold,
          unusedByte,
          0x08,
          footerByte,
        ]);

      case SingleColorCommand(:final level):
        return Uint8List.fromList(<int>[
          headerByte,
          0x05,
          0x05,
          0x01,
          level,
          unusedByte,
          unusedByte,
          0x08,
          footerByte,
        ]);

      case EffectCommand(:final effectIndex):
        final effectByte = (effectIndex + 0x80) & 0xFF;
        return Uint8List.fromList(<int>[
          headerByte,
          0x05,
          0x03,
          effectByte,
          0x03,
          unusedByte,
          unusedByte,
          0x00,
          footerByte,
        ]);

      case EffectSpeedCommand(:final speed):
        return Uint8List.fromList(<int>[
          headerByte,
          0x04,
          0x02,
          speed,
          unusedByte,
          unusedByte,
          unusedByte,
          0x00,
          footerByte,
        ]);

      case RgbOrderCommand(:final c1, :final c2, :final c3):
        return Uint8List.fromList(<int>[
          headerByte,
          0x06,
          0x81,
          c1,
          c2,
          c3,
          unusedByte,
          0x00,
          footerByte,
        ]);

      case ChannelEnableCommand(
          :final rgbOn,
          :final wOn,
          :final mode,
          :final enabled
        ):
        var flags = 0;
        if (rgbOn) flags |= 0xE0;
        if (wOn) flags |= 0x10;
        return Uint8List.fromList(<int>[
          headerByte,
          0x04,
          0x04,
          flags,
          mode,
          enabled ? 0x01 : 0x00,
          unusedByte,
          0x00,
          footerByte,
        ]);

      case MusicReactiveColorCommand(:final r, :final g, :final b):
        return Uint8List.fromList(<int>[
          headerByte,
          0x07,
          0x05,
          0x03,
          r,
          g,
          b,
          0x20,
          footerByte,
        ]);

      case DeviceClockCommand(
          :final hour,
          :final minute,
          :final second,
          :final weekday
        ):
        return Uint8List.fromList(<int>[
          headerByte,
          0x07,
          0x83,
          hour,
          minute,
          second,
          weekday,
          unusedByte,
          footerByte,
        ]);

      case ScheduleSlotCommand(
          :final hour,
          :final minute,
          :final second,
          :final mode,
          :final weeks
        ):
        return Uint8List.fromList(<int>[
          headerByte,
          0x08,
          0x82,
          hour,
          minute,
          second,
          mode,
          weeks,
          footerByte,
        ]);

      case CountdownCommand(:final secondsTimestamp, :final mode):
        final t0 = secondsTimestamp & 0xFF;
        final t1 = (secondsTimestamp >> 8) & 0xFF;
        final t2 = (secondsTimestamp >> 16) & 0xFF;
        return Uint8List.fromList(<int>[
          headerByte,
          0x07,
          0x76,
          t0,
          t1,
          t2,
          mode,
          unusedByte,
          footerByte,
        ]);

      case RawCommand(:final bytes):
        return Uint8List.fromList(bytes);
    }
  }

  /// Encodes a [command] ready for transmission over BLE GATT.
  /// If [isEncryptedDevice] is true and the command is eligible, encodes as 21-byte ciphertext.
  static Uint8List encode(LedCommand command,
      {bool isEncryptedDevice = false}) {
    final plain = encodePlain(command);
    if (!isEncryptedDevice) {
      return plain;
    }

    final cmdByte = plain[2];
    if (cmdByte == 1 || cmdByte == 3 || cmdByte == 4) {
      return ElkEncryption.encryptFrame(plain);
    }
    return plain;
  }

  /// Decodes a 9-byte plain frame into a recognized [LedCommand], or returns a [RawCommand].
  static LedCommand decodePlain(List<int> bytes) {
    if (bytes.length != 9 || bytes[0] != headerByte || bytes[8] != footerByte) {
      throw FormatException(
          'Invalid frame format: must be 9 bytes starting with 7E and ending with EF');
    }

    final cmd = bytes[2];
    switch (cmd) {
      case 0x04: // Power or Channel Enable
        if (bytes[1] == 0x04) {
          if (bytes[4] == 0x00 && (bytes[3] == bytes[5])) {
            return PowerCommand(bytes[3] == 0x01);
          } else {
            final flags = bytes[3];
            final rgbOn = (flags & 0xE0) != 0;
            final wOn = (flags & 0x10) != 0;
            return ChannelEnableCommand(
              rgbOn: rgbOn,
              wOn: wOn,
              mode: bytes[4],
              enabled: bytes[5] == 0x01,
            );
          }
        }
        break;

      case 0x01: // Brightness
        if (bytes[1] == 0x04) {
          return BrightnessCommand(bytes[3]);
        }
        break;

      case 0x02: // Speed
        if (bytes[1] == 0x04) {
          return EffectSpeedCommand(bytes[3]);
        }
        break;

      case 0x05: // Color, CCT, or Single Color
        if (bytes[3] == 0x03) {
          if (bytes[7] == 0x20) {
            return MusicReactiveColorCommand(bytes[4], bytes[5], bytes[6]);
          }
          return ColorCommand(bytes[4], bytes[5], bytes[6]);
        } else if (bytes[3] == 0x02) {
          return WhiteCctCommand(bytes[4], bytes[5]);
        } else if (bytes[3] == 0x01) {
          return SingleColorCommand(bytes[4]);
        }
        break;

      case 0x03: // Effect
        if (bytes[1] == 0x05 && bytes[4] == 0x03) {
          final effectIdx = (bytes[3] - 0x80) & 0xFF;
          return EffectCommand(effectIdx);
        }
        break;

      case 0x81: // Pin sequence
        if (bytes[1] == 0x06) {
          return RgbOrderCommand(bytes[3], bytes[4], bytes[5]);
        }
        break;

      case 0x83: // Device clock
        if (bytes[1] == 0x07) {
          return DeviceClockCommand(
            hour: bytes[3],
            minute: bytes[4],
            second: bytes[5],
            weekday: bytes[6],
          );
        }
        break;

      case 0x82: // Schedule slot
        if (bytes[1] == 0x08) {
          return ScheduleSlotCommand(
            hour: bytes[3],
            minute: bytes[4],
            second: bytes[5],
            mode: bytes[6],
            weeks: bytes[7],
          );
        }
        break;

      case 0x76: // Countdown
        if (bytes[1] == 0x07) {
          final ts = bytes[3] | (bytes[4] << 8) | (bytes[5] << 16);
          return CountdownCommand(secondsTimestamp: ts, mode: bytes[6]);
        }
        break;
    }

    return RawCommand(bytes);
  }
}
