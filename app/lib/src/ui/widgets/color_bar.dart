import 'package:flutter/material.dart';

class ColorBar extends StatelessWidget {
  final Color color;
  final int brightness;
  final bool power;

  const ColorBar({
    super.key,
    required this.color,
    required this.brightness,
    required this.power,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = power ? color : const Color(0xFF181818);
    final glowOpacity = power ? (brightness / 100.0).clamp(0.15, 0.8) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: power ? activeColor.withValues(alpha: 0.6) : Colors.white12,
          width: 1.5,
        ),
        boxShadow: power
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: glowOpacity),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Internal gradient reflection
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    activeColor.withValues(alpha: power ? 0.85 : 0.1),
                    activeColor,
                    activeColor.withValues(alpha: power ? 0.85 : 0.1),
                  ],
                ),
              ),
            ),
            // LED Segment dots mimicking strip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                12,
                (i) => Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: power
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.white10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
