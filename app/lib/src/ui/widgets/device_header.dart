import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';
import '../../providers/device_state_provider.dart';
import '../../providers/transport_provider.dart';

class DeviceHeader extends ConsumerWidget {
  final VoidCallback onOpenDevices;
  final bool showStrip;
  final VoidCallback? onToggleStrip;

  const DeviceHeader({
    super.key,
    required this.onOpenDevices,
    this.showStrip = true,
    this.onToggleStrip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transportState =
        ref.watch(transportStateStreamProvider).asData?.value ??
            ref.watch(transportProvider).currentState;
    final deviceState = ref.watch(deviceStateProvider);
    final isPowerOn = deviceState.power;

    final (dotColor, stateText) = switch (transportState) {
      TransportState.ready => (const Color(0xFF10B981), 'Connected'),
      TransportState.connecting => (const Color(0xFFF59E0B), 'Connecting'),
      TransportState.discovering => (const Color(0xFFF59E0B), 'Discovering'),
      TransportState.scanning => (const Color(0xFF38BDF8), 'Scanning'),
      TransportState.disconnected => (const Color(0xFF71717A), 'No Device'),
    };

    return Container(
          height: 56,
          color: const Color(0xFF000000), // AMOLED Pure Black
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Zap logo badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: const Icon(Icons.bolt, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'strip_ctrl',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      color: Color(0xFFF4F4F5),
                    ),
                  ),
                  Text(
                    'offline BLE LED controller',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Status Pill Button
              InkWell(
                onTap: onOpenDevices,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141416),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stateText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFA1A1AA),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down,
                          size: 16, color: Color(0xFFA1A1AA)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Strip Display Visibility Toggle
              if (onToggleStrip != null)
                IconButton(
                  tooltip: showStrip ? 'Collapse LED Strip' : 'Expand LED Strip',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF141416),
                    foregroundColor: const Color(0xFFA1A1AA),
                    side: const BorderSide(color: Color(0xFF27272A)),
                    minimumSize: const Size(36, 36),
                    padding: const EdgeInsets.all(6),
                  ),
                  icon: Icon(
                    showStrip ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  onPressed: onToggleStrip,
                ),

              const SizedBox(width: 4),

              // Quick Power Button
              IconButton(
                tooltip: isPowerOn ? 'Power Off' : 'Power On',
                style: IconButton.styleFrom(
                  backgroundColor: isPowerOn
                      ? const Color(0xFFF97316)
                      : const Color(0xFF141416),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: isPowerOn
                        ? const Color(0xFFF97316)
                        : const Color(0xFF27272A),
                  ),
                  minimumSize: const Size(36, 36),
                  padding: const EdgeInsets.all(6),
                ),
                icon: const Icon(Icons.power_settings_new, size: 18),
                onPressed: () {
                  ref.read(deviceStateProvider.notifier).setPower(!isPowerOn);
                },
              ),
            ],
          ),
    );
  }
}
