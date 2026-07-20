import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/journey_stage.dart';
import 'auth_provider.dart';

export '../utils/phase_labels.dart' show defaultJourneyStageTypes;

final stageBoxProvider = FutureProvider<Box<JourneyStage>>((ref) async {
  return Hive.openBox<JourneyStage>('stages_box');
});

final stagesProvider = FutureProvider<List<JourneyStage>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);

  if (token == null) {
    return [];
  }

  try {
    final stages = await apiService.getJourneyStages();
    final list = stages
        .map((s) => JourneyStage.fromJson(s as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => a.order.compareTo(b.order));

    // Cache in Hive
    final box = await ref.read(stageBoxProvider.future);
    await box.clear();
    for (var stage in list) {
      await box.put(stage.id, stage);
    }

    return list;
  } catch (e) {
    // Fall back to local cache
    final box = await ref.read(stageBoxProvider.future);
    final cached = box.values.toList();
    cached.sort((a, b) => a.order.compareTo(b.order));
    return cached;
  }
});

final currentPhaseProvider = FutureProvider<JourneyStage?>((ref) async {
  final stages = await ref.watch(stagesProvider.future);
  return _getCurrentPhase(stages);
});

JourneyStage? _getCurrentPhase(List<JourneyStage> stages) {
  for (final stage in stages) {
    if (stage.status == 'in_progress') {
      return stage;
    }
  }
  return stages.isNotEmpty ? stages.first : null;
}

final journeyProvider =
    StateNotifierProvider<JourneyNotifier, AsyncValue<void>>((ref) {
  return JourneyNotifier(ref);
});

class JourneyNotifier extends StateNotifier<AsyncValue<void>> {
  JourneyNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Recomputes start/end dates for a chain of stages, ordered start to finish.
  /// Every stage except the last one gets its end date derived from its
  /// duration, UNLESS `manualEndDate` is set (user override), in which case
  /// its own end date is kept as-is. The next stage starts the day AFTER
  /// whatever end date resulted (a stage ending on D doesn't overlap with
  /// the one starting the same day), UNLESS that next stage has
  /// `manualStartDate` set, in which case its own start date is kept as-is
  /// (e.g. a finished stage is followed by a gap before the next one starts
  /// on a specific future date). The last stage always keeps a manually set
  /// end date (only meaningful once done).
  List<JourneyStage> _recomputeChain(List<JourneyStage> stages) {
    final result = <JourneyStage>[];
    DateTime? previousEnd;

    for (var i = 0; i < stages.length; i++) {
      final isLast = i == stages.length - 1;
      var stage = stages[i];

      final start = i == 0
          ? stage.startDate
          : (stage.manualStartDate
              ? stage.startDate
              : (previousEnd != null
                  ? previousEnd.add(const Duration(days: 1))
                  : stage.startDate));

      DateTime? end;
      if (!isLast && !stage.manualEndDate) {
        final days = stage.durationDays ?? 1;
        end = DateTime(start.year, start.month, start.day)
            .add(Duration(days: days));
      } else {
        // Last stage, or a non-last stage with a manual end date override:
        // keep the manually set end date, unless an upstream change pushed
        // this stage's start date past it (which would make it invalid -
        // end before start).
        end = stage.endDate;
        if (end != null && end.isBefore(start)) {
          end = null;
        }
      }

      stage = stage.copyWith(
        order: i,
        startDate: start,
        endDate: end,
        clearEndDate: end == null,
      );
      result.add(stage);
      previousEnd = end;
    }

    return result;
  }

  Map<String, dynamic> _toApiPayload(JourneyStage stage) {
    return {
      'type': stage.type,
      'custom_name': stage.customName,
      'order': stage.order,
      'start_date': stage.startDate.toIso8601String().split('T')[0],
      'start_time': stage.startTime,
      'end_date': stage.endDate?.toIso8601String().split('T')[0],
      'duration_days': stage.durationDays,
      'manual_end_date': stage.manualEndDate,
      'manual_start_date': stage.manualStartDate,
      'status': stage.status,
      'reminder_enabled': stage.reminderEnabled,
      'notes': stage.notes,
    };
  }

  Future<void> _persistAll(List<JourneyStage> stages) async {
    final apiService = ref.read(apiServiceProvider);
    for (final stage in stages) {
      await apiService.updateJourneyStage(stage.id, _toApiPayload(stage));
    }
    // Invalidate and wait for the refetch to complete so that by the time
    // this returns, any widget watching stagesProvider already has the
    // fresh data on its next build (no race with the caller closing a sheet).
    ref.invalidate(stagesProvider);
    await ref.read(stagesProvider.future);
  }

  /// Adds a new stage of [type] at the end of the chain.
  Future<void> addStageAtEnd(String type) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final current = await ref.read(stagesProvider.future);

      final previousEnd = current.isNotEmpty ? current.last.endDate : null;
      final start = previousEnd ?? DateTime.now();
      final now = DateTime.now();

      final newStage = JourneyStage(
        id: '',
        coupleId: '',
        type: type,
        order: current.length,
        startDate: start,
        durationDays: 3,
        status: 'upcoming',
        reminderEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      // If this new stage becomes the last one, the previously-last stage
      // (if any) is no longer the last, so it needs a duration instead of a
      // manual end date. Recompute the whole chain including the new stage.
      final withNew = [...current, newStage];
      final recomputed = _recomputeChain(withNew);

      // Create the new stage on the server first to get a real id
      final createdData = _toApiPayload(recomputed.last);
      final created = await apiService.createJourneyStage(createdData);
      final createdId = created['id'].toString();

      // Persist recomputed dates for the existing stages (order/end date may
      // have shifted now that a new stage follows them)
      final existingRecomputed =
          recomputed.sublist(0, recomputed.length - 1);
      await _persistAll(existingRecomputed);

      // Ensure the newly created stage also has the right order (already
      // correct from createdData, but re-send in case of race conditions)
      await apiService.updateJourneyStage(
        createdId,
        _toApiPayload(recomputed.last),
      );

      ref.invalidate(stagesProvider);
      await ref.read(stagesProvider.future);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Removes a stage and re-chains the remaining ones.
  Future<void> removeStage(String id) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final current = await ref.read(stagesProvider.future);

      await apiService.deleteJourneyStage(id);

      final remaining = current.where((s) => s.id != id).toList();
      final recomputed = _recomputeChain(remaining);
      await _persistAll(recomputed);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Reorders stages to match [newOrder] and re-chains dates accordingly.
  Future<void> reorderStages(List<JourneyStage> newOrder) async {
    try {
      state = const AsyncValue.loading();
      final recomputed = _recomputeChain(newOrder);
      await _persistAll(recomputed);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Updates a single stage's editable fields (duration for non-last stages,
  /// manual end date for the last stage, status, notes, etc.) and re-chains
  /// the whole list since a duration change shifts everything after it.
  Future<void> updateStage(JourneyStage updatedStage) async {
    try {
      state = const AsyncValue.loading();
      final current = await ref.read(stagesProvider.future);

      final replaced = current
          .map((s) => s.id == updatedStage.id ? updatedStage : s)
          .toList();
      replaced.sort((a, b) => a.order.compareTo(b.order));

      final recomputed = _recomputeChain(replaced);
      await _persistAll(recomputed);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Marks [stageId] as the couple's current phase (used by the post-visit
  /// update flow). Unlike the rest of this notifier, this does NOT run the
  /// date-chain recompute - phases are informational tags now, not a
  /// scheduling mechanism, so there's no cascade to maintain. Only the
  /// newly-current and previously-current stages are touched.
  Future<void> setCurrentStage(String stageId) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final current = await ref.read(stagesProvider.future);

      final previouslyCurrent = current
          .where((s) => s.status == 'in_progress' && s.id != stageId);
      for (final stage in previouslyCurrent) {
        await apiService.updateJourneyStage(
          stage.id,
          {'status': 'done'},
        );
      }

      final target = current.firstWhere((s) => s.id == stageId);
      await apiService.updateJourneyStage(
        stageId,
        {
          'status': 'in_progress',
          // Only stamp a start date if this stage never had one recorded
          // (a fresh "tag" pick) - don't overwrite genuine historical data.
          if (target.status == 'upcoming')
            'start_date':
                DateTime.now().toIso8601String().split('T')[0],
        },
      );

      ref.invalidate(stagesProvider);
      await ref.read(stagesProvider.future);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> closeStage(String id) async {
    try {
      state = const AsyncValue.loading();
      final current = await ref.read(stagesProvider.future);
      final today = DateTime.now();

      final replaced = current.map((s) {
        if (s.id != id) return s;
        return s.copyWith(status: 'done', endDate: today);
      }).toList();

      final recomputed = _recomputeChain(replaced);
      await _persistAll(recomputed);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
