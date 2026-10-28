import 'package:led_core/led_core.dart';
import 'package:test/test.dart';

void main() {
  test('SelfTestRunner runs all 25 vectors with 100% pass', () {
    final result = SelfTestRunner.run();
    expect(result.cases.length, 25);
    expect(result.allPass, isTrue);
    for (final c in result.cases) {
      expect(c.pass, isTrue,
          reason:
              'Case "${c.name}" failed: exp=${c.expected}, act=${c.actual}');
    }
  });
}
