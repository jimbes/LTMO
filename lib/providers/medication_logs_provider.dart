import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication_taken_log.dart';

final logBoxProvider = FutureProvider<Box<MedicationTakenLog>>((ref) async {
  return Hive.openBox<MedicationTakenLog>('logs_box');
});

final medicationLogsProvider = StreamProvider<List<MedicationTakenLog>>((ref) async* {
  final box = await ref.watch(logBoxProvider.future);
  yield box.values.toList();
  yield* box.watch().map((_) => box.values.toList());
});

final medicationLogNotifier =
    StateNotifierProvider<MedicationLogNotifier, AsyncValue<void>>((ref) {
  return MedicationLogNotifier(ref);
});

class MedicationLogNotifier extends StateNotifier<AsyncValue<void>> {
  MedicationLogNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> addLog(MedicationTakenLog log) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(logBoxProvider.future);
      await box.put(log.id, log);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLog(MedicationTakenLog log) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(logBoxProvider.future);
      await box.put(log.id, log);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(logBoxProvider.future);
      await box.delete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markTaken(String scheduleId, DateTime date) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(logBoxProvider.future);
      final logId = '${scheduleId}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      
      var log = box.get(logId);
      if (log == null) {
        log = MedicationTakenLog(
          id: logId,
          medicationScheduleId: scheduleId,
          date: date,
          taken: true,
          takenAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        log = log.copyWith(taken: true, takenAt: DateTime.now());
      }
      await box.put(logId, log);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markNotTaken(String scheduleId, DateTime date) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(logBoxProvider.future);
      final logId = '${scheduleId}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      
      var log = box.get(logId);
      if (log != null) {
        log = log.copyWith(taken: false, takenAt: null);
        await box.put(logId, log);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
