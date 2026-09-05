import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/medication_logs_provider.dart';
import '../../providers/journey_provider.dart';
import '../../providers/data_refresh.dart';
import '../../models/medication_taken_log.dart';
import '../../utils/schedule_due.dart';
import '../../widgets/cycle_day_badge.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  /// Day to open on, e.g. when navigated to from the home screen's "see
  /// more" button on the next appointment. Defaults to today.
  final DateTime? initialDate;

  const AgendaScreen({super.key, this.initialDate});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedWeekStart;
  late PageController _pageController;

  // Fixed anchor page representing "this week" - never reassigned. All page
  // indices are interpreted relative to this to compute the actual date.
  static const int _anchorPage = 1000;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDate ?? DateTime.now();
    _focusedWeekStart = _getWeekMonday(_selectedDay);

    final weeksOffset =
        _focusedWeekStart.difference(_getWeekMonday(DateTime.now())).inDays ~/
            7;
    _pageController =
        PageController(initialPage: _anchorPage + weeksOffset);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getWeekMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime _getWeekMondayFromPage(int page) {
    final offset = page - _anchorPage;
    return _getWeekMonday(DateTime.now()).add(Duration(days: offset * 7));
  }

  String _getMonthName(int month) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    return months[month - 1];
  }

  String _getDayName(DateTime date) {
    const days = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche'
    ];
    return days[date.weekday - 1].toUpperCase();
  }

  Widget _buildWeekView(DateTime weekStart) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Day headers (L M M J V S D)
          Row(
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.inkTertiary,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // 7 day cells with event indicators
          Row(
            children: List.generate(7, (index) {
              final day = weekStart.add(Duration(days: index));
              final isSelected = day.year == _selectedDay.year &&
                  day.month == _selectedDay.month &&
                  day.day == _selectedDay.day;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedDay = day);
                  },
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.sage : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${day.day}',
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Dot indicators: green for medication, orange for appointment
                      Consumer(
                        builder: (context, ref, child) {
                          final schedulesAsync = ref.watch(schedulesProvider);
                          final stagesAsync = ref.watch(stagesProvider);
                          final appointmentsAsync =
                              ref.watch(appointmentsProvider);

                          final hasMedication = schedulesAsync.maybeWhen(
                            data: (schedules) => stagesAsync.maybeWhen(
                              data: (stages) => schedules.any(
                                (s) => isScheduleDueOn(s, stages, day),
                              ),
                              orElse: () => false,
                            ),
                            orElse: () => false,
                          );

                          final hasAppointment = appointmentsAsync.maybeWhen(
                            data: (apts) => apts.any((apt) =>
                                apt.appointmentDate.year == day.year &&
                                apt.appointmentDate.month == day.month &&
                                apt.appointmentDate.day == day.day),
                            orElse: () => false,
                          );

                          if (!hasMedication && !hasAppointment) {
                            return const SizedBox(width: 4, height: 4);
                          }

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasMedication)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: EdgeInsets.only(
                                    right: hasAppointment ? 3 : 0,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppColors.sage,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasAppointment)
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.clay,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentsProvider);
    final medications = ref.watch(medicationsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => refreshAllData(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                color: AppColors.cream,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_getMonthName(_focusedWeekStart.month)} ${_focusedWeekStart.year}',
                      style: AppTypography.headline1,
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border1),
                            ),
                            child: const Icon(Icons.chevron_left, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border1),
                            ),
                            child: const Icon(Icons.chevron_right, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 7-day week view (PageView with smooth animation)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 90,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _focusedWeekStart = _getWeekMondayFromPage(page);
                      });
                    },
                    itemBuilder: (context, pageIndex) {
                      final weekStart = _getWeekMondayFromPage(pageIndex);
                      return _buildWeekView(weekStart);
                    },
                  ),
                ),
              ),

              // Events section - medications and appointments
              Consumer(
                builder: (context, ref, child) {
                  final schedulesAsync = ref.watch(schedulesProvider);
                  final logsAsync = ref.watch(medicationLogsProvider);
                  final appointmentsAsync = ref.watch(appointmentsProvider);
                  final medicationsAsync = ref.watch(medicationsProvider);
                  final journeyStagesAsync = ref.watch(stagesProvider);

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 + MediaQuery.of(context).viewPadding.bottom,
                    ),
                    child: schedulesAsync.when(
                      data: (schedules) {
                        return logsAsync.when(
                          data: (logs) {
                            return appointmentsAsync.when(
                              data: (appointments) {
                                return medicationsAsync.when(
                                  data: (medications) {
                                    return journeyStagesAsync.when(
                                      data: (stages) {
                                        final medMap = {
                                          for (var med in medications)
                                            med.id: med
                                        };
                                        final dayEvents =
                                            <DateTime, List<_ScheduledEvent>>{};

                                        // Seed all 3 days up front (even with
                                        // no events) so a day with nothing
                                        // scheduled still shows up with an
                                        // explicit "rien de prévu" message
                                        // instead of silently disappearing.
                                        for (var i = 0; i <= 2; i++) {
                                          dayEvents[DateTime(
                                            _selectedDay.year,
                                            _selectedDay.month,
                                            _selectedDay.day + i,
                                          )] = [];
                                        }

                                        // Add scheduled medications for next 3 days
                                        for (var i = 0; i <= 2; i++) {
                                          final dateToAdd = DateTime(
                                            _selectedDay.year,
                                            _selectedDay.month,
                                            _selectedDay.day + i,
                                          );

                                          for (var schedule in schedules) {
                                            if (!isScheduleDueOn(
                                                schedule, stages, dateToAdd)) {
                                              continue;
                                            }

                                            // Add each reminder time for this schedule
                                            final medication =
                                                medMap[schedule.medicationId];
                                            // Orphaned schedule (its medication
                                            // was deleted) - skip rather than
                                            // showing the raw medication id.
                                            if (medication == null) continue;
                                            for (var reminderTime
                                                in schedule.reminderTimes) {
                                              final timeParts =
                                                  reminderTime.split(':');
                                              final time = DateTime(
                                                dateToAdd.year,
                                                dateToAdd.month,
                                                dateToAdd.day,
                                                int.parse(timeParts[0]),
                                                int.parse(timeParts[1]),
                                              );

                                              final logId =
                                                  '${schedule.id}_${dateToAdd.year}${dateToAdd.month.toString().padLeft(2, '0')}${dateToAdd.day.toString().padLeft(2, '0')}_$reminderTime';
                                              final logEntry = logs.firstWhere(
                                                (log) =>
                                                    log.medicationScheduleId ==
                                                        schedule.id &&
                                                    log.date.year ==
                                                        dateToAdd.year &&
                                                    log.date.month ==
                                                        dateToAdd.month &&
                                                    log.date.day ==
                                                        dateToAdd.day &&
                                                    log.time == reminderTime,
                                                orElse: () =>
                                                    _createDefaultLog(logId),
                                              );

                                              dayEvents.putIfAbsent(
                                                  dateToAdd, () => []);

                                              dayEvents[dateToAdd]!.add(
                                                _ScheduledEvent(
                                                  id: logId,
                                                  scheduleId: schedule.id,
                                                  time: time,
                                                  title: medication.name,
                                                  subtitle:
                                                      '${medication.dosage} ${medication.unit}${medication.form != null ? ' · ${medication.form}' : ''}',
                                                  type: 'medication',
                                                  completed: logEntry.taken,
                                                  date: dateToAdd,
                                                  reminderTime: reminderTime,
                                                ),
                                              );
                                            }
                                          }
                                        }

                                        // Add appointments for next 3 days
                                        for (var apt in appointments
                                            .where((a) => !a.completed)) {
                                          if (apt.appointmentTime == null)
                                            continue;
                                          final aptDate = apt.appointmentDate;
                                          final daysDiff = aptDate
                                              .difference(_selectedDay)
                                              .inDays;

                                          if (daysDiff < 0 || daysDiff > 2)
                                            continue;

                                          dayEvents.putIfAbsent(
                                              aptDate, () => []);

                                          dayEvents[aptDate]!.add(
                                            _ScheduledEvent(
                                              id: apt.id,
                                              scheduleId: '',
                                              time: apt.appointmentTime!,
                                              title: apt.title,
                                              subtitle:
                                                  apt.location ?? 'Rendez-vous',
                                              type: 'appointment',
                                              completed: false,
                                              date: aptDate,
                                            ),
                                          );
                                        }

                                        final sortedDates =
                                            dayEvents.keys.toList()..sort();

                                        if (sortedDates.isEmpty) {
                                          return Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(32),
                                              child: Text(
                                                'Aucun événement',
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                  color: AppColors.inkTertiary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        return Column(
                                          spacing: 16,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: sortedDates.map((date) {
                                            final events = dayEvents[date]!;
                                            final now = DateTime.now();
                                            final isToday =
                                                date.year == now.year &&
                                                    date.month == now.month &&
                                                    date.day == now.day;
                                            final dayLabel = isToday
                                                ? 'AUJOURD\'HUI - ${date.day} ${_getMonthName(date.month).toUpperCase()}'
                                                : '${_getDayName(date)} ${date.day} ${_getMonthName(date.month).toUpperCase()}';

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              spacing: 8,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      dayLabel,
                                                      style: AppTypography
                                                          .labelSmall
                                                          .copyWith(
                                                        color: AppColors
                                                            .inkTertiary,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    CycleDayBadge(
                                                      date: date,
                                                      compact: true,
                                                    ),
                                                  ],
                                                ),
                                                if (events.isEmpty)
                                                  Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.cream,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(12),
                                                      border: Border.all(
                                                        color:
                                                            AppColors.border1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Rien de prévu ce jour',
                                                      style: AppTypography
                                                          .bodySmall
                                                          .copyWith(
                                                        color: AppColors
                                                            .inkTertiary,
                                                      ),
                                                    ),
                                                  ),
                                                ...events.map((event) {
                                                  final time =
                                                      '${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}';
                                                  final bgColor = event.type ==
                                                          'medication'
                                                      ? AppColors.sageBgLight
                                                      : const Color(0xFFF5EBE0);
                                                  final iconColor =
                                                      event.type == 'medication'
                                                          ? AppColors.sage
                                                          : AppColors.clay;

                                                  return GestureDetector(
                                                    onTap: event.type ==
                                                            'medication'
                                                        ? () async {
                                                            // Toggle mark as taken
                                                            try {
                                                              if (event
                                                                  .completed) {
                                                                await ref
                                                                    .read(medicationLogNotifier
                                                                        .notifier)
                                                                    .markNotTaken(
                                                                      event
                                                                          .scheduleId,
                                                                      event
                                                                          .date,
                                                                      time: event
                                                                          .reminderTime,
                                                                    );
                                                              } else {
                                                                await ref
                                                                    .read(medicationLogNotifier
                                                                        .notifier)
                                                                    .markTaken(
                                                                      event
                                                                          .scheduleId,
                                                                      event
                                                                          .date,
                                                                      time: event
                                                                          .reminderTime,
                                                                    );
                                                              }
                                                            } catch (e) {
                                                              if (context
                                                                  .mounted) {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                        'Non synchronisé avec votre partenaire: $e'),
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          }
                                                        : () {
                                                            GoRouter.of(context)
                                                                .push(
                                                              '/appointments/edit/${event.id}',
                                                            );
                                                          },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color:
                                                              AppColors.border1,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 40,
                                                            height: 40,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: bgColor,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Center(
                                                              child: Icon(
                                                                event.type ==
                                                                        'medication'
                                                                    ? Icons
                                                                        .healing
                                                                    : Icons
                                                                        .event_outlined,
                                                                color:
                                                                    iconColor,
                                                                size: 20,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  '$time · ${event.title}',
                                                                  style: AppTypography
                                                                      .bodyMedium
                                                                      .copyWith(
                                                                    decoration: event
                                                                            .completed
                                                                        ? TextDecoration
                                                                            .lineThrough
                                                                        : null,
                                                                    color: event.completed
                                                                        ? AppColors
                                                                            .inkTertiary
                                                                        : AppColors
                                                                            .ink,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  event
                                                                      .subtitle,
                                                                  style: AppTypography
                                                                      .bodySmall
                                                                      .copyWith(
                                                                    color: AppColors
                                                                        .inkTertiary,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (event.type ==
                                                              'medication')
                                                            GestureDetector(
                                                              onTap: () async {
                                                                try {
                                                                  if (event
                                                                      .completed) {
                                                                    await ref
                                                                        .read(medicationLogNotifier
                                                                            .notifier)
                                                                        .markNotTaken(
                                                                          event
                                                                              .scheduleId,
                                                                          event
                                                                              .date,
                                                                          time:
                                                                              event.reminderTime,
                                                                        );
                                                                  } else {
                                                                    await ref
                                                                        .read(medicationLogNotifier
                                                                            .notifier)
                                                                        .markTaken(
                                                                          event
                                                                              .scheduleId,
                                                                          event
                                                                              .date,
                                                                          time:
                                                                              event.reminderTime,
                                                                        );
                                                                  }
                                                                } catch (e) {
                                                                  if (context
                                                                      .mounted) {
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text('Non synchronisé avec votre partenaire: $e'),
                                                                      ),
                                                                    );
                                                                  }
                                                                }
                                                              },
                                                              behavior:
                                                                  HitTestBehavior
                                                                      .opaque,
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        12),
                                                                child: Icon(
                                                                  event.completed
                                                                      ? Icons
                                                                          .check_circle
                                                                      : Icons
                                                                          .radio_button_unchecked,
                                                                  color: event
                                                                          .completed
                                                                      ? AppColors
                                                                          .sage
                                                                      : AppColors
                                                                          .inkTertiary,
                                                                  size: 20,
                                                                ),
                                                              ),
                                                            ),
                                                          if (event.type !=
                                                              'medication')
                                                            Icon(
                                                              Icons
                                                                  .chevron_right,
                                                              color: AppColors
                                                                  .inkTertiary,
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                            );
                                          }).toList(),
                                        );
                                      },
                                      loading: () =>
                                          const CircularProgressIndicator(),
                                      error: (_, __) => const SizedBox.shrink(),
                                    );
                                  },
                                  loading: () =>
                                      const CircularProgressIndicator(),
                                  error: (_, __) => const SizedBox.shrink(),
                                );
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduledEvent {
  final String id;
  final String scheduleId;
  final DateTime time;
  final String title;
  final String subtitle;
  final String type;
  final bool completed;
  final DateTime date;
  // Raw "HH:mm" reminder slot (medication events only) - a schedule with
  // several reminder times a day needs this to mark just one dose taken
  // instead of all of them sharing one log entry.
  final String? reminderTime;

  _ScheduledEvent({
    required this.id,
    required this.scheduleId,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.completed,
    required this.date,
    this.reminderTime,
  });
}

// Helper to create a default (not-taken) log entry
MedicationTakenLog _createDefaultLog(String id) {
  return MedicationTakenLog(
    id: id,
    medicationScheduleId: '',
    date: DateTime.now(),
    taken: false,
    takenAt: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
