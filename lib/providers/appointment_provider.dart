import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/appointment.dart';
import '../models/pending_action.dart';
import '../services/api_service.dart';
import '../services/local_notification_service.dart';
import '../utils/notification_routing.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';
import 'sync_queue_provider.dart';

final appointmentBoxProvider = FutureProvider<Box<Appointment>>((ref) async {
  return Hive.openBox<Appointment>('appointments_box');
});

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);

  if (token == null) {
    return [];
  }

  try {
    final appointments = await apiService.getAppointments();
    final list = (appointments as List)
        .map((a) => Appointment.fromJson(a as Map<String, dynamic>))
        .toList();

    // Cache in Hive
    final box = await ref.read(appointmentBoxProvider.future);
    for (var apt in list) {
      await box.put(apt.id, apt);
    }

    return list;
  } catch (e) {
    // Fall back to local cache
    final box = await ref.read(appointmentBoxProvider.future);
    return box.values.toList();
  }
});

final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final appointments = await ref.watch(appointmentsProvider.future);
  return _filterUpcoming(appointments);
});

List<Appointment> _filterUpcoming(List<Appointment> appointments) {
  final now = DateTime.now();
  return appointments
      .where((a) {
        final compareTime = a.appointmentTime ?? a.appointmentDate;
        return compareTime.isAfter(now) && !a.completed;
      })
      .toList()
    ..sort((a, b) {
      final aTime = a.appointmentTime ?? a.appointmentDate;
      final bTime = b.appointmentTime ?? b.appointmentDate;
      return aTime.compareTo(bTime);
    });
}

final appointmentProvider =
    StateNotifierProvider<AppointmentNotifier, AsyncValue<void>>((ref) {
  return AppointmentNotifier(ref);
});

class AppointmentNotifier extends StateNotifier<AsyncValue<void>> {
  AppointmentNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  String? _formatTime(DateTime? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<Appointment> addAppointment(Appointment appointment) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);

      final data = {
        'title': appointment.title,
        'appointment_date': appointment.appointmentDate.toIso8601String().split('T')[0],
        'appointment_time': _formatTime(appointment.appointmentTime),
        'types': appointment.types,
        'reminder_offsets': appointment.reminderOffsets,
        'location': appointment.location,
        'doctor_name': appointment.doctorName,
        'description': appointment.description,
        'notify_user_1': appointment.notifyUser1,
        'notify_user_2': appointment.notifyUser2,
        'journey_stage_id': appointment.journeyStageId,
      };

      Appointment createdAppointment;
      try {
        final created = await apiService.createAppointment(data);
        createdAppointment = Appointment.fromJson(created);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // Offline: keep a locally-generated id until the queued create
        // syncs and the next successful fetch replaces it with the real one.
        createdAppointment = appointment.copyWith(id: PendingAction.newId());
        await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
              id: PendingAction.newId(),
              entityType: 'appointment',
              operation: 'create',
              payload: data,
              createdAt: DateTime.now(),
            ));
        final box = await ref.read(appointmentBoxProvider.future);
        await box.put(createdAppointment.id, createdAppointment);
      }

      if (shouldNotifyCurrentUser(
        ref,
        notifyUser1: createdAppointment.notifyUser1,
        notifyUser2: createdAppointment.notifyUser2,
      )) {
        await LocalNotificationService.instance
            .scheduleAppointmentReminder(createdAppointment);
      }

      // Refresh the list
      ref.invalidate(appointmentsProvider);
      state = const AsyncValue.data(null);
      return createdAppointment;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);

      final data = {
        'title': appointment.title,
        'appointment_date': appointment.appointmentDate.toIso8601String().split('T')[0],
        'appointment_time': _formatTime(appointment.appointmentTime),
        'types': appointment.types,
        'reminder_offsets': appointment.reminderOffsets,
        'location': appointment.location,
        'doctor_name': appointment.doctorName,
        'description': appointment.description,
        'notify_user_1': appointment.notifyUser1,
        'notify_user_2': appointment.notifyUser2,
        'journey_stage_id': appointment.journeyStageId,
      };

      Appointment updatedAppointment;
      try {
        final updated = await apiService.updateAppointment(appointment.id, data);
        updatedAppointment = Appointment.fromJson(updated);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        updatedAppointment = appointment;
        await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
              id: PendingAction.newId(),
              entityType: 'appointment',
              operation: 'update',
              targetId: appointment.id,
              payload: data,
              knownUpdatedAt: appointment.updatedAt.toIso8601String(),
              createdAt: DateTime.now(),
            ));
        final box = await ref.read(appointmentBoxProvider.future);
        await box.put(appointment.id, appointment);
      }

      if (shouldNotifyCurrentUser(
        ref,
        notifyUser1: updatedAppointment.notifyUser1,
        notifyUser2: updatedAppointment.notifyUser2,
      )) {
        await LocalNotificationService.instance
            .scheduleAppointmentReminder(updatedAppointment);
      } else {
        // Flag may have just been turned off for this user - clear any
        // reminder scheduled from before that change.
        await LocalNotificationService.instance
            .cancelAppointmentReminder(updatedAppointment.id);
      }

      // Refresh the list
      ref.invalidate(appointmentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final box = await ref.read(appointmentBoxProvider.future);
      final existing = box.get(id);

      try {
        await apiService.deleteAppointment(id);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
              id: PendingAction.newId(),
              entityType: 'appointment',
              operation: 'delete',
              targetId: id,
              payload: const {},
              knownUpdatedAt: existing?.updatedAt.toIso8601String(),
              createdAt: DateTime.now(),
            ));
        await box.delete(id);
      }

      await LocalNotificationService.instance.cancelAppointmentReminder(id);

      // Refresh the list
      ref.invalidate(appointmentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> markComplete(String id) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final box = await ref.read(appointmentBoxProvider.future);
      final existing = box.get(id);

      try {
        await apiService.updateAppointment(id, {'completed': true});
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
              id: PendingAction.newId(),
              entityType: 'appointment',
              operation: 'update',
              targetId: id,
              payload: const {'completed': true},
              knownUpdatedAt: existing?.updatedAt.toIso8601String(),
              createdAt: DateTime.now(),
            ));
        if (existing != null) {
          await box.put(id, existing.copyWith(completed: true));
        }
      }

      await LocalNotificationService.instance.cancelAppointmentReminder(id);

      // Refresh the list
      ref.invalidate(appointmentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
