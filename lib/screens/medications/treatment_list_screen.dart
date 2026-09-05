import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/medication_provider.dart';
import '../../providers/data_refresh.dart';
import '../../models/medication_schedule.dart';

class TreatmentListScreen extends ConsumerWidget {
  const TreatmentListScreen({super.key});

  Color _getFormColor(String? form) {
    switch (form) {
      case 'injection':
        return AppColors.clay;
      case 'comprimé':
        return AppColors.sage;
      case 'patch':
        return const Color(0xFFE8C5B3);
      case 'ovule':
        return const Color(0xFFD4A5A5);
      default:
        return AppColors.sage;
    }
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

  String _getFrequencyLabel(MedicationSchedule? schedule) {
    if (schedule == null) return '';
    if (schedule.frequency == 'daily') return 'tous les jours';
    if (schedule.frequency == 'specific_days' &&
        schedule.daysOfWeek != null &&
        schedule.daysOfWeek!.isNotEmpty) {
      const dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      final sortedDays = List<int>.from(schedule.daysOfWeek!)..sort();
      return sortedDays.map((d) => dayLabels[d]).join(', ');
    }
    return '';
  }

  void _showEditDeleteSheet(BuildContext context, dynamic med, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final schedulesAsync = ref.watch(schedulesProvider);
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 80,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    med.name,
                    style: AppTypography.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Modifier'),
                    onTap: () {
                      Navigator.pop(context);
                      schedulesAsync.whenData((scheds) {
                        try {
                          final schedule = scheds.firstWhere(
                            (s) => s.medicationId == med.id,
                          );
                          GoRouter.of(context).push(
                            '/medications/edit/${med.id}/${schedule.id}',
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Erreur: Aucun horaire trouvé pour ce médicament',
                                ),
                              ),
                            );
                          }
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await ref
                            .read(medicationProvider.notifier)
                            .deleteMedication(med.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Médicament supprimé'),
                              duration: Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationsProvider);
    final schedulesAsync = ref.watch(schedulesProvider);

    return Scaffold(
      body: medications.when(
        data: (meds) {
          final activeMeds = meds.where((m) => m.active).toList();
          final schedules = schedulesAsync.valueOrNull ?? [];
          // A medication can have more than one schedule (e.g. a morning
          // period and a separate evening period with their own date
          // ranges) - group instead of keying a single value per medication
          // id, which used to silently keep only the last one encountered.
          final schedulesByMedicationId = <String, List<MedicationSchedule>>{};
          for (final s in schedules) {
            schedulesByMedicationId.putIfAbsent(s.medicationId, () => []).add(s);
          }

          return RefreshIndicator(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mes traitements',
                          style: AppTypography.headline1,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'EN COURS · ${activeMeds.length}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Medications list
                  if (activeMeds.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Aucun traitement en cours',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        spacing: 12,
                        children: activeMeds.map((med) {
                          final formColor = _getFormColor(med.form);
                          final medSchedules =
                              schedulesByMedicationId[med.id] ?? [];
                          final frequencyLabel = _getFrequencyLabel(
                            medSchedules.isEmpty ? null : medSchedules.first,
                          );
                          final reminderActive = medSchedules.any(
                            (s) => s.notifyUser1 || s.notifyUser2,
                          );
                          final allReminderTimes = medSchedules
                              .expand((s) => s.reminderTimes)
                              .toSet()
                              .toList()
                            ..sort();

                          return GestureDetector(
                            onTap: () =>
                                _showEditDeleteSheet(context, med, ref),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Icon
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: formColor.withAlpha(80),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          med.form == 'injection'
                                              ? Icons.healing
                                              : Icons.medication,
                                          color: formColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${med.name} · ${med.dosage} ${med.unit}',
                                              style: AppTypography.titleSmall,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              frequencyLabel.isNotEmpty
                                                  ? '${_getFormLabel(med.form)} · $frequencyLabel'
                                                  : _getFormLabel(med.form),
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: AppColors.inkTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Time badges
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ...allReminderTimes.map(
                                          (time) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.sageBgLight,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              time,
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                color: AppColors.sage,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.sageBgLight,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          reminderActive
                                              ? 'Rappel actif'
                                              : 'Rappel désactivé',
                                          style:
                                              AppTypography.labelSmall.copyWith(
                                            color: AppColors.sage,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}
