import 'package:flutter/material.dart';

const List<Color> presetColors = <Color>[
  Color(0xFFFF0000), // Pure Red
  Color(0xFFFF1744), // Crimson
  Color(0xFFFF5722), // Coral
  Color(0xFFFF9100), // Vivid Orange
  Color(0xFFFFC400), // Golden Amber
  Color(0xFFFFFF00), // Electric Yellow
  Color(0xFFAEEA00), // Chartreuse
  Color(0xFF76FF03), // Neon Lime
  Color(0xFF00FF00), // Pure Green
  Color(0xFF00C853), // Emerald
  Color(0xFF1DE9B6), // Mint Seafoam
  Color(0xFF00F5D4), // Vibrant Turquoise
  Color(0xFF00FFFF), // Pure Cyan
  Color(0xFF00E5FF), // Ice Blue
  Color(0xFF00B0FF), // Sky Blue
  Color(0xFF2979FF), // Electric Blue
  Color(0xFF0000FF), // Pure Blue
  Color(0xFF304FFE), // Deep Royal Blue
  Color(0xFF651FFF), // Electric Indigo
  Color(0xFF7C4DFF), // Vivid Violet
  Color(0xFFAA00FF), // Neon Purple
  Color(0xFFFF00FF), // Pure Magenta
  Color(0xFFFF1493), // Deep Hot Pink
  Color(0xFFFF4081), // Radiant Rose Pink
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
