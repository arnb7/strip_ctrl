import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';
import '../../providers/transport_provider.dart';

class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  final TextEditingController _hexInputController =
      TextEditingController(text: '7E 04 04 01 00 01 FF 00 EF');

  @override
  void dispose() {
    _hexInputController.dispose();
    super.dispose();
  }

  void _showSelfTestModal(BuildContext context) {
    final result = SelfTestRunner.run();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            result.allPass ? Icons.check_circle : Icons.error,
                            color: result.allPass
                                ? Colors.tealAccent
                                : Colors.redAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Protocol Verification Report',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                result.summary,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: result.allPass
                                      ? Colors.tealAccent
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: result.cases.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, idx) {
                        final tc = result.cases[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '#${idx + 1} ${tc.name}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: tc.pass
                                          ? Colors.greenAccent.withOpacity(0.15)
                                          : Colors.redAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tc.pass ? 'PASS' : 'FAIL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: tc.pass
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Expected: ${tc.expected}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                              Text(
                                'Actual:   ${tc.actual}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: tc.pass
                                      ? Colors.tealAccent
                                      : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final diag = ref.watch(diagnosticsProvider);
    final diagNotifier = ref.read(diagnosticsProvider.notifier);
    final transport = ref.watch(transportProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Diagnostics & Hex Console',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF4F4F5),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, size: 20),
                      tooltip: 'Clear Log',
                      color: const Color(0xFFA1A1AA),
                      onPressed: () => diagNotifier.clearLogs(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy Log to Clipboard',
                      color: const Color(0xFFA1A1AA),
                      onPressed: () {
                        final logText = diag.logs
                            .map((e) =>
                                '[${e.timestamp.toIso8601String().substring(11, 19)}] ${e.isTx ? "TX" : "RX"} -> ${e.hexString} (${e.note})')
                            .join('\n');
                        Clipboard.setData(ClipboardData(text: logText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Log copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Protocol Self-Test Card
          Card(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Protocol Verification',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '25 mandatory ELK test vectors (§3 & §4)',
                          style: TextStyle(fontSize: 11, color: Colors.white54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.verified, size: 14),
                    label: const Text('Run 25 Vectors',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 11)),
                    onPressed: () => _showSelfTestModal(context),
                  ),
                ],
              ),
            ),
          ),
          // Fake transport switch & MTU readout
          Card(
            margin: const EdgeInsets.all(12),
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Virtual FakeTransport',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        diag.useFakeTransport
                            ? 'Simulating hardware (Zero BLE needed)'
                            : 'Real Hardware (BlueZ / Android BLE)',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                  Switch(
                    value: diag.useFakeTransport,
                    onChanged: (val) {
                      diagNotifier.setUseFakeTransport(val);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Raw Hex Sender
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hexInputController,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Raw Hex (e.g. 7E 04 04 01 00 01 FF 00 EF)',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final text = _hexInputController.text.trim();
                    try {
                      final bytes = text
                          .split(RegExp(r'\s+'))
                          .map((s) => int.parse(s, radix: 16))
                          .toList();
                      await transport.write(bytes);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sent ${bytes.length} bytes'),
                            duration: const Duration(milliseconds: 700),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Parse error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Send'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Read GATT characteristic',
                  icon: const Icon(Icons.download),
                  onPressed: () async {
                    try {
                      final res = await transport.read();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Read ${res.length} bytes: $res')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Read error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text(
                  'Live Frame Stream',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Log list
          SizedBox(
            height: 250,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF101010),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: diag.logs.isEmpty
                  ? const Center(
                      child: Text('No frames recorded yet.',
                          style: TextStyle(color: Colors.white30)),
                    )
                  : ListView.builder(
                      itemCount: diag.logs.length,
                      itemBuilder: (context, idx) {
                        final log = diag.logs[idx];
                        final time =
                            log.timestamp.toIso8601String().substring(11, 19);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                time,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: log.isTx
                                      ? Colors.cyanAccent.withOpacity(0.15)
                                      : Colors.amberAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  log.isTx ? 'TX' : 'RX',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: log.isTx
                                        ? Colors.cyanAccent
                                        : Colors.amberAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.hexString.isNotEmpty
                                          ? log.hexString
                                          : '(no payload)',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (log.note.isNotEmpty)
                                      Text(
                                        log.note,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
