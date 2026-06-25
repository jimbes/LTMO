import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/appointment.dart';

final appointmentBoxProvider = FutureProvider<Box<Appointment>>((ref) async {
  return Hive.openBox<Appointment>('appointments_box');
});

final appointmentsProvider = StreamProvider<List<Appointment>>((ref) async* {
  final box = await ref.watch(appointmentBoxProvider.future);
  yield box.values.toList();
  yield* box.watch().map((_) => box.values.toList());
});

final upcomingAppointmentsProvider = StreamProvider<List<Appointment>>((ref) async* {
  final box = await ref.watch(appointmentBoxProvider.future);
  yield _filterUpcoming(box.values.toList());
  yield* box.watch().map((_) {
    final now = DateTime.now();
    return box.values
        .where((a) => a.appointmentDate.isAfter(now) && !a.completed)
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  });
});

List<Appointment> _filterUpcoming(List<Appointment> appointments) {
  final now = DateTime.now();
  return appointments
      .where((a) => a.appointmentDate.isAfter(now) && !a.completed)
      .toList()
    ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
}

final appointmentProvider =
    StateNotifierProvider<AppointmentNotifier, AsyncValue<void>>((ref) {
  return AppointmentNotifier(ref);
});

class AppointmentNotifier extends StateNotifier<AsyncValue<void>> {
  AppointmentNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> addAppointment(Appointment appointment) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(appointmentBoxProvider.future);
      await box.put(appointment.id, appointment);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(appointmentBoxProvider.future);
      await box.put(appointment.id, appointment);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(appointmentBoxProvider.future);
      await box.delete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markComplete(String id) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(appointmentBoxProvider.future);
      final appointment = box.get(id);
      if (appointment != null) {
        await box.put(id, appointment.copyWith(completed: true));
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
