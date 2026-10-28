import 'package:flutter/material.dart';

const List<Color> presetColors = <Color>[
  Color(0xFFFF0000), // Red
  Color(0xFF00FF00), // Green
  Color(0xFF0000FF), // Blue
  Color(0xFFFFFF00), // Yellow
  Color(0xFF00FFFF), // Cyan
  Color(0xFFFF00FF), // Magenta
  Color(0xFFFF8800), // Orange
  Color(0xFF8800FF), // Purple
  Color(0xFFFF0088), // Pink
  Color(0xFF00FF88), // Mint
  Color(0xFF88FF00), // Lime
  Color(0xFF0088FF), // Sky Blue
  Color(0xFFFFD1A4), // Warm White
  Color(0xFFE6F0FF), // Cool White
  Color(0xFFFFFFFF), // Pure White
  Color(0xFFFF4500), // Flame
];

class ColorSwatches extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onSelectColor;

  const ColorSwatches({
    super.key,
    required this.selectedColor,
    required this.onSelectColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: presetColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final color = presetColors[index];
          final isSelected = color.value == selectedColor.value;

          return GestureDetector(
            onTap: () => onSelectColor(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isSelected ? 42 : 36,
              height: isSelected ? 42 : 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: isSelected ? 3 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
