import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journey_stage.dart';
import '../models/pending_action.dart';
import '../models/treatment_cycle.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';
import 'journey_provider.dart';
import 'sync_queue_provider.dart';

final currentCycleProvider = FutureProvider<TreatmentCycle?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);
  if (token == null) return null;

  final data = await apiService.getCurrentTreatmentCycle();
  if (data.isEmpty) return null;
  return TreatmentCycle.fromJson(data);
});

final cycleHistoryProvider = FutureProvider<List<TreatmentCycle>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);
  if (token == null) return [];

  final data = await apiService.getTreatmentCycles();
  return data
      .map((c) => TreatmentCycle.fromJson(c as Map<String, dynamic>))
      .toList();
});

/// Read-only stages of a past (archived) cycle, for the history view.
final cycleStagesProvider =
    FutureProvider.family<List<JourneyStage>, String>((ref, cycleId) async {
  final apiService = ref.watch(apiServiceProvider);
  final data = await apiService.getTreatmentCycleStages(cycleId);
  final stages = data
      .map((s) => JourneyStage.fromJson(s as Map<String, dynamic>))
      .toList();
  stages.sort((a, b) => a.order.compareTo(b.order));
  return stages;
});

final treatmentCycleActionsProvider =
    Provider((ref) => TreatmentCycleActions(ref));

class TreatmentCycleActions {
  TreatmentCycleActions(this.ref);

  final Ref ref;

  Future<void> startNewCycle() async {
    final apiService = ref.read(apiServiceProvider);

    try {
      await apiService.startNewTreatmentCycle();
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      // Nothing meaningful to write locally (no cache of cycles exists) -
      // just queue it. The next successful sync creates the real cycle.
      await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
            id: PendingAction.newId(),
            entityType: 'treatment_cycle',
            operation: 'create',
            payload: const {},
            createdAt: DateTime.now(),
          ));
    }

    ref.invalidate(stagesProvider);
    ref.invalidate(currentCycleProvider);
    ref.invalidate(cycleHistoryProvider);
    try {
      await ref.read(stagesProvider.future);
      await ref.read(currentCycleProvider.future);
    } catch (_) {
      // Still offline - the invalidation above is enough; the UI picks up
      // fresh data once processQueue() succeeds later.
    }
  }
}
