import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/appointment_provider.dart';
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
                      if (!appointment.completed)
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

                                // Blood tests alone rarely change the
                                // treatment plan - that decision happens at
                                // the consult/echo/procedure that reads the
                                // result, so skip the wizard for those.
                                if (appointment.type != 'blood_test') {
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
