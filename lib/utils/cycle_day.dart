/// "J1" is the first day of the current treatment cycle - standard IVF
/// clinical shorthand (used by doctors and patients alike, e.g. "contrôle à
/// J12") for how far into the cycle a given day falls, independent of which
/// journey stage is active at that point.
String? cycleDayLabel(DateTime date, DateTime? cycleStartDate) {
  if (cycleStartDate == null) return null;
  final day = DateTime(date.year, date.month, date.day);
  final start = DateTime(
    cycleStartDate.year,
    cycleStartDate.month,
    cycleStartDate.day,
  );
  final dayNumber = day.difference(start).inDays + 1;
  if (dayNumber < 1) return null;
  return 'J$dayNumber';
}
