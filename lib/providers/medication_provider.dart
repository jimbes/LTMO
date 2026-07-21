import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication.dart';
import '../models/medication_schedule.dart';
import '../services/api_service.dart';
import '../services/local_notification_service.dart';
import '../utils/notification_routing.dart';
import 'auth_provider.dart';

final medicationBoxProvider = FutureProvider<Box<Medication>>((ref) async {
  return Hive.openBox<Medication>('medications_box');
});

final scheduleBoxProvider = FutureProvider<Box<MedicationSchedule>>((ref) async {
  return Hive.openBox<MedicationSchedule>('schedules_box');
});

final medicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);

  if (token == null) {
    return [];
  }

  try {
    final medications = await apiService.getMedications();
    final list = (medications as List)
        .map((m) => Medication.fromJson(m as Map<String, dynamic>))
        .toList();

    // Cache in Hive
    final box = await ref.read(medicationBoxProvider.future);
    for (var med in list) {
      await box.put(med.id, med);
    }

    return list;
  } catch (e) {
    // Fall back to local cache
    final box = await ref.read(medicationBoxProvider.future);
    return box.values.toList();
  }
});

final schedulesProvider = FutureProvider<List<MedicationSchedule>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);

  if (token == null) {
    return [];
  }

  try {
    final schedules = await apiService.getSchedules();
    final list = (schedules as List)
        .map((s) => MedicationSchedule.fromJson(s as Map<String, dynamic>))
        .toList();

    // Cache in Hive
    final box = await ref.read(scheduleBoxProvider.future);
    for (var schedule in list) {
      await box.put(schedule.id, schedule);
    }

    return list;
  } catch (e) {
    // Fall back to local cache
    final box = await ref.read(scheduleBoxProvider.future);
    return box.values.toList();
  }
});

final medicationProvider =
    StateNotifierProvider<MedicationNotifier, AsyncValue<void>>((ref) {
  return MedicationNotifier(ref);
});

class MedicationNotifier extends StateNotifier<AsyncValue<void>> {
  MedicationNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<Medication> addMedication(Medication medication) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);

      final data = {
        'name': medication.name,
        'dosage': medication.dosage,
        'unit': medication.unit,
        'form': medication.form,
        'for_partner': medication.forPartner,
        'description': medication.description,
      };

      final created = await apiService.createMedication(data);
      final createdMedication = Medication.fromJson(created);

      // Refresh the list
      ref.invalidate(medicationsProvider);
      state = const AsyncValue.data(null);
      return createdMedication;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);

      final data = {
        'name': medication.name,
        'dosage': medication.dosage,
        'unit': medication.unit,
        'form': medication.form,
        'for_partner': medication.forPartner,
        'description': medication.description,
      };

      await apiService.updateMedication(medication.id, data);

      // Refresh the list
      ref.invalidate(medicationsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      await apiService.deleteMedication(id);

      // Refresh the list
      ref.invalidate(medicationsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Medication? _findMedication(String medicationId) {
    final meds = ref.read(medicationsProvider).valueOrNull;
    if (meds == null) return null;
    try {
      return meds.firstWhere((m) => m.id == medicationId);
    } catch (_) {
      return null;
    }
  }

  Future<void> addSchedule(MedicationSchedule schedule) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);

      final data = {
        'medication_id': schedule.medicationId,
        'frequency': schedule.frequency,
        'days_of_week': schedule.daysOfWeek,
        'reminder_times': schedule.reminderTimes,
        'reminder_offsets': schedule.reminderOffsets,
        'notify_user_1': schedule.notifyUser1,
        'notify_user_2': schedule.notifyUser2,
        'start_date': schedule.startDate?.toIso8601String().split('T')[0],
        'end_date': schedule.endDate?.toIso8601String().split('T')[0],
        'journey_stage_id': schedule.journeyStageId,
      };

      final created = await apiService.createSchedule(data);
      final createdSchedule = MedicationSchedule.fromJson(created);

      if (shouldNotifyCurrentUser(
        ref,
        notifyUser1: createdSchedule.notifyUser1,
        notifyUser2: createdSchedule.notifyUser2,
      )) {
        await LocalNotificationService.instance.scheduleMedicationReminders(
          createdSchedule,
          _findMedication(createdSchedule.medicationId),
        );
      }

      // Refresh the list
      ref.invalidate(schedulesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSchedule(MedicationSchedule schedule) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);

      final data = {
        'frequency': schedule.frequency,
        'days_of_week': schedule.daysOfWeek,
        'reminder_times': schedule.reminderTimes,
        'reminder_offsets': schedule.reminderOffsets,
        'notify_user_1': schedule.notifyUser1,
        'notify_user_2': schedule.notifyUser2,
        'start_date': schedule.startDate?.toIso8601String().split('T')[0],
        'end_date': schedule.endDate?.toIso8601String().split('T')[0],
        'journey_stage_id': schedule.journeyStageId,
      };

      final updated = await apiService.updateSchedule(schedule.id, data);
      final updatedSchedule = MedicationSchedule.fromJson(updated);

      if (shouldNotifyCurrentUser(
        ref,
        notifyUser1: updatedSchedule.notifyUser1,
        notifyUser2: updatedSchedule.notifyUser2,
      )) {
        await LocalNotificationService.instance.scheduleMedicationReminders(
          updatedSchedule,
          _findMedication(updatedSchedule.medicationId),
        );
      } else {
        // Flag may have just been turned off for this user - clear any
        // reminders scheduled from before that change.
        await LocalNotificationService.instance
            .cancelMedicationReminders(updatedSchedule);
      }

      // Refresh the list
      ref.invalidate(schedulesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);

      final existingSchedules = ref.read(schedulesProvider).valueOrNull ?? [];
      final matches = existingSchedules.where((s) => s.id == id).toList();
      final schedule = matches.isEmpty ? null : matches.first;

      await apiService.deleteSchedule(id);

      if (schedule != null) {
        await LocalNotificationService.instance
            .cancelMedicationReminders(schedule);
      }

      // Refresh the list
      ref.invalidate(schedulesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
