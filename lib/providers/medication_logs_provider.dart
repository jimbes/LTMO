import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication_taken_log.dart';
import '../models/pending_action.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';
import 'sync_queue_provider.dart';

final logBoxProvider = FutureProvider<Box<MedicationTakenLog>>((ref) async {
  return Hive.openBox<MedicationTakenLog>('logs_box');
});

/// The composite key used everywhere in the app to identify "this schedule,
/// on this reminder time, on this day" - matches what markTaken/markNotTaken
/// write, so a fetched log always overwrites the right local cache entry
/// regardless of the server's own numeric id. A schedule with several
/// reminder times a day needs `time` to tell those doses apart - without it
/// they'd all collapse onto one shared entry (checking one checks all).
String _logKey(String scheduleId, DateTime date, String? time) {
  final day = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  return '${scheduleId}_${day}_${time ?? ''}';
}

final medicationLogsProvider =
    FutureProvider<List<MedicationTakenLog>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);

  if (token == null) {
    return [];
  }

  try {
    final raw = await apiService.getMedicationTakenLogs();
    final list = raw.map((json) {
      final log = MedicationTakenLog.fromJson(json as Map<String, dynamic>);
      // Re-key to the composite id so it lines up with logs written locally
      // (e.g. right after a markTaken call, before the refetch lands).
      return log.copyWith(
        id: _logKey(log.medicationScheduleId, log.date, log.time),
      );
    }).toList();

    final box = await ref.read(logBoxProvider.future);
    await box.clear();
    for (var log in list) {
      await box.put(log.id, log);
    }

    return list;
  } catch (e) {
    // Fall back to local cache (e.g. offline) - the couple's partner won't
    // see this device's changes until connectivity is back, but at least
    // this device's own history stays visible.
    final box = await ref.read(logBoxProvider.future);
    return box.values.toList();
  }
});

final medicationLogNotifier =
    StateNotifierProvider<MedicationLogNotifier, AsyncValue<void>>((ref) {
  return MedicationLogNotifier(ref);
});

class MedicationLogNotifier extends StateNotifier<AsyncValue<void>> {
  MedicationLogNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  String _dateParam(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _writeLocal(
    String scheduleId,
    DateTime date,
    String? time,
    bool taken,
  ) async {
    final box = await ref.read(logBoxProvider.future);
    final key = _logKey(scheduleId, date, time);
    final existing = box.get(key);
    final log = (existing ??
            MedicationTakenLog(
              id: key,
              medicationScheduleId: scheduleId,
              date: date,
              taken: taken,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              time: time,
            ))
        .copyWith(
      taken: taken,
      takenAt: taken ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    await box.put(key, log);
  }

  /// Marks a dose taken/not-taken on the server so the partner sees it too,
  /// not just this device. [time] identifies which reminder slot (e.g.
  /// "08:00") for schedules with more than one dose a day - omit only for
  /// schedules that genuinely have a single daily dose. Writes to the local
  /// cache immediately (so the UI reacts instantly) then syncs with the
  /// server and refetches.
  Future<void> _markAndSync(
    String scheduleId,
    DateTime date,
    String? time,
    bool taken,
  ) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(logBoxProvider.future);
      final knownUpdatedAt = box.get(_logKey(scheduleId, date, time))?.updatedAt;

      await _writeLocal(scheduleId, date, time, taken);
      final apiService = ref.read(apiServiceProvider);

      try {
        if (taken) {
          await apiService.markMedicationTaken(scheduleId, _dateParam(date), time: time);
        } else {
          await apiService.markMedicationNotTaken(scheduleId, _dateParam(date), time: time);
        }
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // The local write above already happened, so the UI already
        // reflects this - just queue it to reach the server later.
        await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
              id: PendingAction.newId(),
              entityType: 'medication_taken_log',
              operation: 'update',
              payload: {
                'schedule_id': scheduleId,
                'date': _dateParam(date),
                'time': time,
                'taken': taken,
              },
              knownUpdatedAt: knownUpdatedAt?.toIso8601String(),
              createdAt: DateTime.now(),
            ));
      }

      ref.invalidate(medicationLogsProvider);
      await ref.read(medicationLogsProvider.future);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> markTaken(String scheduleId, DateTime date, {String? time}) {
    return _markAndSync(scheduleId, date, time, true);
  }

  Future<void> markNotTaken(String scheduleId, DateTime date, {String? time}) {
    return _markAndSync(scheduleId, date, time, false);
  }
}
