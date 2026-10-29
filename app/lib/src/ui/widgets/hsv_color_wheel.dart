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
                // Cached, mathematically circular HSV Color Wheel & Radial Glow
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: _HsvWheelPainter(
                      radius: radius,
                      activeColor: widget.currentColor,
                      power: widget.power,
                    ),
                  ),
                ),
                // Selector thumb (independent repaint layer)
                Positioned(
                  left: currentSelector.dx - 14,
                  top: currentSelector.dy - 14,
                  child: RepaintBoundary(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.currentColor,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ],
                      ),
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
                      color: const Color(0xFF141416),
                      border: Border.all(
                        color: widget.power
                            ? widget.currentColor.withOpacity(0.8)
                            : Colors.white12,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.power_settings_new,
                        size: size * 0.16,
                        color: widget.power
                            ? widget.currentColor
                            : const Color(0xFF52525B),
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
  final Color activeColor;
  final bool power;

  // Pre-generated 360-degree smooth hues for perfectly continuous circular interpolation
  static final List<Color> _smoothHues = List<Color>.generate(
    361,
    (deg) => HSVColor.fromAHSV(1.0, deg.toDouble(), 1.0, 1.0).toColor(),
  );

  _HsvWheelPainter({
    required this.radius,
    required this.activeColor,
    required this.power,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerR = radius * 0.40;
    final outerR = radius * 0.88;
    final ringCenterR = (innerR + outerR) / 2;
    final strokeW = outerR - innerR;

    // 1. Soft Circular Ambient Glow (drawn on canvas as a true circle, never clipped into a box)
    if (power) {
      final glowPaint = Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          colors: [
            activeColor.withOpacity(0.25),
            activeColor.withOpacity(0.08),
            Colors.transparent,
          ],
          stops: const [0.4, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: outerR * 1.15));

      canvas.drawCircle(center, outerR * 1.15, glowPaint);
    }

    // 2. Continuous 360-Stop Sweep Gradient Hue Ring
    final sweepGradient = SweepGradient(
      colors: _smoothHues,
      startAngle: 0.0,
      endAngle: 2 * math.pi,
    );

    final huePaint = Paint()
      ..isAntiAlias = true
      ..shader = sweepGradient.createShader(
        Rect.fromCircle(center: center, radius: outerR),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    canvas.drawCircle(center, ringCenterR, huePaint);

    // 3. True Radial White/Pastel Saturation Desaturation Gradient
    // Centered at circle center, smoothly blending from white at innerR to transparent at outerR
    final satShader = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.95),
        Colors.white.withOpacity(0.85),
        Colors.white.withOpacity(0.0),
      ],
      stops: [
        0.0,
        innerR / outerR,
        1.0,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: outerR));

    final satPaint = Paint()
      ..isAntiAlias = true
      ..shader = satShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    canvas.drawCircle(center, ringCenterR, satPaint);

    // 4. Subtle inner & outer rim anti-aliasing borders
    final rimPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0x33FFFFFF);

    canvas.drawCircle(center, outerR, rimPaint);
    canvas.drawCircle(center, innerR, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _HsvWheelPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.power != power ||
        (power && oldDelegate.activeColor != activeColor);
  }
}
