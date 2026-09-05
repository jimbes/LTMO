import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/treatment_cycle_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/cycle_day.dart';

/// Small "J5" badge showing how far [date] falls into the current
/// treatment cycle. Renders nothing if there's no active cycle yet, or the
/// date falls before the cycle started.
class CycleDayBadge extends ConsumerWidget {
  final DateTime date;
  final bool compact;

  const CycleDayBadge({super.key, required this.date, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycle = ref.watch(currentCycleProvider).valueOrNull;
    final label = cycleDayLabel(date, cycle?.startDate);
    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.sageBgLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.sage,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
