import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/journey_provider.dart';
import '../../providers/today_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/ltmo_card.dart';
import '../../widgets/ltmo_button.dart';
import '../../widgets/phase_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getPhaseLabel(String? type) {
    switch (type) {
      case 'stimulation':
        return 'Stimulation';
      case 'declenchement':
        return 'Déclenchement';
      case 'ponction':
        return 'Ponction';
      case 'transfert':
        return 'Transfert';
      case 'attente_test':
        return 'Attente & Test';
      default:
        return 'Phase en cours';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPhase = ref.watch(currentPhaseProvider);
    final todayEvents = ref.watch(todayEventsProvider);
    final todayProgress = ref.watch(todayProgressProvider);
    final upcomingAppointments = ref.watch(upcomingAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LTMO'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and phase badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue',
                        style: AppTypography.headline2,
                      ),
                      const SizedBox(height: 8),
                      currentPhase.when(
                        data: (phase) => PhaseBadge(
                          phase: _getPhaseLabel(phase?.type),
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.sageBgLight,
                    child: Icon(Icons.person, color: AppColors.sage),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Progress section
              Text(
                'À suivre aujourd\'hui',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 12),

              todayProgress.when(
                data: (progress) {
                  final completed = progress['completed'] ?? 0;
                  final total = progress['total'] ?? 0;
                  final percent = total > 0 ? completed / total : 0.0;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completed/$total complété',
                            style: AppTypography.bodyMedium,
                          ),
                          Text(
                            '${(percent * 100).toStringAsFixed(0)}%',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.sage,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 8,
                          backgroundColor: AppColors.border1,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percent > 0.5 ? AppColors.sage : AppColors.clay,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Mark all as taken button
              SizedBox(
                width: double.infinity,
                child: LtmoPrimaryButton(
                  label: 'Marquer comme pris',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tous les traitements marqués comme pris')),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Today's items
              Text(
                'Détail',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 12),

              todayEvents.when(
                data: (events) {
                  if (events.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Rien à suivre aujourd\'hui',
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
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: AppTypography.bodyMedium,
                                    ),
                                    if (event.time != null)
                                      Text(
                                        '${event.time!.hour}:${event.time!.minute.toString().padLeft(2, '0')}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.inkTertiary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: event.completed,
                                onChanged: (_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        event.completed
                                            ? 'Marqué comme non pris'
                                            : 'Marqué comme pris',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => Text('Erreur: $_'),
              ),

              const SizedBox(height: 24),

              // Next appointment
              Text(
                'Prochain rendez-vous',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 12),

              upcomingAppointments.when(
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return LtmoCard(
                      child: Center(
                        child: Text(
                          'Aucun rendez-vous prévu',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.inkTertiary,
                          ),
                        ),
                      ),
                    );
                  }

                  final next = appointments.first;
                  return LtmoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          next.title,
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${next.appointmentDate.day}/${next.appointmentDate.month}/${next.appointmentDate.year}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                        if (next.appointmentTime != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${next.appointmentTime!.hour}:${next.appointmentTime!.minute.toString().padLeft(2, '0')}',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
