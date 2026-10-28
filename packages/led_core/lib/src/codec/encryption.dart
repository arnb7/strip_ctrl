import 'dart:math';
import 'dart:typed_data';

class ElkEncryption {
  static const List<int> key = <int>[
    0x2A,
    0x7F,
    0xC1,
    0x94,
    0x33,
    0xDE,
    0x45,
    0xE0,
    0x8B,
    0x11,
    0x5C,
    0xA6,
    0x09,
    0xF2,
    0x7D,
    0xB8,
  ];

  static final Random _secureRandom = Random.secure();

  /// Computes the 9-byte keystream from a 12-byte random seed.
  static Uint8List computeKeystream(List<int> r) {
    if (r.length != 12) {
      throw ArgumentError.value(r.length, 'r', 'Expected 12-byte random seed');
    }
    final ks = Uint8List(9);
    for (var i = 0; i < 9; i++) {
      final b0 = (r[i] * 27) & 0xFF;
      final b1 = (r[(i + 3) % 12] + 55) & 0xFF;
      final b2 = (r[(i + 7) % 12] >> 2) & 0xFF;
      final b3 = (i * 85) & 0xFF;
      ks[i] = b0 ^ b1 ^ b2 ^ b3;
    }
    return ks;
  }

  /// Encrypts a 9-byte plain frame into a 21-byte ciphertext.
  /// If [fixedRandom] is provided, it is used instead of cryptographically random bytes.
  static Uint8List encryptFrame(List<int> plain9, {List<int>? fixedRandom}) {
    if (plain9.length != 9) {
      throw ArgumentError.value(
          plain9.length, 'plain9', 'Must be exactly 9 bytes');
    }

    final b = Uint8List.fromList(plain9);
    b[0] = 0xAA;
    b[8] = 0x55;

    final r = Uint8List(12);
    if (fixedRandom != null) {
      if (fixedRandom.length != 12) {
        throw ArgumentError.value(
            fixedRandom.length, 'fixedRandom', 'Must be 12 bytes');
      }
      r.setAll(0, fixedRandom);
    } else {
      for (var i = 0; i < 12; i++) {
        r[i] = _secureRandom.nextInt(256);
      }
    }

    final ks = computeKeystream(r);
    final c = Uint8List(21);

    for (var i = 0; i < 9; i++) {
      c[i] = b[i] ^ ks[i];
    }
    for (var j = 0; j < 12; j++) {
      c[9 + j] = r[j] ^ key[j % 16];
    }

    return c;
  }

  /// Decrypts a 21-byte ciphertext back into the 9-byte plain frame (with 0x7E/0xEF headers restored).
  static Uint8List decryptFrame(List<int> c21) {
    if (c21.length != 21) {
      throw ArgumentError.value(c21.length, 'c21', 'Must be exactly 21 bytes');
    }

    final r = Uint8List(12);
    for (var j = 0; j < 12; j++) {
      r[j] = c21[9 + j] ^ key[j % 16];
    }

    final ks = computeKeystream(r);
    final plain = Uint8List(9);
    for (var i = 0; i < 9; i++) {
      plain[i] = c21[i] ^ ks[i];
    }

    // Restore standard frame headers
    plain[0] = 0x7E;
    plain[8] = 0xEF;

    return plain;
  }
}
