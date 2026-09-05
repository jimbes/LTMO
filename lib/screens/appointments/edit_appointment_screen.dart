import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/journey_stage.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/journey_provider.dart';
import '../../providers/treatment_cycle_provider.dart';
import '../../widgets/appointment_form.dart';

class EditAppointmentScreen extends ConsumerWidget {
  final String appointmentId;

  const EditAppointmentScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: appointmentsAsync.when(
                data: (appointments) {
                  final matches =
                      appointments.where((a) => a.id == appointmentId).toList();
                  final appointment = matches.isEmpty ? null : matches.first;

                  if (appointment == null) {
                    return const Text(
                      'Erreur: rendez-vous introuvable',
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!appointment.completed) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.sage,
                                side: const BorderSide(color: AppColors.sage),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () async {
                                await ref
                                    .read(appointmentProvider.notifier)
                                    .markComplete(appointment.id);

                                if (!context.mounted) return;

                                // A visit that's purely a blood test rarely
                                // changes the treatment plan - that decision
                                // happens at the consult/echo/procedure that
                                // reads the result, so skip the wizard for
                                // those. If blood test is combined with
                                // anything else, the wizard stays relevant.
                                final isPureBloodTest =
                                    appointment.types.length == 1 &&
                                        appointment.types.first ==
                                            'blood_test';
                                if (!isPureBloodTest) {
                                  await context
                                      .push('/appointments/post-visit');
                                }

                                if (context.mounted) context.pop();
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Marquer comme terminé'),
                            ),
                          ),
                        ),
                        if (appointment.journeyStageId != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Suite à ce rendez-vous',
                                    style: AppTypography.labelMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () => _markStageSkipped(
                                        context,
                                        ref,
                                        appointment.journeyStageId!,
                                      ),
                                      child: const Text(
                                        'Marquer l\'étape comme ignorée',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _confirmStartNewCycle(context, ref),
                                      child: const Text(
                                        'Démarrer un nouveau cycle',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                      AppointmentForm(
                        buttonLabel: 'Modifier',
                        initialAppointment: appointment,
                        onSubmit: (updated) async {
                          await ref
                              .read(appointmentProvider.notifier)
                              .updateAppointment(updated);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Rendez-vous mis à jour'),
                              ),
                            );
                            context.pop();
                          }
                        },
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Supprimer ce rendez-vous ?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Supprimer',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await ref
                                .read(appointmentProvider.notifier)
                                .deleteAppointment(appointmentId);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rendez-vous supprimé'),
                                ),
                              );
                              context.pop();
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Erreur: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _markStageSkipped(
  BuildContext context,
  WidgetRef ref,
  String stageId,
) async {
  try {
    final stages = await ref.read(stagesProvider.future);
    JourneyStage? stage;
    for (final s in stages) {
      if (s.id == stageId) {
        stage = s;
        break;
      }
    }
    if (stage == null) return;

    await ref
        .read(journeyProvider.notifier)
        .updateStage(stage.copyWith(status: 'skipped'));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Étape marquée comme ignorée')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}

Future<void> _confirmStartNewCycle(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Démarrer un nouveau cycle ?'),
      content: const Text(
        'Le parcours actuel sera archivé (consultable dans l\'historique) '
        'et un nouveau parcours vide démarrera.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Démarrer'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await ref.read(treatmentCycleActionsProvider).startNewCycle();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau cycle démarré')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
