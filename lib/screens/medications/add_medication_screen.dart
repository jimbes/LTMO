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

class AddMedicationScreen extends ConsumerWidget {
  const AddMedicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    'Nouveau traitement',
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
              child: MedicationForm(
                title: 'Nouveau traitement',
                buttonLabel: 'Enregistrer le traitement',
                onSubmit: (medication, schedule) async {
                  final userState = ref.read(userProvider);
                  final coupleId = userState.maybeWhen(
                    data: (user) => user?.coupleId,
                    orElse: () => null,
                  );

                  if (coupleId == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Erreur: Impossible de récupérer votre couple ID',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  try {
                    final med = medication.copyWith(coupleId: coupleId);

                    // Add medication first, and get back its real server-assigned ID
                    final createdMedication = await ref
                        .read(medicationProvider.notifier)
                        .addMedication(med);

                    // Then add schedule, linked to the real medication ID
                    final sched = schedule.copyWith(
                      coupleId: coupleId,
                      medicationId: createdMedication.id,
                    );
                    await ref.read(medicationProvider.notifier).addSchedule(sched);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Médicament et horaire ajoutés avec succès'),
                          duration: Duration(milliseconds: 1500),
                        ),
                      );
                      // Refresh providers
                      ref.invalidate(medicationsProvider);
                      ref.invalidate(schedulesProvider);
                      context.pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la création: $e'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
