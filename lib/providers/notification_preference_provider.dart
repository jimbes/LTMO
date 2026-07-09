import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_preference.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

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

      await apiService.createNotificationPreference(data);

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

      await apiService.updateNotificationPreference(pref.id, data);

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
      await apiService.deleteNotificationPreference(id);

      // Refresh the list
      ref.invalidate(notificationPreferencesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
