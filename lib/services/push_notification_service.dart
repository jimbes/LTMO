import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'local_notification_service.dart';

/// Called when a push arrives while the app is fully terminated/backgrounded
/// (not just foregrounded). Must be a top-level function, not a class
/// method - FCM invokes it in its own isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nothing to do here for now: Android shows the system notification for
  // background/terminated pushes automatically from the message's
  // `notification` payload, no extra work needed. This handler exists so
  // FCM has somewhere to deliver data-only messages if we add those later.
}

/// Registers this device for server-driven push notifications (FCM) and
/// wires up how incoming pushes are displayed/handled depending on whether
/// the app is in the foreground, background, or was launched by tapping one.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Called once at startup after login - registers the device token with
  /// the backend and wires up message listeners. Safe to call multiple
  /// times (e.g. after switching accounts).
  Future<void> init({
    required Future<void> Function(String token) onTokenReady,
    void Function(RemoteMessage message)? onNotificationTap,
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

    // App open and in the foreground: Android/iOS don't auto-display a
    // system notification for this case, so show it via the same local
    // notification channel used for on-device reminders.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      LocalNotificationService.instance.showNow(
        title: notification.title ?? 'LTMO',
        body: notification.body ?? '',
      );
    });

    // User tapped a notification while the app was backgrounded (not
    // terminated).
    if (onNotificationTap != null) {
      FirebaseMessaging.onMessageOpenedApp.listen(onNotificationTap);

      // App was fully terminated and got launched by tapping a notification.
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        onNotificationTap(initialMessage);
      }
    }
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to delete FCM token: $e');
    }
  }
}
