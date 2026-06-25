import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/medication_provider.dart';
import '../../widgets/ltmo_card.dart';

class TreatmentListScreen extends ConsumerWidget {
  const TreatmentListScreen({super.key});

  String _getMedicationIcon(String? form) {
    switch (form) {
      case 'injection':
        return '💉';
      case 'comprimé':
        return '💊';
      case 'patch':
        return '🩹';
      case 'ovule':
        return '⭕';
      default:
        return '💊';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes traitements')),
      body: medications.when(
        data: (meds) {
          final activeMeds = meds.where((m) => m.active).toList();

          if (activeMeds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Aucun traitement en cours',
                    style: AppTypography.headline3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/medications/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un traitement'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeMeds.length,
            itemBuilder: (context, index) {
              final med = activeMeds[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LtmoCard(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${med.name} - ${med.dosage} ${med.unit}')),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getMedicationIcon(med.form),
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: AppTypography.titleMedium,
                                ),
                                Text(
                                  '${med.dosage} ${med.unit}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.inkTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sageBgLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Actif',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.sage,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (med.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          med.description!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/medications/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
