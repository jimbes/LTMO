import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_preference.dart';
import '../models/pending_action.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';
import 'sync_queue_provider.dart';

final notifPrefBoxProvider = FutureProvider<Box<NotificationPreference>>((ref) async {
  return Hive.openBox<NotificationPreference>('notif_prefs_box');
});

final notificationPreferencesProvider =
    FutureProvider<List<NotificationPreference>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);

  if (token == null) {
    return [];
  }

  try {
    final preferences = await apiService.getNotificationPreferences();
    final list = (preferences as List)
        .map((p) => NotificationPreference.fromJson(p as Map<String, dynamic>))
        .toList();

    // Cache in Hive
    final box = await ref.read(notifPrefBoxProvider.future);
    for (var pref in list) {
      await box.put(pref.id, pref);
    }

    return list;
  } catch (e) {
    // Fall back to local cache
    final box = await ref.read(notifPrefBoxProvider.future);
    return box.values.toList();
  }
});

final notifPrefProvider = StateNotifierProvider<
    NotificationPreferenceNotifier,
    AsyncValue<void>>((ref) {
  return NotificationPreferenceNotifier(ref);
});

class NotificationPreferenceNotifier extends StateNotifier<AsyncValue<void>> {
  NotificationPreferenceNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> addPreference(NotificationPreference pref) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);

      final data = {
        'type': pref.type,
        'channel': pref.channel,
        'enabled': pref.enabled,
        'reminder_minutes_before': pref.reminderMinutesBefore,
      };

      try {
        await apiService.createNotificationPreference(data);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
              id: PendingAction.newId(),
              entityType: 'notification_preference',
              operation: 'create',
              payload: data,
              createdAt: DateTime.now(),
            ));
        final box = await ref.read(notifPrefBoxProvider.future);
        final local = pref.copyWith(id: PendingAction.newId());
        await box.put(local.id, local);
      }

      // Refresh the list
      ref.invalidate(notificationPreferencesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePreference(NotificationPreference pref) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);

      final data = {
        'type': pref.type,
        'channel': pref.channel,
        'enabled': pref.enabled,
        'reminder_minutes_before': pref.reminderMinutesBefore,
      };

      try {
        await apiService.updateNotificationPreference(pref.id, data);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
              id: PendingAction.newId(),
              entityType: 'notification_preference',
              operation: 'update',
              targetId: pref.id,
              payload: data,
              knownUpdatedAt: pref.updatedAt.toIso8601String(),
              createdAt: DateTime.now(),
            ));
        final box = await ref.read(notifPrefBoxProvider.future);
        await box.put(pref.id, pref);
      }

      // Refresh the list
      ref.invalidate(notificationPreferencesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePreference(String id) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final box = await ref.read(notifPrefBoxProvider.future);
      final existing = box.get(id);

      try {
        await apiService.deleteNotificationPreference(id);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        await ref.read(syncQueueProvider.notifier).enqueue(PendingAction(
              id: PendingAction.newId(),
              entityType: 'notification_preference',
              operation: 'delete',
              targetId: id,
              payload: const {},
              knownUpdatedAt: existing?.updatedAt.toIso8601String(),
              createdAt: DateTime.now(),
            ));
        await box.delete(id);
      }

      // Refresh the list
      ref.invalidate(notificationPreferencesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
