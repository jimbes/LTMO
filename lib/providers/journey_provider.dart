import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/journey_stage.dart';
import '../models/pending_action.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';
import 'sync_queue_provider.dart';

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
  final active = stages.where((s) => s.status != 'skipped');
  return active.isNotEmpty ? active.first : null;
}

final journeyProvider =
    StateNotifierProvider<JourneyNotifier, AsyncValue<void>>((ref) {
  return JourneyNotifier(ref);
});

class JourneyNotifier extends StateNotifier<AsyncValue<void>> {
  JourneyNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Recomputes start/end dates for a chain of stages, ordered start to finish.
  /// Every stage's end date is derived from its duration, UNLESS
  /// `manualEndDate` is set (user override - available for every stage,
  /// including the last one), in which case its own end date is kept as-is.
  /// The next stage starts the day AFTER whatever end date resulted (a
  /// stage ending on D doesn't overlap with the one starting the same day),
  /// UNLESS that next stage has `manualStartDate` set, in which case its own
  /// start date is kept as-is (e.g. a finished stage is followed by a gap
  /// before the next one starts on a specific future date).
  List<JourneyStage> _recomputeChain(List<JourneyStage> stages) {
    final result = <JourneyStage>[];
    DateTime? previousEnd;

    for (var i = 0; i < stages.length; i++) {
      var stage = stages[i];

      if (stage.status == 'skipped') {
        // Excluded from the date chain entirely: keep its own dates as-is
        // and don't let it push where the next stage starts - the chain
        // continues from the last non-skipped stage's end.
        result.add(stage.copyWith(order: i));
        continue;
      }

      final start = i == 0
          ? stage.startDate
          : (stage.manualStartDate
              ? stage.startDate
              : (previousEnd != null
                  ? previousEnd.add(const Duration(days: 1))
                  : stage.startDate));

      DateTime? end;
      if (!stage.manualEndDate) {
        final days = stage.durationDays ?? 1;
        end = DateTime(start.year, start.month, start.day)
            .add(Duration(days: days));
      } else {
        // Manual end date override: keep it as-is, unless an upstream
        // change pushed this stage's start date past it (which would make
        // it invalid - end before start).
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
    final box = await ref.read(stageBoxProvider.future);
    for (final stage in stages) {
      final payload = _toApiPayload(stage);
      try {
        await apiService.updateJourneyStage(stage.id, payload);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
              id: PendingAction.newId(),
              entityType: 'journey_stage',
              operation: 'update',
              targetId: stage.id,
              payload: payload,
              knownUpdatedAt: stage.updatedAt.toIso8601String(),
              createdAt: DateTime.now(),
            ));
        await box.put(stage.id, stage);
      }
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
      String createdId;
      var wentOffline = false;
      try {
        final created = await apiService.createJourneyStage(createdData);
        createdId = created['id'].toString();
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        wentOffline = true;
        createdId = PendingAction.newId();
        await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
              id: PendingAction.newId(),
              entityType: 'journey_stage',
              operation: 'create',
              payload: createdData,
              createdAt: DateTime.now(),
            ));
        final box = await ref.read(stageBoxProvider.future);
        await box.put(createdId, recomputed.last.copyWith(id: createdId));
      }

      // Persist recomputed dates for the existing stages (order/end date may
      // have shifted now that a new stage follows them)
      final existingRecomputed =
          recomputed.sublist(0, recomputed.length - 1);
      await _persistAll(existingRecomputed);

      // Ensure the newly created stage also has the right order (already
      // correct from createdData, but re-send in case of race conditions) -
      // skipped when the create itself was just queued offline, since the
      // queued payload already has the right order and there's no real id
      // yet to target.
      if (!wentOffline) {
        await apiService.updateJourneyStage(
          createdId,
          _toApiPayload(recomputed.last),
        );
      }

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
      final existingMatches = current.where((s) => s.id == id).toList();
      final existing = existingMatches.isEmpty ? null : existingMatches.first;

      try {
        await apiService.deleteJourneyStage(id);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
              id: PendingAction.newId(),
              entityType: 'journey_stage',
              operation: 'delete',
              targetId: id,
              payload: const {},
              knownUpdatedAt: existing?.updatedAt.toIso8601String(),
              createdAt: DateTime.now(),
            ));
        final box = await ref.read(stageBoxProvider.future);
        await box.delete(id);
      }

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
      final box = await ref.read(stageBoxProvider.future);
      final current = await ref.read(stagesProvider.future);

      Future<void> updateWithFallback(
        JourneyStage stage,
        Map<String, dynamic> payload,
      ) async {
        try {
          await apiService.updateJourneyStage(stage.id, payload);
        } catch (e) {
          if (!isNetworkError(e)) rethrow;
          await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
                id: PendingAction.newId(),
                entityType: 'journey_stage',
                operation: 'update',
                targetId: stage.id,
                payload: payload,
                knownUpdatedAt: stage.updatedAt.toIso8601String(),
                createdAt: DateTime.now(),
              ));
          await box.put(stage.id, stage.copyWith(status: payload['status'] as String));
        }
      }

      final previouslyCurrent = current
          .where((s) => s.status == 'in_progress' && s.id != stageId);
      for (final stage in previouslyCurrent) {
        await updateWithFallback(stage, {'status': 'done'});
      }

      final target = current.firstWhere((s) => s.id == stageId);
      await updateWithFallback(target, {
        'status': 'in_progress',
        // Only stamp a start date if this stage never had one recorded
        // (a fresh "tag" pick) - don't overwrite genuine historical data.
        if (target.status == 'upcoming')
          'start_date': DateTime.now().toIso8601String().split('T')[0],
      });

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
