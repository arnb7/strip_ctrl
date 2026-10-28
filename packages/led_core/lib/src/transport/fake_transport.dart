import 'dart:async';
import 'led_transport.dart';

class FakeTransport implements LedTransport {
  final _stateController = StreamController<TransportState>.broadcast();
  TransportState _currentState = TransportState.disconnected;
  int _mtu;
  String? _connectedAddress;

  final List<List<int>> writtenFrames = <List<int>>[];
  final List<List<int>> scriptedReplies = <List<int>>[];

  FakeTransport({int initialMtu = 247}) : _mtu = initialMtu;

  @override
  Stream<TransportState> get state => _stateController.stream;

  @override
  TransportState get currentState => _currentState;

  @override
  int get mtu => _mtu;

  set mtu(int value) => _mtu = value;

  @override
  String? get connectedAddress => _connectedAddress;

  void setState(TransportState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  @override
  Future<void> connect(String address) async {
    setState(TransportState.connecting);
    _connectedAddress = address;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    setState(TransportState.discovering);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    setState(TransportState.ready);
  }

  @override
  Future<void> disconnect() async {
    _connectedAddress = null;
    setState(TransportState.disconnected);
  }

  @override
  Future<void> write(List<int> bytes, {bool withoutResponse = true}) async {
    if (_currentState != TransportState.ready) {
      throw StateError('Cannot write when transport is not ready');
    }
    writtenFrames.add(List<int>.unmodifiable(bytes));
  }

  @override
  Future<List<int>> read() async {
    if (_currentState != TransportState.ready) {
      throw StateError('Cannot read when transport is not ready');
    }
    if (scriptedReplies.isNotEmpty) {
      return scriptedReplies.removeAt(0);
    }
    // Default reply mimicking on/off schedule query (7E 09 85 ...)
    return <int>[0x7E, 0x09, 0x85, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEF];
  }

  void clearRecorded() {
    writtenFrames.clear();
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
  }
}
