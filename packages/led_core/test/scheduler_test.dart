import 'package:led_core/led_core.dart';
import 'package:test/test.dart';

void main() {
  group('CommandScheduler', () {
    late FakeTransport transport;
    late CommandScheduler scheduler;

    setUp(() async {
      transport = FakeTransport();
      await transport.connect('AA:BB:CC:DD:EE:FF');
      scheduler = CommandScheduler(
        transport: transport,
        minFrameInterval: const Duration(milliseconds: 20),
        maxQueueSize: 5,
      );
    });

    tearDown(() async {
      await scheduler.dispose();
      await transport.dispose();
    });

    test('dispatches single command successfully to transport', () async {
      await scheduler.submit(const PowerCommand(true));

      expect(transport.writtenFrames.length, equals(1));
      expect(transport.writtenFrames.first,
          equals([0x7E, 0x04, 0x04, 0x01, 0x00, 0x01, 0xFF, 0x00, 0xEF]));
    });

    test('coalesces rapid slider updates (latest-wins)', () async {
      // Rapidly submit 5 brightness commands without awaiting each
      final futures = <Future<void>>[
        scheduler.submit(const BrightnessCommand(10)),
        scheduler.submit(const BrightnessCommand(20)),
        scheduler.submit(const BrightnessCommand(30)),
        scheduler.submit(const BrightnessCommand(40)),
        scheduler.submit(const BrightnessCommand(50)),
      ];

      await Future.wait(futures);

      // Even though 5 were submitted rapidly, coalescing ensures at most 2 writes happen
      // (the first one might begin dispatching before the others coalesce into 50)
      expect(transport.writtenFrames.length, lessThanOrEqualTo(2));
      // The final dispatched brightness must be 50
      final lastFrame = transport.writtenFrames.last;
      expect(lastFrame[2], equals(0x01)); // CMD brightness
      expect(lastFrame[3], equals(50)); // 50%
    });

    test('respects minFrameInterval between writes', () async {
      final t0 = DateTime.now();

      await scheduler.submit(const PowerCommand(true));
      await scheduler.submit(const ColorCommand(255, 0, 0));
      await scheduler.submit(const ColorCommand(0, 255, 0));

      final duration = DateTime.now().difference(t0);
      // 3 frames with 20ms interval = at least ~40ms
      expect(duration.inMilliseconds, greaterThanOrEqualTo(35));
      expect(transport.writtenFrames.length, equals(3));
    });

    test('drops or evicts when exceeding maxQueueSize without deadlock',
        () async {
      // Pause transport so queue accumulates
      final pausedTransport = FakeTransport();
      final overflowScheduler = CommandScheduler(
        transport: pausedTransport,
        minFrameInterval: const Duration(milliseconds: 50),
        maxQueueSize: 3,
      );

      // Submit more than maxQueueSize non-coalescible commands
      for (var i = 0; i < 5; i++) {
        // RawCommand has no coalescingKey
        overflowScheduler
            .submit(RawCommand(<int>[0x7E, 0x04, 0x04, i, 0, i, 0xFF, 0, 0xEF]))
            .catchError((_) {}); // catch eviction error
      }

      expect(overflowScheduler.queueLength, lessThanOrEqualTo(3));
      await overflowScheduler.dispose();
      await pausedTransport.dispose();
    });
  });
}
