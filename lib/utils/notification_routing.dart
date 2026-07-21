import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// Whether a medication/appointment reminder flagged with [notifyUser1] /
/// [notifyUser2] should be scheduled as a *local* notification on this
/// device - i.e. whether the signed-in user is the one those flags say to
/// notify. Local notifications don't sync across the couple's two devices,
/// so each device must only schedule reminders meant for whoever is signed
/// in on it (the server-side push already does this correctly; this mirrors
/// it for local scheduling).
bool shouldNotifyCurrentUser(
  Ref ref, {
  required bool notifyUser1,
  required bool notifyUser2,
}) {
  final user = ref.read(userProvider).value;
  // No user loaded yet (shouldn't happen once logged in) - default to
  // scheduling rather than silently dropping a reminder.
  if (user == null) return true;
  return user.isPrimaryUser ? notifyUser1 : notifyUser2;
}
