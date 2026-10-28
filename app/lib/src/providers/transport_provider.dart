import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';
import '../transport/ble_transport.dart';

class TxRxLogEntry {
  final DateTime timestamp;
  final bool isTx;
  final List<int> bytes;
  final String note;

  TxRxLogEntry({
    required this.isTx,
    required this.bytes,
    this.note = '',
  }) : timestamp = DateTime.now();

  String get hexString => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');
}

class DiagnosticsState {
  final bool useFakeTransport;
  final List<TxRxLogEntry> logs;

  const DiagnosticsState({
    this.useFakeTransport = false,
    this.logs = const <TxRxLogEntry>[],
  });

  DiagnosticsState copyWith({
    bool? useFakeTransport,
    List<TxRxLogEntry>? logs,
  }) {
    return DiagnosticsState(
      useFakeTransport: useFakeTransport ?? this.useFakeTransport,
      logs: logs ?? this.logs,
    );
  }
}

class DiagnosticsNotifier extends StateNotifier<DiagnosticsState> {
  DiagnosticsNotifier() : super(const DiagnosticsState());

  void setUseFakeTransport(bool value) {
    state = state.copyWith(useFakeTransport: value);
  }

  void addLog(
      {required bool isTx, required List<int> bytes, String note = ''}) {
    final entry = TxRxLogEntry(isTx: isTx, bytes: bytes, note: note);
    final updated = List<TxRxLogEntry>.from(state.logs)..insert(0, entry);
    if (updated.length > 200) {
      updated.removeLast();
    }
    state = state.copyWith(logs: updated);
  }

  void clearLogs() {
    state = state.copyWith(logs: const <TxRxLogEntry>[]);
  }
}

final diagnosticsProvider =
    StateNotifierProvider<DiagnosticsNotifier, DiagnosticsState>((ref) {
  return DiagnosticsNotifier();
});

class LoggingTransportWrapper implements LedTransport {
  final LedTransport inner;
  final void Function(bool isTx, List<int> bytes, String note) onLog;

  LoggingTransportWrapper(this.inner, this.onLog);

  @override
  Stream<TransportState> get state => inner.state;

  @override
  TransportState get currentState => inner.currentState;

  @override
  int get mtu => inner.mtu;

  @override
  String? get connectedAddress => inner.connectedAddress;

  @override
  Future<void> connect(String address) {
    onLog(true, const <int>[], 'Connecting to $address');
    return inner.connect(address);
  }

  @override
  Future<void> disconnect() {
    onLog(true, const <int>[], 'Disconnecting');
    return inner.disconnect();
  }

  @override
  Future<void> write(List<int> bytes, {bool withoutResponse = true}) async {
    onLog(true, bytes, 'GATT Write (noResp: $withoutResponse)');
    await inner.write(bytes, withoutResponse: withoutResponse);
  }

  @override
  Future<List<int>> read() async {
    final res = await inner.read();
    onLog(false, res, 'GATT Read response');
    return res;
  }

  @override
  Future<void> dispose() => inner.dispose();
}

final transportProvider = Provider<LedTransport>((ref) {
  final useFake =
      ref.watch(diagnosticsProvider.select((s) => s.useFakeTransport));
  final LedTransport raw = useFake ? FakeTransport() : BleTransport();
  final wrapper = LoggingTransportWrapper(raw, (isTx, bytes, note) {
    ref
        .read(diagnosticsProvider.notifier)
        .addLog(isTx: isTx, bytes: bytes, note: note);
  });
  ref.onDispose(() {
    wrapper.dispose();
  });
  return wrapper;
});

final schedulerProvider = Provider<CommandScheduler>((ref) {
  final transport = ref.watch(transportProvider);
  final scheduler = CommandScheduler(transport: transport);
  ref.onDispose(() {
    scheduler.dispose();
  });
  return scheduler;
});

final transportStateStreamProvider =
    StreamProvider<TransportState>((ref) async* {
  final transport = ref.watch(transportProvider);
  yield transport.currentState;
  yield* transport.state;
});
