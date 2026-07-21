import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'medication_provider.dart';
import 'appointment_provider.dart';
import 'medication_logs_provider.dart';
import 'journey_provider.dart';
import 'partner_provider.dart';
import 'practitioner_provider.dart';
import '../services/local_notification_service.dart';
import '../utils/notification_routing.dart';

/// Invalidates every provider that fetches shared couple data from the API,
/// so the next read/watch triggers a fresh network fetch. Cheap to call
/// repeatedly: invalidating just discards the cached Future, it doesn't
/// accumulate memory.
Future<void> refreshAllData(WidgetRef ref) async {
  ref.invalidate(medicationsProvider);
  ref.invalidate(schedulesProvider);
  ref.invalidate(medicationLogsProvider);
  ref.invalidate(appointmentsProvider);
  ref.invalidate(stagesProvider);
  ref.invalidate(partnerProvider);
  ref.invalidate(pendingInvitationProvider);
  ref.invalidate(receivedInvitationsProvider);
  ref.invalidate(practitionersProvider);

  // Wait for the core ones so pull-to-refresh indicators know when to stop.
  await Future.wait([
    ref.read(medicationsProvider.future),
    ref.read(schedulesProvider.future),
    ref.read(appointmentsProvider.future),
    ref.read(stagesProvider.future),
  ]);
}

/// (Re)schedules every local reminder from the couple's current medication
/// schedules and upcoming appointments. Needed after login/register/accept
/// invite - local notifications don't sync with the server, so a fresh
/// install or a different device has none scheduled until this runs once.
Future<void> resyncAllNotifications(Ref ref) async {
  try {
    final schedules = await ref.read(schedulesProvider.future);
    final medications = await ref.read(medicationsProvider.future);
    final appointments = await ref.read(appointmentsProvider.future);

    // Clear everything first rather than relying solely on the per-item
    // cancel-then-reschedule below: a schedule/appointment deleted from
    // another device wouldn't be in the fresh lists at all, so nothing
    // would otherwise cancel its old alarm; this also sweeps up any alarm
    // still scheduled under a previous app version's notification id
    // scheme.
    await LocalNotificationService.instance.cancelAll();

    final medMap = {for (final m in medications) m.id: m};

    for (final schedule in schedules) {
      if (!shouldNotifyCurrentUser(
        ref,
        notifyUser1: schedule.notifyUser1,
        notifyUser2: schedule.notifyUser2,
      )) {
        continue;
      }
      await LocalNotificationService.instance.scheduleMedicationReminders(
        schedule,
        medMap[schedule.medicationId],
      );
    }

    for (final appointment in appointments) {
      if (!shouldNotifyCurrentUser(
        ref,
        notifyUser1: appointment.notifyUser1,
        notifyUser2: appointment.notifyUser2,
      )) {
        continue;
      }
      await LocalNotificationService.instance
          .scheduleAppointmentReminder(appointment);
    }
  } catch (_) {
    // Best-effort: a failure here shouldn't block login. Notifications will
    // simply resync on the next successful data refresh.
  }
}
