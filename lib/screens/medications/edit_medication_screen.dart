import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/medication.dart';
import '../../models/medication_schedule.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/medication_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/medication_form.dart';

class EditMedicationScreen extends ConsumerWidget {
  final String medicationId;
  final String scheduleId;

  const EditMedicationScreen({
    super.key,
    required this.medicationId,
    required this.scheduleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider);
    final schedulesAsync = ref.watch(schedulesProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
              color: AppColors.cream,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Modifier',
                    style: AppTypography.headline1,
                  ),
                ],
              ),
            ),

            // Form content
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: medicationsAsync.when(
                data: (medications) {
                  return schedulesAsync.when(
                    data: (schedules) {
                      Medication? medication;
                      try {
                        medication =
                            medications.firstWhere((m) => m.id == medicationId);
                      } catch (_) {
                        medication = null;
                      }

                      MedicationSchedule? schedule;
                      try {
                        schedule =
                            schedules.firstWhere((s) => s.id == scheduleId);
                      } catch (_) {
                        schedule = null;
                      }

                      if (medication == null || schedule == null) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Erreur: médicament ou horaire introuvable',
                          ),
                        );
                      }

                      return MedicationForm(
                        title: 'Modifier',
                        buttonLabel: 'Modifier',
                        initialMedication: medication,
                        initialSchedule: schedule,
                        onSubmit: (updatedMedication, updatedSchedule) async {
                          try {
                            await ref
                                .read(medicationProvider.notifier)
                                .updateMedication(updatedMedication);
                            await ref
                                .read(medicationProvider.notifier)
                                .updateSchedule(updatedSchedule);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Médicament mis à jour avec succès',
                                  ),
                                ),
                              );
                              context.pop();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
                          }
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => Text('Erreur: $error'),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('Erreur: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
