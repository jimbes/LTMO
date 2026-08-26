import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/treatment_cycle.dart';
import '../models/journey_stage.dart';
import 'auth_provider.dart';
import 'journey_provider.dart';

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
    await apiService.startNewTreatmentCycle();

    ref.invalidate(stagesProvider);
    ref.invalidate(currentCycleProvider);
    ref.invalidate(cycleHistoryProvider);
    await ref.read(stagesProvider.future);
    await ref.read(currentCycleProvider.future);
  }
}
