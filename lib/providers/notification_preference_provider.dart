import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_preference.dart';

final notifPrefBoxProvider = FutureProvider<Box<NotificationPreference>>((ref) async {
  return Hive.openBox<NotificationPreference>('notif_prefs_box');
});

final notificationPreferencesProvider =
    StreamProvider<List<NotificationPreference>>((ref) async* {
  final box = await ref.watch(notifPrefBoxProvider.future);
  yield box.values.toList();
  yield* box.watch().map((_) => box.values.toList());
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
      final box = await ref.read(notifPrefBoxProvider.future);
      await box.put(pref.id, pref);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePreference(NotificationPreference pref) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(notifPrefBoxProvider.future);
      await box.put(pref.id, pref);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePreference(String id) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(notifPrefBoxProvider.future);
      await box.delete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
