import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_schedule.dart';
import '../models/medication_taken_log.dart';
import '../models/appointment.dart';
import 'medication_provider.dart';
import 'appointment_provider.dart';
import 'medication_logs_provider.dart';

class TodayEvent {
  final String type; // 'medication' or 'appointment'
  final String id;
  final String title;
  final DateTime? time;
  final bool completed;

  TodayEvent({
    required this.type,
    required this.id,
    required this.title,
    this.time,
    required this.completed,
  });
}

final todayEventsProvider = StreamProvider<List<TodayEvent>>((ref) async* {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Get initial data
  final schedules = await ref.watch(schedulesProvider.future);
  final appointments = await ref.watch(appointmentsProvider.future);
  final logs = await ref.watch(medicationLogsProvider.future);

  yield _buildTodayEvents(today, schedules, appointments, logs);

  // Listen for changes
  ref.listen(schedulesProvider, (prev, next) {
    // Rebuild on changes
  });
});

List<TodayEvent> _buildTodayEvents(
  DateTime today,
  List<MedicationSchedule> schedules,
  List<Appointment> appointments,
  List<MedicationTakenLog> logs,
) {
  final events = <TodayEvent>[];

  // Add medications due today
  for (final schedule in schedules) {
    bool isDueToday = false;

    if (schedule.frequency == 'daily') {
      isDueToday = schedule.startDate.isBefore(today.add(const Duration(days: 1))) &&
          (schedule.endDate == null || schedule.endDate!.isAfter(today));
    } else if (schedule.frequency == 'specific_days' && schedule.daysOfWeek != null) {
      final todayDayOfWeek = today.weekday - 1;
      isDueToday = schedule.daysOfWeek!.contains(todayDayOfWeek) &&
          schedule.startDate.isBefore(today.add(const Duration(days: 1))) &&
          (schedule.endDate == null || schedule.endDate!.isAfter(today));
    }

    if (isDueToday) {
      for (final time in schedule.reminderTimes) {
        MedicationTakenLog? logEntry;
        try {
          logEntry = logs.firstWhere(
            (log) =>
                log.medicationScheduleId == schedule.id &&
                log.date.year == today.year &&
                log.date.month == today.month &&
                log.date.day == today.day,
          );
        } catch (_) {
          logEntry = null;
        }

        events.add(TodayEvent(
          type: 'medication',
          id: '${schedule.id}_$time',
          title: schedule.medicationId,
          time: _parseTime(time),
          completed: logEntry?.taken ?? false,
        ));
      }
    }
  }

  // Add appointments today
  for (final appointment in appointments) {
    if (appointment.appointmentDate.year == today.year &&
        appointment.appointmentDate.month == today.month &&
        appointment.appointmentDate.day == today.day) {
      events.add(TodayEvent(
        type: 'appointment',
        id: appointment.id,
        title: appointment.title,
        time: appointment.appointmentTime,
        completed: appointment.completed,
      ));
    }
  }

  // Sort by time
  events.sort((a, b) {
    if (a.time == null && b.time == null) return 0;
    if (a.time == null) return 1;
    if (b.time == null) return -1;
    return a.time!.compareTo(b.time!);
  });

  return events;
}

final todayProgressProvider = StreamProvider<Map<String, int>>((ref) async* {
  final events = await ref.watch(todayEventsProvider.future);
  final total = events.length;
  final completed = events.where((e) => e.completed).length;
  yield {'completed': completed, 'total': total};
});

DateTime? _parseTime(String timeStr) {
  try {
    final parts = timeStr.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  } catch (_) {
    return null;
  }
}
