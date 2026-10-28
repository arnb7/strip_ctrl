import 'dart:math' as math;
import 'package:flutter/material.dart';

class HsvColorWheel extends StatefulWidget {
  final Color currentColor;
  final bool power;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onTogglePower;

  const HsvColorWheel({
    super.key,
    required this.currentColor,
    required this.power,
    required this.onColorChanged,
    required this.onTogglePower,
  });

  @override
  State<HsvColorWheel> createState() => _HsvColorWheelState();
}

class _HsvColorWheelState extends State<HsvColorWheel> {
  Offset? _selectorPosition;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxHeight.isFinite
          ? math.min(constraints.maxWidth, constraints.maxHeight)
          : math.min(constraints.maxWidth, 220.0);
      final radius = size / 2;
      final center = Offset(radius, radius);

      final hsv = HSVColor.fromColor(widget.currentColor);
      final angle = (hsv.hue * math.pi) / 180;
      final innerR = radius * 0.40;
      final outerR = radius * 0.88;
      final currentDist = innerR + hsv.saturation * (outerR - innerR);

      final currentSelector = _selectorPosition ??
          Offset(
            center.dx + currentDist * math.cos(angle),
            center.dy + currentDist * math.sin(angle),
          );

      return Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) =>
              _handleTouch(details.localPosition, radius, center),
          onPanStart: (details) =>
              _handleTouch(details.localPosition, radius, center),
          onPanUpdate: (details) =>
              _handleTouch(details.localPosition, radius, center),
          onPanEnd: (_) => setState(() => _selectorPosition = null),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft glow behind wheel
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: size * 0.9,
                  height: size * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.power
                            ? widget.currentColor.withOpacity(0.35)
                            : Colors.transparent,
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
                // Custom Paint HSV Wheel
                CustomPaint(
                  size: Size(size, size),
                  painter: _HsvWheelPainter(radius: radius),
                ),
                // Selector thumb
                Positioned(
                  left: currentSelector.dx - 14,
                  top: currentSelector.dy - 14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.currentColor,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                ),
                // Center Power Button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onTogglePower,
                  child: Container(
                    width: size * 0.36,
                    height: size * 0.36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF141414),
                      border: Border.all(
                        color: widget.power
                            ? widget.currentColor.withOpacity(0.7)
                            : Colors.white12,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.power_settings_new,
                        size: size * 0.16,
                        color:
                            widget.power ? widget.currentColor : Colors.white24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _handleTouch(Offset localPos, double radius, Offset center) {
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    // Inside deadzone (center power button)
    if (dist < radius * 0.28) return;

    // Outside wheel deadzone (allow parent scroll gestures)
    if (dist > radius * 1.05) return;

    var rad = math.atan2(dy, dx);
    if (rad < 0) rad += 2 * math.pi;
    final hue = (rad * 180) / math.pi;

    final innerR = radius * 0.40;
    final outerR = radius * 0.88;
    final sat = ((dist - innerR) / (outerR - innerR)).clamp(0.05, 1.0);

    final clampedDist = dist.clamp(innerR, outerR);
    setState(() {
      _selectorPosition = Offset(
        center.dx + clampedDist * math.cos(rad),
        center.dy + clampedDist * math.sin(rad),
      );
    });

    final hsv = HSVColor.fromAHSV(1.0, hue, sat, 1.0);
    widget.onColorChanged(hsv.toColor());
  }
}

class _HsvWheelPainter extends CustomPainter {
  final double radius;

  _HsvWheelPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerR = radius * 0.40;
    final outerR = radius * 0.88;

    // Draw sweep gradient wheel for full 360 hues
    const colors = <Color>[
      Color(0xFFFF0000), // Red
      Color(0xFFFFFF00), // Yellow
      Color(0xFF00FF00), // Green
      Color(0xFF00FFFF), // Cyan
      Color(0xFF0000FF), // Blue
      Color(0xFFFF00FF), // Magenta
      Color(0xFFFF0000), // Red
    ];

    const sweepGradient = SweepGradient(
      colors: colors,
      startAngle: 0.0,
      endAngle: 2 * math.pi,
    );

    final paint = Paint()
      ..shader = sweepGradient
          .createShader(Rect.fromCircle(center: center, radius: outerR))
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerR - innerR;

    canvas.drawCircle(center, (innerR + outerR) / 2, paint);

    // Radial white/pastel tint gradient towards the inner edge
    final whiteShader = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.90),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: (innerR + outerR) / 2));

    final whitePaint = Paint()
      ..shader = whiteShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = (outerR - innerR) * 0.7;

    canvas.drawCircle(center, innerR + (outerR - innerR) * 0.35, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
