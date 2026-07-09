import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/journey_provider.dart';
import '../../providers/today_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_logs_provider.dart';
import '../../providers/data_refresh.dart';
import '../../widgets/ltmo_card.dart';
import '../../widgets/ltmo_button.dart';
import '../../utils/phase_labels.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _stagePhaseLabel(dynamic phase) {
    final custom = phase?.customName as String?;
    if (custom != null && custom.trim().isNotEmpty) return custom.trim();
    return getPhaseLabel(phase?.type as String?);
  }

  String _getFormLabel(String? form) {
    switch (form) {
      case 'injection':
        return 'Injection';
      case 'comprimé':
        return 'Comprimé';
      case 'patch':
        return 'Patch';
      case 'ovule':
        return 'Ovule';
      default:
        return 'Médicament';
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPhase = ref.watch(currentPhaseProvider);
    final todayEvents = ref.watch(todayEventsProvider);
    final upcomingAppointments = ref.watch(upcomingAppointmentsProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => refreshAllData(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16 + MediaQuery.of(context).padding.top,
                  16,
                  24,
                ),
                color: AppColors.cream,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE d MMMM', 'fr_FR')
                              .format(DateTime.now()),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        user.when(
                          data: (userData) => Text(
                            'Bonjour ${userData?.name.split(' ').first ?? 'Vous'}',
                            style: AppTypography.headline1,
                          ),
                          loading: () => Text(
                            'Bonjour',
                            style: AppTypography.headline1,
                          ),
                          error: (_, __) => Text(
                            'Bienvenue',
                            style: AppTypography.headline1,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.sageBgLight,
                      child: user.when(
                        data: (userData) => Text(
                          userData?.name.isNotEmpty == true
                              ? userData!.name[0].toUpperCase()
                              : 'L',
                          style: AppTypography.headline2.copyWith(
                            color: AppColors.sage,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const Icon(Icons.person),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Current phase section
                    currentPhase.when(
                      data: (phase) {
                        if (phase == null) {
                          return const SizedBox.shrink();
                        }
                        // Compare calendar days only, not instants - phase
                        // dates come from the backend as UTC timestamps, so
                        // diffing directly against local DateTime.now() can
                        // be off by a day depending on the device's UTC
                        // offset and time of day (same class of bug as the
                        // agenda's due-date check).
                        final today = DateTime.now();
                        final todayOnly =
                            DateTime(today.year, today.month, today.day);
                        final startOnly = DateTime(phase.startDate.year,
                            phase.startDate.month, phase.startDate.day);
                        final dayCount =
                            todayOnly.difference(startOnly).inDays + 1;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border1),
                          ),
                          child: Row(
                            children: [
                              // Phase icon/image
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.sageBgLight,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.favorite,
                                    color: AppColors.sage,
                                    size: 40,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Phase info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _stagePhaseLabel(phase),
                                      style: AppTypography.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.sage,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Jour $dayCount',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // Today's treatments section
                    Text(
                      'À suivre aujourd\'hui',
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    todayEvents.when(
                      data: (events) {
                        final medications = events
                            .where((e) => e.type == 'medication')
                            .toList();

                        if (medications.isEmpty) {
                          return LtmoCard(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Aucun traitement aujourd\'hui',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.inkTertiary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          spacing: 12,
                          children: medications.map((event) {
                            return LtmoCard(
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.sageBgLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.healing,
                                        color: AppColors.sage,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style:
                                              AppTypography.bodyMedium.copyWith(
                                            decoration: event.completed
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: event.completed
                                                ? AppColors.inkTertiary
                                                : AppColors.ink,
                                          ),
                                        ),
                                        if (event.subtitle != null)
                                          Text(
                                            event.subtitle!,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.inkTertiary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (event.time != null)
                                        Text(
                                          _formatTime(event.time),
                                          style:
                                              AppTypography.labelSmall.copyWith(
                                            color: event.completed
                                                ? AppColors.inkTertiary
                                                : AppColors.ink,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      if (event.completed)
                                        GestureDetector(
                                          onTap: event.scheduleId == null
                                              ? null
                                              : () async {
                                                  try {
                                                    await ref
                                                        .read(
                                                            medicationLogNotifier
                                                                .notifier)
                                                        .markNotTaken(
                                                          event.scheduleId!,
                                                          event.date!,
                                                          time: event
                                                              .reminderTime,
                                                        );
                                                  } catch (e) {
                                                    if (context.mounted) {
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
                                                },
                                          behavior: HitTestBehavior.opaque,
                                          child: const Padding(
                                            padding: EdgeInsets.all(14),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: AppColors.sage,
                                              size: 16,
                                            ),
                                          ),
                                        )
                                      else
                                        GestureDetector(
                                          onTap: event.scheduleId == null
                                              ? null
                                              : () async {
                                                  try {
                                                    await ref
                                                        .read(
                                                            medicationLogNotifier
                                                                .notifier)
                                                        .markTaken(
                                                          event.scheduleId!,
                                                          event.date!,
                                                          time: event
                                                              .reminderTime,
                                                        );
                                                  } catch (e) {
                                                    if (context.mounted) {
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
                                                },
                                          behavior: HitTestBehavior.opaque,
                                          child: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: AppColors.sage,
                                                  width: 1.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // Next appointment section
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
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Aucun rendez-vous prévu',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.inkTertiary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final next = appointments.first;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LtmoCard(
                              onTap: () {
                                GoRouter.of(context)
                                    .push('/appointments/edit/${next.id}');
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    next.title,
                                    style: AppTypography.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  if (next.location != null)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        next.location!,
                                        style:
                                            AppTypography.bodySmall.copyWith(
                                          color: AppColors.inkTertiary,
                                        ),
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: AppColors.clay,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('EEEE d MMMM', 'fr_FR')
                                            .format(next.appointmentDate),
                                        style:
                                            AppTypography.bodySmall.copyWith(
                                          color: AppColors.clay,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (next.appointmentTime != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: AppColors.clay,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatTime(next.appointmentTime),
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                            color: AppColors.clay,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    GoRouter.of(context).go(
                                      '/agenda',
                                      extra: next.appointmentDate,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.sage,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                  ),
                                  label: const Text('Voir plus'),
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
