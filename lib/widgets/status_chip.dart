import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusChip({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getStatusColor(status);
    final label = status.replaceAll('_', ' ').trim().toUpperCase();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.isNotEmpty ? label : 'SIN ESTADO',
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
