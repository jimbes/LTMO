import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/appointment_form.dart';

class AddAppointmentScreen extends ConsumerWidget {
  const AddAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Text('Nouveau rendez-vous', style: AppTypography.headline1),
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
              child: AppointmentForm(
                buttonLabel: 'Enregistrer le rendez-vous',
                onSubmit: (appointment) async {
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

                  final apt = appointment.copyWith(coupleId: coupleId);
                  await ref
                      .read(appointmentProvider.notifier)
                      .addAppointment(apt);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rendez-vous ajouté avec succès'),
                      ),
                    );
                    context.pop();
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
