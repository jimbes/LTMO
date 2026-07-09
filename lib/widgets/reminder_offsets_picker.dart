import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Common reminder lead times, in minutes before the event/dose. Covers
/// both short medication-dose offsets (15min, 30min, 1h) and longer
/// appointment ones (12h, 24h, 48h) in a single list since either kind of
/// reminder can reasonably use any of them.
const List<int> reminderOffsetPresets = [15, 30, 60, 120, 360, 720, 1440, 2880];

String formatReminderOffset(int minutes) {
  if (minutes < 60) return '$minutes min';
  if (minutes % 1440 == 0) {
    final days = minutes ~/ 1440;
    return days == 1 ? '1 jour' : '$days jours';
  }
  final hours = minutes ~/ 60;
  return hours == 1 ? '1h' : '${hours}h';
}

/// Lets the user pick any number of reminder lead times (e.g. both "1h
/// before" and "15min before" for the same dose/appointment). At least one
/// must stay selected - toggling off the last one is a no-op, since a
/// reminder with zero lead times firing would mean no reminder at all.
class ReminderOffsetsPicker extends StatelessWidget {
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  const ReminderOffsetsPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: reminderOffsetPresets.map((minutes) {
        final isSelected = selected.contains(minutes);
        return FilterChip(
          label: Text(formatReminderOffset(minutes)),
          selected: isSelected,
          onSelected: (value) {
            final updated = List<int>.from(selected);
            if (value) {
              updated.add(minutes);
            } else if (updated.length > 1) {
              updated.remove(minutes);
            } else {
              return;
            }
            updated.sort();
            onChanged(updated);
          },
          selectedColor: AppColors.sage,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.ink,
          ),
        );
      }).toList(),
    );
  }
}

/// Short "1h et 15min avant" style summary, used where space is tight
/// (e.g. a collapsed toggle row) instead of showing every chip.
String summarizeReminderOffsets(List<int> minutes) {
  if (minutes.isEmpty) return 'Aucun rappel';
  final sorted = List<int>.from(minutes)..sort();
  return '${sorted.map(formatReminderOffset).join(' et ')} avant';
}

class ReminderOffsetsLabel extends StatelessWidget {
  final List<int> offsets;

  const ReminderOffsetsLabel({super.key, required this.offsets});

  @override
  Widget build(BuildContext context) {
    return Text(
      summarizeReminderOffsets(offsets),
      style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
    );
  }
}
