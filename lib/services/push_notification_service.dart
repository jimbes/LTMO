import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'local_notification_service.dart';
import '../utils/notification_id.dart';

/// Backend sends data-only messages (no top-level "notification" block) so
/// the OS never auto-displays them - display always goes through this
/// function instead, both from the foreground listener below and from
/// [firebaseMessagingBackgroundHandler]. That's what lets it compute the
/// same deterministic notification id the local-alarm scheduler used for
/// this reminder (see notification_id.dart), so a push arriving for a
/// reminder that already fired locally (or is about to) replaces it in the
/// tray instead of showing a duplicate.
Future<void> _showPushNotification(Map<String, dynamic> data) async {
  final title = data['title'] as String? ?? 'LTMO';
  final body = data['body'] as String? ?? '';
  await LocalNotificationService.instance.showNow(
    title: title,
    body: body,
    id: _matchingLocalNotificationId(data),
  );
}

/// Recomputes the id from the identity fields the backend includes for
/// medication/appointment reminders (see NotificationService in the
/// backend for the matching canonical string format). Returns null for
/// anything else - falls back to a fresh, always-shown notification.
int? _matchingLocalNotificationId(Map<String, dynamic> data) {
  final type = data['type'] as String?;
  final relatedEntityId = data['related_entity_id'] as String?;
  final offsetMinutes = int.tryParse(data['offset_minutes']?.toString() ?? '');
  if (relatedEntityId == null || offsetMinutes == null) return null;

  if (type == 'medication_reminder') {
    final doseTime = data['dose_time'] as String?;
    if (doseTime == null) return null;
    return medicationReminderNotificationId(
      scheduleId: relatedEntityId,
      doseTime: doseTime,
      offsetMinutes: offsetMinutes,
      weekday: int.tryParse(data['weekday']?.toString() ?? ''),
    );
  }
  if (type == 'appointment') {
    return appointmentReminderNotificationId(
      appointmentId: relatedEntityId,
      offsetMinutes: offsetMinutes,
    );
  }
  return null;
}

/// Called when a push arrives while the app is fully terminated/backgrounded
/// (not just foregrounded). Must be a top-level function, not a class
/// method - FCM invokes it in its own isolate, which hasn't run main() and
/// needs its own plugin setup before any platform channel (including
/// flutter_local_notifications, used here to actually display the push)
/// can be used.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.instance.init();
  await _showPushNotification(message.data);
}

/// Registers this device for server-driven push notifications (FCM) and
/// wires up how incoming pushes are displayed depending on whether the app
/// is in the foreground or background/terminated.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Called once at startup after login - registers the device token with
  /// the backend and wires up message listeners. Safe to call multiple
  /// times (e.g. after switching accounts).
  Future<void> init({
    required Future<void> Function(String token) onTokenReady,
  }) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await onTokenReady(token);
    }

    // The OS can rotate the FCM token (app reinstall, data clear, etc.) -
    // without re-registering, the server would keep sending to a dead token.
    _messaging.onTokenRefresh.listen(onTokenReady);

    // App open and in the foreground - same display path as the
    // background/terminated handler above.
    FirebaseMessaging.onMessage.listen((message) {
      _showPushNotification(message.data);
    });
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to delete FCM token: $e');
    }
  }
}
