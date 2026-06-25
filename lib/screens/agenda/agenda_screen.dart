import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/today_provider.dart';
import '../../widgets/ltmo_card.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final todayEvents = ref.watch(todayEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: LtmoCard(
                padding: EdgeInsets.zero,
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: AppColors.sage,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.sageBgLight,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: AppTypography.bodyMedium,
                    weekendTextStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                    selectedTextStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: AppTypography.titleMedium,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Événements du ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  todayEvents.when(
                    data: (events) {
                      // Filter events for selected day
                      final selectedEvents = events.where((e) {
                        if (e.time == null) return false;
                        return e.time!.year == _selectedDay.year &&
                            e.time!.month == _selectedDay.month &&
                            e.time!.day == _selectedDay.day;
                      }).toList();

                      if (selectedEvents.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Aucun événement ce jour',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final event = selectedEvents[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: LtmoCard(
                              child: Row(
                                children: [
                                  Icon(
                                    event.type == 'medication'
                                        ? Icons.medication
                                        : Icons.event,
                                    color: AppColors.sage,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: AppTypography.bodyMedium,
                                        ),
                                        if (event.time != null)
                                          Text(
                                            '${event.time!.hour}:${event.time!.minute.toString().padLeft(2, '0')}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.inkTertiary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: event.completed
                                            ? AppColors.sage
                                            : AppColors.border1,
                                      ),
                                      color: event.completed
                                          ? AppColors.sage
                                          : Colors.transparent,
                                    ),
                                    child: event.completed
                                        ? const Icon(Icons.check,
                                            size: 12, color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
