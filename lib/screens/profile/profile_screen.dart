import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/journey_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getPhaseLabel(String type) {
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
        return type;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = ref.watch(stagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Parcours')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Couple header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sageBgLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.sage,
                      child: Text('👤', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Léa & Tom',
                            style: AppTypography.titleLarge,
                          ),
                          Text(
                            'Parcours PMA en cours',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Journey timeline
              Text(
                'Votre parcours FIV',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 16),

              stages.when(
                data: (stageList) {
                  final phases = [
                    'stimulation',
                    'declenchement',
                    'ponction',
                    'transfert',
                    'attente_test'
                  ];

                  return Column(
                    children: List.generate(phases.length, (index) {
                      final phase = phases[index];
                      final stage = stageList.cast<dynamic>().firstWhere(
                        (s) => (s as dynamic).type == phase,
                        orElse: () => null,
                      ) as dynamic?;

                      final isCompleted = stage != null && stage.status == 'done';
                      final isActive = stage != null && stage.status == 'in_progress';

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.sageBgLight
                                  : isActive
                                      ? AppColors.clayBgLight
                                      : AppColors.border2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCompleted
                                    ? AppColors.sage
                                    : isActive
                                        ? AppColors.clay
                                        : AppColors.border1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? AppColors.sage
                                        : isActive
                                            ? AppColors.clay
                                            : AppColors.border1,
                                  ),
                                  child: isCompleted
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 16)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getPhaseLabel(phase),
                                        style: AppTypography.bodyMedium,
                                      ),
                                      if (stage != null)
                                        Text(
                                          'Débuté le ${stage.startDate.day}/${stage.startDate.month}/${stage.startDate.year}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                            color: AppColors.inkTertiary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isCompleted
                                      ? AppColors.sage
                                      : AppColors.inkTertiary,
                                ),
                              ],
                            ),
                          ),
                          if (index < phases.length - 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Container(
                                height: 2,
                                color: AppColors.border1,
                              ),
                            ),
                        ],
                      );
                    }),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('Erreur: $error'),
              ),

              const SizedBox(height: 32),

              // Quick actions
              Text(
                'Actions',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _ActionCard(
                    icon: Icons.edit,
                    label: 'Configurer\nmon parcours',
                    onTap: () => context.push('/journey/configure'),
                  ),
                  _ActionCard(
                    icon: Icons.local_hospital,
                    label: 'Mes\npraticiens',
                    onTap: () => context.push('/practitioners'),
                  ),
                  _ActionCard(
                    icon: Icons.share,
                    label: 'Partage\npartenaire',
                    onTap: () => context.push('/partner-sharing'),
                  ),
                  _ActionCard(
                    icon: Icons.settings,
                    label: 'Configuration',
                    onTap: () => context.push('/profile/edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.sage, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
