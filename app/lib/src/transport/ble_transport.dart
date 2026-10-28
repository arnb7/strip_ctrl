import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:led_core/led_core.dart';
import '../core/constants.dart';

class BleTransport implements LedTransport {
  final _stateController = StreamController<TransportState>.broadcast();
  TransportState _currentState = TransportState.disconnected;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  final int _mtu = 23;
  String? _connectedAddress;
  String? _targetAddress;
  bool _intentionalDisconnect = false;
  Timer? _reconnectTimer;
  Timer? _keepAliveTimer;
  DateTime _lastWriteTime = DateTime.now();

  BleTransport() {
    _emitState(TransportState.disconnected);
  }

  void _emitState(TransportState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  @override
  Stream<TransportState> get state => _stateController.stream;

  @override
  TransportState get currentState => _currentState;

  @override
  int get mtu => _mtu;

  @override
  String? get connectedAddress => _connectedAddress;

  void _scheduleAutoReconnect() {
    _reconnectTimer?.cancel();
    if (_intentionalDisconnect || _targetAddress == null) return;
    _reconnectTimer = Timer(const Duration(seconds: 3), () async {
      if (_currentState == TransportState.ready || _intentionalDisconnect) return;
      try {
        _emitState(TransportState.connecting);
        await connect(_targetAddress!);
      } catch (_) {
        if (!_intentionalDisconnect) {
          _scheduleAutoReconnect();
        }
      }
    });
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (_currentState == TransportState.ready && _writeCharacteristic != null) {
        final elapsed = DateTime.now().difference(_lastWriteTime).inSeconds;
        if (elapsed >= 8) {
          try {
            await _writeCharacteristic?.read();
          } catch (_) {}
        }
      }
    });
  }

  @override
  Future<void> connect(String address) async {
    _intentionalDisconnect = false;
    _targetAddress = address;
    _reconnectTimer?.cancel();
    await _disconnectInternal();

    _emitState(TransportState.connecting);
    _connectedAddress = address;

    try {
      final device = BluetoothDevice.fromId(address);
      _device = device;

      var hasConnected = false;
      _connSub = device.connectionState.listen((connState) {
        if (connState == BluetoothConnectionState.connected) {
          hasConnected = true;
        } else if (connState == BluetoothConnectionState.disconnected &&
            hasConnected) {
          _writeCharacteristic = null;
          _emitState(TransportState.disconnected);
          if (!_intentionalDisconnect && _targetAddress != null) {
            _scheduleAutoReconnect();
          }
        }
      });

      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      if (Platform.isAndroid) {
        try {
          await device.requestConnectionPriority(
            connectionPriorityRequest: ConnectionPriority.high,
          );
        } catch (_) {}
      }

      _emitState(TransportState.discovering);

      final services = await device.discoverServices();
      BluetoothCharacteristic? targetChar;

      bool matchesService(Guid guid) {
        final s128 = guid.str128.toLowerCase();
        final sShort = guid.toString().toLowerCase();
        return s128 == AppConstants.serviceUuid.toLowerCase() ||
            sShort == 'fff0' ||
            s128.contains('fff0') ||
            sShort == 'ffd0' ||
            s128.contains('ffd0') ||
            sShort == 'ffe0' ||
            s128.contains('ffe0');
      }

      bool matchesChar(Guid guid) {
        final c128 = guid.str128.toLowerCase();
        final cShort = guid.toString().toLowerCase();
        return c128 == AppConstants.writeCharUuid.toLowerCase() ||
            cShort == 'fff3' ||
            c128.contains('fff3') ||
            cShort == 'ffd5' ||
            c128.contains('ffd5') ||
            cShort == 'ffe1' ||
            c128.contains('ffe1');
      }

      // Step 1: Search service fff0/ffd0/ffe0 for characteristic fff3/ffd5/ffe1
      for (final s in services) {
        if (matchesService(s.uuid)) {
          for (final c in s.characteristics) {
            if (matchesChar(c.uuid)) {
              targetChar = c;
              break;
            }
          }
        }
        if (targetChar != null) break;
      }

      // Step 2: Search any service for characteristic fff3/ffd5/ffe1
      if (targetChar == null) {
        for (final s in services) {
          for (final c in s.characteristics) {
            if (matchesChar(c.uuid)) {
              targetChar = c;
              break;
            }
          }
          if (targetChar != null) break;
        }
      }

      // Step 3: Search service fff0/ffd0/ffe0 for any writable characteristic
      if (targetChar == null) {
        for (final s in services) {
          if (matchesService(s.uuid)) {
            for (final c in s.characteristics) {
              if (c.properties.writeWithoutResponse || c.properties.write) {
                targetChar = c;
                break;
              }
            }
          }
          if (targetChar != null) break;
        }
      }

      // Step 4: Search any service for a writeWithoutResponse characteristic
      if (targetChar == null) {
        for (final s in services) {
          for (final c in s.characteristics) {
            if (c.properties.writeWithoutResponse) {
              targetChar = c;
              break;
            }
          }
          if (targetChar != null) break;
        }
      }

      // Step 5: Search any service for any writable characteristic
      if (targetChar == null) {
        for (final s in services) {
          for (final c in s.characteristics) {
            if (c.properties.write) {
              targetChar = c;
              break;
            }
          }
          if (targetChar != null) break;
        }
      }

      if (targetChar == null) {
        await disconnect();
        throw StateError(
          'Target GATT write characteristic not found on device $address',
        );
      }

      _writeCharacteristic = targetChar;
      _lastWriteTime = DateTime.now();
      _startKeepAlive();
      _emitState(TransportState.ready);
    } catch (e) {
      await _disconnectInternal();
      rethrow;
    }
  }

  Future<void> _disconnectInternal() async {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    await _connSub?.cancel();
    _connSub = null;
    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
      _device = null;
    }
    _writeCharacteristic = null;
    _connectedAddress = null;
    _emitState(TransportState.disconnected);
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _targetAddress = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _disconnectInternal();
  }

  @override
  Future<void> write(List<int> bytes, {bool withoutResponse = true}) async {
    final char = _writeCharacteristic;
    if (char == null || _currentState != TransportState.ready) {
      throw StateError('Cannot write: BLE transport is not ready');
    }

    final canWithout = char.properties.writeWithoutResponse;
    final useWithoutResponse = withoutResponse && canWithout;

    _lastWriteTime = DateTime.now();
    try {
      await char.write(
        bytes,
        withoutResponse: useWithoutResponse,
      );
    } catch (e) {
      if (!_intentionalDisconnect && _targetAddress != null) {
        _scheduleAutoReconnect();
      }
      rethrow;
    }
  }

  @override
  Future<List<int>> read() async {
    final char = _writeCharacteristic;
    if (char == null || _currentState != TransportState.ready) {
      throw StateError('Cannot read: BLE transport is not ready');
    }
    return await char.read();
  }

  @override
  Future<void> dispose() async {
    _intentionalDisconnect = true;
    _targetAddress = null;
    _reconnectTimer?.cancel();
    _keepAliveTimer?.cancel();
    await _disconnectInternal();
    await _stateController.close();
  }
}
