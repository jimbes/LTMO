import 'dart:convert';

/// Standard CRC-32 (IEEE 802.3) - the same algorithm as PHP's crc32() and
/// zlib. Used (instead of Dart's own String.hashCode, which is an
/// unspecified, implementation-detail hash with no cross-language or
/// cross-version stability guarantee) so the backend can compute an
/// identical Android notification id for a push message without the two
/// codebases ever drifting out of sync.
final List<int> _crc32Table = _buildCrc32Table();

List<int> _buildCrc32Table() {
  final table = List<int>.filled(256, 0);
  for (var i = 0; i < 256; i++) {
    var c = i;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
    }
    table[i] = c;
  }
  return table;
}

int _crc32(String input) {
  var crc = 0xFFFFFFFF;
  for (final byte in utf8.encode(input)) {
    crc = _crc32Table[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

/// Deterministic Android notification id for one instance of a medication
/// reminder: one schedule, one dose time, one reminder offset - plus the
/// weekday for a specific_days schedule, where each selected weekday needs
/// its own independently-recurring local alarm. Used both to schedule the
/// local alarm and to display the matching FCM push, so that whichever
/// fires second replaces the first in the notification tray instead of
/// stacking a duplicate.
///
/// Must match NotificationService::medicationReminderNotificationId in the
/// backend (pma-backend/app/Services/NotificationService.php) exactly.
int medicationReminderNotificationId({
  required String scheduleId,
  required String doseTime, // "HH:mm"
  required int offsetMinutes,
  int? weekday, // 0=Monday..6=Sunday, only for specific_days schedules
}) {
  final key = weekday == null
      ? 'med:$scheduleId:$doseTime:$offsetMinutes'
      : 'med:$scheduleId:$doseTime:$offsetMinutes:$weekday';
  return _crc32(key) & 0x7FFFFFFF;
}

/// Deterministic Android notification id for one appointment reminder.
/// Must match NotificationService::appointmentReminderNotificationId in
/// the backend exactly.
int appointmentReminderNotificationId({
  required String appointmentId,
  required int offsetMinutes,
}) {
  final key = 'apt:$appointmentId:$offsetMinutes';
  return _crc32(key) & 0x7FFFFFFF;
}
