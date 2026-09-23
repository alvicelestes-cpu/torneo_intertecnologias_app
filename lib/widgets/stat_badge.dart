import 'package:flutter/material.dart';

class StatBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final double fontSize;

  const StatBadge({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    this.fontSize = 11,
  });

  factory StatBadge.goles(int goles) {
    return StatBadge(
      emoji: '⚽',
      label: 'GOLES',
      value: goles,
      bgColor: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFFC8E6C9),
      textColor: const Color(0xFF2E7D32),
    );
  }

  factory StatBadge.amarillas(int amarillas) {
    return StatBadge(
      emoji: '🟨',
      label: 'AMARILLAS',
      value: amarillas,
      bgColor: const Color(0xFFFFFDE7),
      borderColor: const Color(0xFFFFF59D),
      textColor: const Color(0xFFF57F17),
    );
  }

  factory StatBadge.rojas(int rojas) {
    return StatBadge(
      emoji: '🟥',
      label: 'ROJAS',
      value: rojas,
      bgColor: const Color(0xFFFFEBEE),
      borderColor: const Color(0xFFFFCDD2),
      textColor: const Color(0xFFC62828),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
