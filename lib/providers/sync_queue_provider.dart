import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pending_action.dart';
import 'appointment_provider.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';
import 'journey_provider.dart';
import 'medication_logs_provider.dart';
import 'medication_provider.dart';
import 'notification_preference_provider.dart';
import 'practitioner_provider.dart';
import 'treatment_cycle_provider.dart';

final pendingActionBoxProvider = FutureProvider<Box<PendingAction>>((ref) async {
  return Hive.openBox<PendingAction>('pending_actions_box');
});

final pendingActionsProvider = FutureProvider<List<PendingAction>>((ref) async {
  final box = await ref.watch(pendingActionBoxProvider.future);
  final list = box.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return list;
});

/// Messages pushed by processQueue() when a queued action is rejected for a
/// conflict - consumed once by a global snackbar listener in MainScaffold.
final conflictMessagesProvider = StateProvider<List<String>>((ref) => []);

final syncQueueProvider =
    StateNotifierProvider<SyncQueueNotifier, AsyncValue<void>>((ref) {
  return SyncQueueNotifier(ref);
});

const Map<String, String> _entityLabels = {
  'appointment': 'un rendez-vous',
  'medication': 'un médicament',
  'schedule': 'un planning de traitement',
  'journey_stage': 'une étape du parcours',
  'practitioner': 'un praticien',
  'notification_preference': 'une préférence de notification',
  'medication_taken_log': 'une prise de médicament',
  'treatment_cycle': 'un cycle de traitement',
};

class SyncQueueNotifier extends StateNotifier<AsyncValue<void>> {
  SyncQueueNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;
  bool _processing = false;

  Future<void> enqueue(PendingAction action) async {
    final box = await ref.read(pendingActionBoxProvider.future);
    await box.put(action.id, action);
    ref.invalidate(pendingActionsProvider);
  }

  /// Replays every queued action against the server in order. Re-entrant
  /// calls are dropped rather than queued - the periodic refresh timer and
  /// the connectivity-regained listener can both fire around the same time.
  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      final box = await ref.read(pendingActionBoxProvider.future);
      final actions = box.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (actions.isEmpty) return;

      // Lets the UI show a "synchronisation en cours" indicator distinct
      // from the offline banner - this used to just sit in `data(null)`
      // the whole time, so nothing could ever observe an active sync.
      state = const AsyncValue.loading();

      final touchedEntityTypes = <String>{};

      for (final action in actions) {
        try {
          await _replay(action);
          await box.delete(action.id);
          touchedEntityTypes.add(action.entityType);
        } on DioException catch (e) {
          if (e.response?.statusCode == 409) {
            await box.delete(action.id);
            touchedEntityTypes.add(action.entityType);
            final label = _entityLabels[action.entityType] ?? 'une donnée';
            ref.read(conflictMessagesProvider.notifier).update(
                  (msgs) => [
                    ...msgs,
                    'Une modification de $label n\'a pas pu être appliquée '
                        'car elle a été modifiée entre-temps. Les données '
                        'ont été mises à jour.',
                  ],
                );
          } else if (!isNetworkError(e)) {
            // A real, non-network, non-conflict error (e.g. invalid
            // payload) will never succeed by retrying - drop it instead of
            // blocking every action queued after it.
            await box.delete(action.id);
          }
          // Otherwise still offline - leave it queued for the next pass.
        }
      }

      ref.invalidate(pendingActionsProvider);
      for (final type in touchedEntityTypes) {
        _invalidateListProvider(type);
      }
    } finally {
      _processing = false;
      // Unconditional, even on an unexpected error escaping the loop above -
      // otherwise the UI could get stuck showing "synchronisation en cours"
      // forever.
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _replay(PendingAction action) async {
    final apiService = ref.read(apiServiceProvider);

    if (action.entityType == 'medication_taken_log') {
      final scheduleId = action.payload['schedule_id'] as String;
      final date = action.payload['date'] as String;
      final time = action.payload['time'] as String?;
      final taken = action.payload['taken'] as bool;
      if (taken) {
        await apiService.markMedicationTaken(scheduleId, date,
            time: time, clientKnownUpdatedAt: action.knownUpdatedAt);
      } else {
        await apiService.markMedicationNotTaken(scheduleId, date,
            time: time, clientKnownUpdatedAt: action.knownUpdatedAt);
      }
      return;
    }

    final payload = {
      ...action.payload,
      'client_known_updated_at': action.knownUpdatedAt,
    };

    switch (action.entityType) {
      case 'appointment':
        switch (action.operation) {
          case 'create':
            await apiService.createAppointment(payload);
          case 'update':
            await apiService.updateAppointment(action.targetId!, payload);
          case 'delete':
            await apiService.deleteAppointment(action.targetId!, data: payload);
        }
      case 'medication':
        switch (action.operation) {
          case 'create':
            await apiService.createMedication(payload);
          case 'update':
            await apiService.updateMedication(action.targetId!, payload);
          case 'delete':
            await apiService.deleteMedication(action.targetId!, data: payload);
        }
      case 'schedule':
        switch (action.operation) {
          case 'create':
            await apiService.createSchedule(payload);
          case 'update':
            await apiService.updateSchedule(action.targetId!, payload);
          case 'delete':
            await apiService.deleteSchedule(action.targetId!, data: payload);
        }
      case 'journey_stage':
        switch (action.operation) {
          case 'create':
            await apiService.createJourneyStage(payload);
          case 'update':
            await apiService.updateJourneyStage(action.targetId!, payload);
          case 'delete':
            await apiService.deleteJourneyStage(action.targetId!, data: payload);
        }
      case 'practitioner':
        switch (action.operation) {
          case 'create':
            await apiService.createPractitioner(payload);
          case 'update':
            await apiService.updatePractitioner(action.targetId!, payload);
          case 'delete':
            await apiService.deletePractitioner(action.targetId!, data: payload);
        }
      case 'notification_preference':
        switch (action.operation) {
          case 'create':
            await apiService.createNotificationPreference(payload);
          case 'update':
            await apiService.updateNotificationPreference(action.targetId!, payload);
          case 'delete':
            await apiService.deleteNotificationPreference(action.targetId!, data: payload);
        }
      case 'treatment_cycle':
        await apiService.startNewTreatmentCycle();
    }
  }

  void _invalidateListProvider(String entityType) {
    switch (entityType) {
      case 'appointment':
        ref.invalidate(appointmentsProvider);
      case 'medication':
        ref.invalidate(medicationsProvider);
      case 'schedule':
        ref.invalidate(schedulesProvider);
      case 'journey_stage':
        ref.invalidate(stagesProvider);
      case 'practitioner':
        ref.invalidate(practitionersProvider);
      case 'notification_preference':
        ref.invalidate(notificationPreferencesProvider);
      case 'medication_taken_log':
        ref.invalidate(medicationLogsProvider);
      case 'treatment_cycle':
        ref.invalidate(currentCycleProvider);
        ref.invalidate(cycleHistoryProvider);
        ref.invalidate(stagesProvider);
    }
  }
}
