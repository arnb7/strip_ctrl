import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';
import '../../providers/device_state_provider.dart';
import '../../providers/transport_provider.dart';

class StripDisplay extends ConsumerWidget {
  const StripDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceStateProvider);
    final transportState = ref.watch(transportStateStreamProvider).asData?.value ??
        ref.watch(transportProvider).currentState;
    final isConnected = transportState == TransportState.ready;

    final currentColor = Color.fromARGB(255, state.r, state.g, state.b);
    final isPowerOn = state.power;

    String modeText = 'Solid Color';
    IconData modeIcon = Icons.palette_outlined;
    if (state.mode == ActiveLedMode.music) {
      modeText = 'Music Reactive';
      modeIcon = Icons.waves;
    } else if (state.mode == ActiveLedMode.white) {
      modeText = 'White (CCT)';
      modeIcon = Icons.wb_sunny_outlined;
    } else if (state.mode == ActiveLedMode.effect) {
      modeText = 'Effect ${state.effectIndex}';
      modeIcon = Icons.auto_awesome;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 95,
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF27272A), width: 1),
      ),
      child: Stack(
        children: [
          // Custom Canvas Painter for ambient glow and LED dots
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: _StripPainter(
                  color: currentColor,
                  power: isPowerOn,
                ),
              ),
            ),
          ),

          // Top Overlay: Badges and Quick Power Button
          Positioned(
            top: 8,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    // Connection Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF71717A),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isConnected ? 'BLEDOM' : 'Offline',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active Mode Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFF97316).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(modeIcon,
                              size: 11, color: const Color(0xFFF97316)),
                          const SizedBox(width: 4),
                          Text(
                            modeText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF97316),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Power Quick Button
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: isPowerOn
                        ? const Color(0xFFF97316)
                        : const Color(0xFF27272A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(28, 28),
                  ),
                  icon: const Icon(Icons.power_settings_new, size: 15),
                  onPressed: () {
                    ref.read(deviceStateProvider.notifier).setPower(!isPowerOn);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StripPainter extends CustomPainter {
  final Color color;
  final bool power;

  _StripPainter({required this.color, required this.power});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h / 2 + 15;

    // Ambient radial glow
    if (power && (color.r + color.g + color.b > 0.05)) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(w / 2, cy), radius: w * 0.55));
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);
    }

    // Housing Track
    const stripH = 28.0;
    const pad = 12.0;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, cy - stripH / 2, w - pad * 2, stripH),
      const Radius.circular(14),
    );

    final trackPaint = Paint()
      ..color = const Color(0xFF18181B)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(trackRect, trackPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF27272A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(trackRect, borderPaint);

    // Uniform LED Dots
    const dotR = 6.5;
    const gap = 20.0;
    final usable = w - pad * 2 - 16;
    final count = math.max(6, (usable / gap).floor());
    final startX = pad + 8 + (usable - (count - 1) * gap) / 2;

    final bloomPaint = Paint()
      ..isAntiAlias = true
      ..color = color.withOpacity(0.35);
    final dotPaint = Paint()
      ..isAntiAlias = true
      ..color = color;
    final glintPaint = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withOpacity(0.40);
    final offDotPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF27272A);
    final offGlintPaint = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withOpacity(0.06);

    final isGlow = power && (color.r + color.g + color.b > 0.05);

    for (int i = 0; i < count; i++) {
      final dx = startX + i * gap;
      final center = Offset(dx, cy);

      if (isGlow) {
        // Dot Bloom Glow (hardware-accelerated concentric anti-aliased circles)
        canvas.drawCircle(center, dotR + 3.5, bloomPaint);

        // Core LED Dot
        canvas.drawCircle(center, dotR, dotPaint);

        // Specular Glint
        canvas.drawCircle(
            Offset(dx - dotR * 0.3, cy - dotR * 0.3), dotR * 0.32, glintPaint);
      } else {
        // Off LED Dot
        canvas.drawCircle(center, dotR, offDotPaint);
        canvas.drawCircle(Offset(dx - dotR * 0.3, cy - dotR * 0.3), dotR * 0.3,
            offGlintPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StripPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.power != power;
  }
}
