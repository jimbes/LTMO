import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication.dart';
import '../models/medication_schedule.dart';

final medicationBoxProvider = FutureProvider<Box<Medication>>((ref) async {
  return Hive.openBox<Medication>('medications_box');
});

final scheduleBoxProvider = FutureProvider<Box<MedicationSchedule>>((ref) async {
  return Hive.openBox<MedicationSchedule>('schedules_box');
});

final medicationsProvider = StreamProvider<List<Medication>>((ref) async* {
  final box = await ref.watch(medicationBoxProvider.future);
  yield box.values.toList();
  yield* box.watch().map((_) => box.values.toList());
});

final schedulesProvider = StreamProvider<List<MedicationSchedule>>((ref) async* {
  final box = await ref.watch(scheduleBoxProvider.future);
  yield box.values.toList();
  yield* box.watch().map((_) => box.values.toList());
});

final medicationProvider =
    StateNotifierProvider<MedicationNotifier, AsyncValue<void>>((ref) {
  return MedicationNotifier(ref);
});

class MedicationNotifier extends StateNotifier<AsyncValue<void>> {
  MedicationNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> addMedication(Medication medication) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(medicationBoxProvider.future);
      await box.put(medication.id, medication);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(medicationBoxProvider.future);
      await box.put(medication.id, medication);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(medicationBoxProvider.future);
      await box.delete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSchedule(MedicationSchedule schedule) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(scheduleBoxProvider.future);
      await box.put(schedule.id, schedule);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSchedule(MedicationSchedule schedule) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(scheduleBoxProvider.future);
      await box.put(schedule.id, schedule);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(scheduleBoxProvider.future);
      await box.delete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
