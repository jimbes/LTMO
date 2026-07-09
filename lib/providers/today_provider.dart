import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_schedule.dart';
import '../models/medication_taken_log.dart';
import '../models/medication.dart';
import '../models/appointment.dart';
import '../models/journey_stage.dart';
import '../utils/schedule_due.dart';
import 'medication_provider.dart';
import 'appointment_provider.dart';
import 'medication_logs_provider.dart';
import 'journey_provider.dart';

class TodayEvent {
  final String type; // 'medication' or 'appointment'
  final String id;
  final String title;
  final String? subtitle; // medication form or appointment location
  final DateTime? time;
  final bool completed;
  final String? scheduleId;
  final DateTime? date;
  // The raw "HH:mm" reminder time slot (medication events only) - needed to
  // mark just this dose taken, since a schedule can have several reminder
  // times a day that must be tracked independently.
  final String? reminderTime;

  TodayEvent({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    this.time,
    required this.completed,
    this.scheduleId,
    this.date,
    this.reminderTime,
  });
}

final todayEventsProvider = FutureProvider<List<TodayEvent>>((ref) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Watch schedules, appointments, medications, journey stages, and logs
  final schedules = await ref.watch(schedulesProvider.future);
  final appointments = await ref.watch(appointmentsProvider.future);
  final medications = await ref.watch(medicationsProvider.future);
  final logs = await ref.watch(medicationLogsProvider.future);
  final stages = await ref.watch(stagesProvider.future);

  return _buildTodayEvents(
      today, schedules, appointments, medications, logs, stages);
});

List<TodayEvent> _buildTodayEvents(
  DateTime today,
  List<MedicationSchedule> schedules,
  List<Appointment> appointments,
  List<Medication> medications,
  List<MedicationTakenLog> logs,
  List<JourneyStage> stages,
) {
  final events = <TodayEvent>[];

  // Build a map of medication id -> medication for quick lookup
  final medMap = {for (var med in medications) med.id: med};

  // Add medications due today
  for (final schedule in schedules) {
    // When a schedule is linked to a journey stage, the stage's own date
    // range governs whether it's due today - not the schedule's own dates
    // (which are otherwise ignored once linked). Without this, a medication
    // whose stage hasn't started yet, or already ended, still showed up
    // here forever since it has no end date of its own.
    final isDueToday = isScheduleDueOn(schedule, stages, today);

    if (isDueToday) {
      final medication = medMap[schedule.medicationId];
      // Orphaned schedule (its medication was deleted but the row somehow
      // survived) - skip rather than showing the raw medication id as a title.
      if (medication == null) continue;

      for (final time in schedule.reminderTimes) {
        MedicationTakenLog? logEntry;
        try {
          logEntry = logs.firstWhere(
            (log) =>
                log.medicationScheduleId == schedule.id &&
                log.date.year == today.year &&
                log.date.month == today.month &&
                log.date.day == today.day &&
                log.time == time,
          );
        } catch (_) {
          logEntry = null;
        }

        final subtitle =
            '${medication.dosage} ${medication.unit}${medication.form != null ? ' · ${medication.form}' : ''}';

        events.add(TodayEvent(
          type: 'medication',
          id: '${schedule.id}_$time',
          title: medication.name,
          subtitle: subtitle,
          time: _parseTime(time),
          completed: logEntry?.taken ?? false,
          scheduleId: schedule.id,
          date: today,
          reminderTime: time,
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
        subtitle: appointment.location,
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

final todayProgressProvider = FutureProvider<Map<String, int>>((ref) async {
  final events = await ref.watch(todayEventsProvider.future);
  final total = events.length;
  final completed = events.where((e) => e.completed).length;
  return {'completed': completed, 'total': total};
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
