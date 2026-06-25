import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PhaseBadge extends StatelessWidget {
  final String phase;
  final Color? backgroundColor;
  final Color? textColor;

  const PhaseBadge({
    required this.phase,
    this.backgroundColor,
    this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.sageBgLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        phase,
        style: AppTypography.labelSmall.copyWith(
          color: textColor ?? AppColors.sage,
        ),
      ),
    );
  }
}
