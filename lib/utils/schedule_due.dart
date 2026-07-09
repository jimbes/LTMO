import '../models/medication_schedule.dart';
import '../models/journey_stage.dart';

/// Whether a medication schedule is due on [date]. A schedule's own
/// start/end date always governs visibility - a linked journey stage (if
/// any) is purely an informational tag and has no effect on scheduling.
/// This matches how treatment actually works: the doctor sets a dose and a
/// duration at a visit, before it's necessarily clear which phase that
/// falls under, so phase assignment can't be a prerequisite for a
/// medication to show up in the agenda.
// isBefore/isAfter compare absolute instants, not calendar days. Schedule
// dates come from the backend as UTC timestamps (DateTime.parse of a
// "...Z" string yields isUtc=true), while the `date` being checked here is
// built as local midnight - comparing those directly silently shifts the
// valid window by the device's UTC offset (e.g. a whole day off in
// France's UTC+2/+1). Stripping to y/m/d before comparing makes the check
// purely calendar-based, independent of timezone.
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isScheduleDueOn(
  MedicationSchedule schedule,
  List<JourneyStage> stages,
  DateTime date,
) {
  final day = _dateOnly(date);

  final isDateValid = !day.isBefore(_dateOnly(schedule.startDate)) &&
      (schedule.endDate == null || !day.isAfter(_dateOnly(schedule.endDate!)));

  if (!isDateValid) return false;

  if (schedule.frequency == 'daily') return true;
  if (schedule.frequency == 'specific_days' && schedule.daysOfWeek != null) {
    final dayOfWeek = day.weekday - 1;
    return schedule.daysOfWeek!.contains(dayOfWeek);
  }
  return false;
}
