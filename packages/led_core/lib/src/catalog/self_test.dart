import 'dart:typed_data';
import '../codec/encryption.dart';
import '../codec/frame_codec.dart';
import '../commands/led_command.dart';
import 'effect_catalog.dart';

class SelfTestCase {
  final String name;
  final String expected;
  final String actual;
  final bool pass;
  final String group;

  const SelfTestCase({
    required this.name,
    required this.expected,
    required this.actual,
    required this.pass,
    required this.group,
  });
}

class SelfTestResult {
  final List<SelfTestCase> cases;
  final bool allPass;
  final String summary;

  const SelfTestResult({
    required this.cases,
    required this.allPass,
    required this.summary,
  });
}

class SelfTestRunner {
  static String _toHex(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  static SelfTestCase _vector(
      String name, String expected, LedCommand command) {
    final bytes = FrameCodec.encodePlain(command);
    final actual = _toHex(bytes);
    return SelfTestCase(
      name: name,
      expected: expected,
      actual: actual,
      pass: actual == expected,
      group: 'Frame vectors',
    );
  }

  static SelfTestResult run() {
    final cases = <SelfTestCase>[];

    /* --- Mandatory unit-test vectors (§3.1) --- */
    cases.add(_vector(
        'Power on', '7E 04 04 01 00 01 FF 00 EF', const PowerCommand(true)));
    cases.add(_vector(
        'Power off', '7E 04 04 00 00 00 FF 00 EF', const PowerCommand(false)));
    cases.add(_vector('Brightness 50', '7E 04 01 32 FF FF FF 00 EF',
        const BrightnessCommand(50)));
    cases.add(_vector('RGB pure red', '7E 07 05 03 FF 00 00 10 EF',
        const ColorCommand(255, 0, 0)));
    cases.add(_vector(
        'Effect 3', '7E 05 03 83 03 FF FF 00 EF', const EffectCommand(3)));
    cases.add(_vector(
        'Effect 28', '7E 05 03 9C 03 FF FF 00 EF', const EffectCommand(28)));

    /* --- Additional vector coverage --- */
    cases.add(_vector('Brightness 0', '7E 04 01 00 FF FF FF 00 EF',
        const BrightnessCommand(0)));
    cases.add(_vector('Brightness 100', '7E 04 01 64 FF FF FF 00 EF',
        const BrightnessCommand(100)));
    cases.add(_vector('RGB teal', '7E 07 05 03 00 80 80 10 EF',
        const ColorCommand(0, 128, 128)));
    cases.add(_vector('Music color red', '7E 07 05 03 FF 00 00 20 EF',
        const MusicReactiveColorCommand(255, 0, 0)));
    cases.add(_vector('CCT warm/cold', '7E 06 05 02 FF 80 FF 08 EF',
        const WhiteCctCommand(255, 128)));
    cases.add(_vector('Single-channel level', '7E 05 05 01 7F FF FF 08 EF',
        const SingleColorCommand(127)));
    cases.add(_vector('Effect speed 60', '7E 04 02 3C FF FF FF 00 EF',
        const EffectSpeedCommand(60)));
    cases.add(_vector('Channel order 2,1,3', '7E 06 81 02 01 03 FF 00 EF',
        const RgbOrderCommand(2, 1, 3)));
    cases.add(_vector(
        'Effect 0', '7E 05 03 80 03 FF FF 00 EF', const EffectCommand(0)));
    cases.add(_vector(
        'Set clock 12:34:56 wd3 (VERIFY)',
        '7E 07 83 0C 22 38 03 FF EF',
        const DeviceClockCommand(
            hour: 12, minute: 34, second: 56, weekday: 3)));
    cases.add(_vector(
        'Schedule slot 07:30:00 on, daily (VERIFY)',
        '7E 08 82 07 1E 00 01 7F EF',
        const ScheduleSlotCommand(
            hour: 7, minute: 30, second: 0, mode: 1, weeks: 0x7F)));
    cases.add(_vector(
        'Countdown 300s -> off (VERIFY)',
        '7E 07 76 2C 01 00 00 FF EF',
        const CountdownCommand(secondsTimestamp: 300, mode: 0)));

    /* --- Encryption known-answer test (§4) --- */
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
    final plainPower = FrameCodec.encodePlain(const PowerCommand(true));
    final katCipher =
        ElkEncryption.encryptFrame(plainPower, fixedRandom: fixedR);
    final katPass = katCipher.length == expectedC.length &&
        List.generate(katCipher.length, (i) => katCipher[i] == expectedC[i])
            .every((b) => b);

    cases.add(SelfTestCase(
      name: 'Encryption KAT (fixed R)',
      expected: _toHex(expectedC),
      actual: _toHex(katCipher),
      pass: katPass,
      group: 'Encryption',
    ));

    final recovered = ElkEncryption.decryptFrame(Uint8List.fromList(expectedC));
    final recoveredPass = recovered.length == plainPower.length &&
        List.generate(recovered.length, (i) => recovered[i] == plainPower[i])
            .every((b) => b);

    cases.add(SelfTestCase(
      name: 'KAT decrypt -> original frame',
      expected: _toHex(plainPower),
      actual: _toHex(recovered),
      pass: recoveredPass,
      group: 'Encryption',
    ));

    // Random round-trip
    final samples = <LedCommand>[
      const PowerCommand(true),
      const BrightnessCommand(42),
      const EffectCommand(12),
      const ColorCommand(10, 200, 90),
    ];
    var roundTripOk = true;
    for (final s in samples) {
      final p = FrameCodec.encodePlain(s);
      final enc = ElkEncryption.encryptFrame(p);
      final dec = ElkEncryption.decryptFrame(enc);
      if (dec.length != p.length ||
          !List.generate(p.length, (i) => dec[i] == p[i]).every((b) => b)) {
        roundTripOk = false;
      }
    }
    cases.add(SelfTestCase(
      name: 'Encrypt -> decrypt round-trip (x4 frames)',
      expected: 'identical',
      actual: roundTripOk ? 'identical' : 'mismatch',
      pass: roundTripOk,
      group: 'Encryption',
    ));

    final encryptableCheck = const BrightnessCommand(50).canBeEncrypted &&
        const EffectCommand(1).canBeEncrypted &&
        const PowerCommand(true).canBeEncrypted &&
        !const ColorCommand(1, 2, 3).canBeEncrypted;

    cases.add(SelfTestCase(
      name: 'Only CMD 01/03/04 encryptable (rule)',
      expected: 'brightness✓ effect✓ power✓ color✗',
      actual: encryptableCheck
          ? 'brightness✓ effect✓ power✓ color✗'
          : 'failed eligibility',
      pass: encryptableCheck,
      group: 'Encryption',
    ));

    /* --- Catalog integrity --- */
    cases.add(SelfTestCase(
      name: 'Effect catalog count = 29',
      expected: '29',
      actual: '${EffectCatalog.effects.length}',
      pass: EffectCatalog.effects.length == 29,
      group: 'Catalog',
    ));

    final indicesOk = EffectCatalog.effects
            .asMap()
            .entries
            .every((e) => e.value.index == e.key) &&
        EffectCatalog.byIndex(28) != null &&
        EffectCatalog.byIndex(29) == null;

    cases.add(SelfTestCase(
      name: 'Effect indices 0..28, contiguous',
      expected: '0..28',
      actual: indicesOk ? '0..28' : 'broken',
      pass: indicesOk,
      group: 'Catalog',
    ));

    final strobesOk = [21, 22, 23, 24, 25, 26, 27, 28]
            .every((i) => EffectCatalog.byIndex(i)?.isStrobe == true) &&
        EffectCatalog.byIndex(20)?.isStrobe == false;

    cases.add(SelfTestCase(
      name: 'Strobe classification (21..28)',
      expected: '21..28',
      actual: strobesOk ? '21..28' : 'wrong',
      pass: strobesOk,
      group: 'Catalog',
    ));

    final allPass = cases.every((c) => c.pass);
    final passedCount = cases.where((c) => c.pass).length;

    return SelfTestResult(
      cases: cases,
      allPass: allPass,
      summary: '$passedCount/${cases.length} checks passed',
    );
  }
}
