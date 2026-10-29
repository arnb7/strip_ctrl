import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../providers/device_state_provider.dart';
import '../../providers/transport_provider.dart';

class DiscoveredStrip {
  final BluetoothDevice device;
  final String name;
  final int rssi;
  final bool isEncrypted;

  DiscoveredStrip({
    required this.device,
    required this.name,
    required this.rssi,
    required this.isEncrypted,
  });
}

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  bool _isScanning = false;
  bool _showAllDevices = false;
  bool _isConnectingDirect = false;
  String? _lastError;
  final TextEditingController _macController =
      TextEditingController(text: 'BE:58:90:00:93:7B');
  final Map<String, DiscoveredStrip> _scanResults = <String, DiscoveredStrip>{};
  StreamSubscription<List<ScanResult>>? _scanSub;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _stopScan();
    _macController.dispose();
    super.dispose();
  }

  String _normalizeMac(String input) {
    final clean = input.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();
    if (clean.length == 12) {
      return [
        clean.substring(0, 2),
        clean.substring(2, 4),
        clean.substring(4, 6),
        clean.substring(6, 8),
        clean.substring(8, 10),
        clean.substring(10, 12),
      ].join(':');
    }
    return input.trim();
  }

  Future<void> _startScan() async {
    final diag = ref.read(diagnosticsProvider);
    if (diag.useFakeTransport) {
      setState(() {
        _isScanning = false;
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResults.clear();
      _lastError = null;
    });

    try {
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final advName = r.advertisementData.advName;
          final platName = r.device.platformName;
          final name = advName.isNotEmpty
              ? advName
              : (platName.isNotEmpty ? platName : 'Unknown BLE Device');

          final hasFff0 = r.advertisementData.serviceUuids.any((u) =>
              u.toString().toLowerCase().contains('fff0') ||
              u.str128.toLowerCase().contains('fff0'));

          final macUpper = r.device.remoteId.str.toUpperCase();
          final isKnown = AppConstants.isSupportedDevice(name) ||
              hasFff0 ||
              macUpper.contains('BE:58:90:00:93:7B') ||
              name.toLowerCase().contains('bledom');

          if (isKnown || _showAllDevices) {
            setState(() {
              _scanResults[r.device.remoteId.str] = DiscoveredStrip(
                device: r.device,
                name: name,
                rssi: r.rssi,
                isEncrypted: AppConstants.isEncryptedDevice(name),
              );
            });
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
    } catch (e) {
      _lastError = 'Scan error: $e';
    }

    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  Future<void> _connectToAddress(String rawAddress) async {
    final address = _normalizeMac(rawAddress);
    if (address.isEmpty) return;

    await _stopScan();
    setState(() {
      _isConnectingDirect = true;
      _lastError = null;
    });

    final transport = ref.read(transportProvider);
    try {
      await transport.connect(address);
      ref.read(deviceStateProvider.notifier).syncStripToApp();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_connected_device', address);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to $address successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastError = 'Connection failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to $address: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnectingDirect = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transport = ref.watch(transportProvider);
    final transportState =
        ref.watch(transportStateStreamProvider).value ?? transport.currentState;
    final state = ref.watch(deviceStateProvider);
    final notifier = ref.read(deviceStateProvider.notifier);
    final diag = ref.watch(diagnosticsProvider);

    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bluetooth Devices',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning
                      ? Colors.redAccent
                      : const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: Icon(_isScanning ? Icons.stop : Icons.refresh, size: 16),
                label: Text(_isScanning ? 'Stop Scan' : 'Scan BLE'),
                onPressed: () {
                  if (_isScanning) {
                    _stopScan();
                    setState(() => _isScanning = false);
                  } else {
                    _startScan();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Connection Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Connection',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: transportState == TransportState.ready
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          transportState.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: transportState == TransportState.ready
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transport.connectedAddress ??
                        (diag.useFakeTransport
                            ? 'Virtual FakeTransport (Active)'
                            : 'Not Connected'),
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  if (_lastError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _lastError!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (transportState == TransportState.ready)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent),
                          icon: const Icon(Icons.link_off, size: 18),
                          label: const Text('Disconnect'),
                          onPressed: () => transport.disconnect(),
                        )
                      else if (diag.useFakeTransport)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.link, size: 18),
                          label: const Text('Connect Fake Strip'),
                          onPressed: () =>
                              transport.connect('MOCK:AA:BB:CC:DD'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Direct MAC Address Connection Card (Quick Connect)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.amberAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Direct / Quick Connect by MAC',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Target device detected: BLEDOM (BE:58:90:00:93:7B).\n'
                    'Tap Quick Connect below or enter any MAC address to connect directly.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amberAccent,
                            side: const BorderSide(color: Colors.amberAccent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: _isConnectingDirect
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.amberAccent),
                                )
                              : const Icon(Icons.flash_on, size: 18),
                          label: const Text(
                            'Quick Connect: BE:58:90:00:93:7B',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isConnectingDirect
                              ? null
                              : () => _connectToAddress('BE:58:90:00:93:7B'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _macController,
                          decoration: InputDecoration(
                            labelText: 'Bluetooth MAC Address',
                            hintText: 'BE:58:90:00:93:7B',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isConnectingDirect
                            ? null
                            : () => _connectToAddress(_macController.text),
                        child: const Text('Connect'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hardware Pin Sequence (RGB Order Wizard)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune,
                          color: Colors.deepOrangeAccent, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Terminal Pin Order (Hardware Wizard)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Controller housing label: V+ / G / R / B.\n'
                    'If colors appear inverted, pick the matching sequence below:',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        ['GRB', 'RGB', 'RBG', 'GBR', 'BRG', 'BGR'].map((order) {
                      final isSelected = state.pinOrder == order;
                      return ChoiceChip(
                        label: Text(order),
                        selected: isSelected,
                        onSelected: (_) => notifier.setPinOrder(order),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 10),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => notifier.setRgb(255, 0, 0),
                          child: const Text('Test Red',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 10),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => notifier.setRgb(0, 255, 0),
                          child: const Text('Test Green',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 10),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => notifier.setRgb(0, 0, 255),
                          child: const Text('Test Blue',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Discovered Controllers Section Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Discovered Nearby Controllers',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Show All',
                      style: TextStyle(fontSize: 12, color: Colors.white60)),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _showAllDevices,
                      onChanged: (val) {
                        setState(() => _showAllDevices = val);
                        _startScan();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_scanResults.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                _isScanning
                    ? 'Scanning for BLEDOM / ELK controllers...'
                    : 'No controllers found in active scan.\nUse Quick Connect above to connect directly to BE:58:90:00:93:7B.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            )
          else
            ..._scanResults.values.map((discovered) {
              final isConnected =
                  transport.connectedAddress == discovered.device.remoteId.str;
              return Card(
                color: const Color(0xFF141414),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading:
                      const Icon(Icons.bluetooth, color: Colors.blueAccent),
                  title: Row(
                    children: [
                      Text(discovered.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (discovered.isEncrypted) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ENCRYPTED',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                      '${discovered.device.remoteId.str} • RSSI: ${discovered.rssi} dBm'),
                  trailing: ElevatedButton(
                    onPressed: isConnected
                        ? null
                        : () async {
                            await _connectToAddress(
                                discovered.device.remoteId.str);
                          },
                    child: Text(isConnected ? 'Connected' : 'Connect'),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
