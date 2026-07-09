import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/medication_schedule.dart';
import '../models/medication.dart';
import '../models/appointment.dart';
import '../widgets/reminder_offsets_picker.dart';

/// Schedules on-device reminders for medications and appointments. No
/// server/network involved - purely local alarms via the OS notification
/// scheduler, so reminders keep firing even when the app has no connectivity.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      // No native plugin dependency for this: derive a fixed-offset zone
      // from the device's current UTC offset (e.g. "Etc/GMT-2" for UTC+2).
      // Note the inverted sign in Etc/GMT naming. This won't auto-adjust
      // across a DST transition until the app restarts, but avoids pulling
      // in a native timezone-name plugin just for this lookup.
      final offsetHours = DateTime.now().timeZoneOffset.inHours;
      final etcSign = offsetHours <= 0 ? '+' : '-';
      final etcName = 'Etc/GMT$etcSign${offsetHours.abs()}';
      tz.setLocalLocation(tz.getLocation(etcName));
    } catch (_) {
      // Fall back to whatever the timezone package defaults to (UTC) rather
      // than crashing app startup over a timezone lookup failure.
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    // Explicitly (re)create the channel up front, rather than relying on it
    // being created implicitly the first time a notification fires - this
    // makes the channel show up in system settings immediately and removes
    // one possible point of failure from the actual fire path.
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel());

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
    if (iosImpl != null) {
      await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Cancels every scheduled reminder - used on logout so the next user's
  /// session doesn't inherit the previous user's reminders.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Displays a notification immediately - used to surface a push message
  /// (FCM) received while the app is in the foreground, since Android
  /// doesn't auto-show a system notification for foreground pushes the way
  /// it does for background ones.
  Future<void> showNow({
    required String title,
    required String body,
    int? id,
  }) async {
    await _plugin.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      title: title,
      body: body,
      notificationDetails: _details(),
    );
  }

  AndroidNotificationChannel _channel() {
    return const AndroidNotificationChannel(
      'ltmo_reminders',
      'Rappels LTMO',
      description: 'Rappels de médicaments et rendez-vous',
      importance: Importance.high,
    );
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'ltmo_reminders',
        'Rappels LTMO',
        channelDescription: 'Rappels de médicaments et rendez-vous',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  int _medicationBaseId(String scheduleId, String reminderTime, int offsetMinutes) {
    return ('med_${scheduleId}_${reminderTime}_$offsetMinutes').hashCode &
        0x7FFFFFFF;
  }

  int _appointmentId(String appointmentId, int offsetMinutes) {
    return ('apt_${appointmentId}_$offsetMinutes').hashCode & 0x7FFFFFFF;
  }

  /// Cancels every notification that could have been scheduled for this
  /// schedule (the single "daily" id and the 7 "specific_days" id variants,
  /// for every possible offset preset - not just the currently-selected
  /// ones, since a previously-selected offset that's since been removed
  /// still needs its old alarm cleared). Safe to call even if nothing was
  /// ever scheduled - cancelling a non-existent id is a no-op.
  Future<void> cancelMedicationReminders(MedicationSchedule schedule) async {
    for (final time in schedule.reminderTimes) {
      for (final offsetMinutes in reminderOffsetPresets) {
        final baseId = _medicationBaseId(schedule.id, time, offsetMinutes);
        await _plugin.cancel(id: baseId);
        for (var day = 0; day < 7; day++) {
          await _plugin.cancel(id: baseId + 1 + day);
        }
      }
    }
  }

  Future<void> scheduleMedicationReminders(
    MedicationSchedule schedule,
    Medication? medication,
  ) async {
    await cancelMedicationReminders(schedule);

    final title = medication != null
        ? '${medication.name} · ${medication.dosage}${medication.unit}'
        : 'Rappel médicament';

    for (final time in schedule.reminderTimes) {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      var doseTime = tz.TZDateTime.now(tz.local);
      doseTime = tz.TZDateTime(
        tz.local,
        doseTime.year,
        doseTime.month,
        doseTime.day,
        hour,
        minute,
      );

      for (final offsetMinutes in schedule.reminderOffsets) {
        final baseId = _medicationBaseId(schedule.id, time, offsetMinutes);
        final body =
            'C\'est bientôt l\'heure de votre prise (dans ${formatReminderOffset(offsetMinutes)})';

        var fireTime = doseTime.subtract(Duration(minutes: offsetMinutes));
        if (fireTime.isBefore(tz.TZDateTime.now(tz.local))) {
          fireTime = fireTime.add(const Duration(days: 1));
        }

        if (schedule.frequency == 'daily') {
          await _plugin.zonedSchedule(
            id: baseId,
            title: title,
            body: body,
            scheduledDate: fireTime,
            notificationDetails: _details(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } else if (schedule.frequency == 'specific_days' &&
            schedule.daysOfWeek != null) {
          for (final day in schedule.daysOfWeek!) {
            // day: 0=Monday..6=Sunday -> DateTime.weekday: 1=Monday..7=Sunday
            final weekday = day + 1;
            var dayFireTime = fireTime;
            while (dayFireTime.weekday != weekday) {
              dayFireTime = dayFireTime.add(const Duration(days: 1));
            }
            await _plugin.zonedSchedule(
              id: baseId + 1 + day,
              title: title,
              body: body,
              scheduledDate: dayFireTime,
              notificationDetails: _details(),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            );
          }
        }
      }
    }
  }

  /// Cancels every reminder that could have been scheduled for this
  /// appointment, across every possible offset preset (see
  /// cancelMedicationReminders for why not just the current ones).
  Future<void> cancelAppointmentReminder(String appointmentId) async {
    for (final offsetMinutes in reminderOffsetPresets) {
      await _plugin.cancel(id: _appointmentId(appointmentId, offsetMinutes));
    }
  }

  Future<void> scheduleAppointmentReminder(Appointment appointment) async {
    await cancelAppointmentReminder(appointment.id);

    if (appointment.appointmentTime == null || appointment.completed) return;

    for (final offsetMinutes in appointment.reminderOffsets) {
      final fireTime = appointment.appointmentTime!
          .subtract(Duration(minutes: offsetMinutes));
      if (fireTime.isBefore(DateTime.now())) continue;

      final body = appointment.location != null
          ? 'Rendez-vous · ${appointment.location} (dans ${formatReminderOffset(offsetMinutes)})'
          : 'Vous avez un rendez-vous bientôt (dans ${formatReminderOffset(offsetMinutes)})';

      await _plugin.zonedSchedule(
        id: _appointmentId(appointment.id, offsetMinutes),
        title: appointment.title,
        body: body,
        scheduledDate: tz.TZDateTime.from(fireTime, tz.local),
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }
}
