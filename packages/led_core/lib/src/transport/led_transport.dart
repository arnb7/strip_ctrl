import 'dart:async';

enum TransportState {
  disconnected,
  scanning,
  connecting,
  discovering,
  ready,
}

abstract interface class LedTransport {
  Stream<TransportState> get state;
  TransportState get currentState;
  int get mtu;
  String? get connectedAddress;

  Future<void> connect(String address);
  Future<void> disconnect();
  Future<void> write(List<int> bytes, {bool withoutResponse = true});
  Future<List<int>> read();
  Future<void> dispose();
}
