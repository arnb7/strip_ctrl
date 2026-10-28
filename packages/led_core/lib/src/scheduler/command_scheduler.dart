import 'dart:async';
import 'dart:collection';
import '../codec/frame_codec.dart';
import '../commands/led_command.dart';
import '../transport/led_transport.dart';

class ScheduledEntry {
  final LedCommand command;
  final Completer<void> completer;

  ScheduledEntry(this.command) : completer = Completer<void>();
}

class CommandScheduler {
  final LedTransport transport;
  final Duration minFrameInterval;
  final int maxQueueSize;

  bool _isEncryptedDevice = false;
  bool _isProcessing = false;
  bool _isDisposed = false;

  final Queue<ScheduledEntry> _queue = Queue<ScheduledEntry>();
  final Map<String, ScheduledEntry> _coalescedEntries =
      <String, ScheduledEntry>{};

  DateTime _lastDispatchTime = DateTime.fromMillisecondsSinceEpoch(0);

  CommandScheduler({
    required this.transport,
    this.minFrameInterval = const Duration(milliseconds: 35),
    this.maxQueueSize = 32,
    bool isEncryptedDevice = false,
  }) : _isEncryptedDevice = isEncryptedDevice;

  bool get isEncryptedDevice => _isEncryptedDevice;
  set isEncryptedDevice(bool val) => _isEncryptedDevice = val;

  int get queueLength => _queue.length;

  /// Enqueues a command for dispatch.
  /// If [command.coalescingKey] is non-null and an identical key is already queued,
  /// the old entry is replaced in-place (latest-wins).
  Future<void> submit(LedCommand command) {
    if (_isDisposed) {
      return Future.error(StateError('CommandScheduler is disposed'));
    }

    final key = command.coalescingKey;
    if (key != null && _coalescedEntries.containsKey(key)) {
      // Coalesce: update the existing queued command
      final existing = _coalescedEntries[key]!;
      // Find and replace in queue
      final newEntry = ScheduledEntry(command);
      _coalescedEntries[key] = newEntry;

      final updatedQueue = Queue<ScheduledEntry>();
      for (final item in _queue) {
        if (identical(item, existing)) {
          updatedQueue.add(newEntry);
          if (!existing.completer.isCompleted) {
            existing.completer.complete(); // Superseded without error
          }
        } else {
          updatedQueue.add(item);
        }
      }
      _queue.clear();
      _queue.addAll(updatedQueue);

      _ensureProcessing();
      return newEntry.completer.future;
    }

    // Check capacity
    if (_queue.length >= maxQueueSize) {
      // Evict oldest coalescible command if possible, otherwise drop oldest
      ScheduledEntry? toEvict;
      for (final item in _queue) {
        if (item.command.coalescingKey != null) {
          toEvict = item;
          break;
        }
      }
      toEvict ??= _queue.first;
      _queue.remove(toEvict);
      if (toEvict.command.coalescingKey != null) {
        _coalescedEntries.remove(toEvict.command.coalescingKey);
      }
      if (!toEvict.completer.isCompleted) {
        toEvict.completer.completeError(
          StateError('Command evicted due to queue capacity overflow'),
        );
      }
    }

    final entry = ScheduledEntry(command);
    if (key != null) {
      _coalescedEntries[key] = entry;
    }
    _queue.add(entry);

    _ensureProcessing();
    return entry.completer.future;
  }

  void _ensureProcessing() {
    if (_isProcessing || _isDisposed) return;
    _isProcessing = true;
    _drainQueue();
  }

  Future<void> _drainQueue() async {
    while (_queue.isNotEmpty && !_isDisposed) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastDispatchTime);
      if (elapsed < minFrameInterval) {
        final waitDuration = minFrameInterval - elapsed;
        await Future<void>.delayed(waitDuration);
      }

      if (_queue.isEmpty || _isDisposed) break;

      final entry = _queue.removeFirst();
      if (entry.command.coalescingKey != null) {
        _coalescedEntries.remove(entry.command.coalescingKey);
      }

      try {
        if (transport.currentState == TransportState.ready) {
          final payload = FrameCodec.encode(
            entry.command,
            isEncryptedDevice: _isEncryptedDevice,
          );
          await transport.write(payload, withoutResponse: true);
          _lastDispatchTime = DateTime.now();
        }
        if (!entry.completer.isCompleted) {
          entry.completer.complete();
        }
      } catch (e, st) {
        if (!entry.completer.isCompleted) {
          entry.completer.completeError(e, st);
        }
      }
    }
    _isProcessing = false;
  }

  void clearQueue() {
    for (final entry in _queue) {
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(
          StateError('Queue cleared'),
        );
      }
    }
    _queue.clear();
    _coalescedEntries.clear();
  }

  Future<void> dispose() async {
    _isDisposed = true;
    clearQueue();
  }
}
