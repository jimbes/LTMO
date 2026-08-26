import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/treatment_cycle_provider.dart';
import '../../models/treatment_cycle.dart';
import 'configure_journey_screen.dart' show phaseColorForStatus, statusLabelFor, displayLabelForStage;

class CycleHistoryScreen extends ConsumerWidget {
  const CycleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cycleHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des cycles'),
        elevation: 0,
      ),
      body: cyclesAsync.when(
        data: (cycles) {
          if (cycles.isEmpty) {
            return Center(
              child: Text(
                'Aucun cycle enregistré.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cycles.length,
            itemBuilder: (context, index) {
              final cycle = cycles[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _CycleStagesScreen(cycle: cycle),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cycle ${cycle.cycleNumber}',
                                style: AppTypography.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Depuis le ${cycle.startDate.day}/${cycle.startDate.month}/${cycle.startDate.year}'
                                '${cycle.endDate != null ? ' jusqu\'au ${cycle.endDate!.day}/${cycle.endDate!.month}/${cycle.endDate!.year}' : ''}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.inkTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.inkTertiary),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}

class _CycleStagesScreen extends ConsumerWidget {
  final TreatmentCycle cycle;

  const _CycleStagesScreen({required this.cycle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(cycleStagesProvider(cycle.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Cycle ${cycle.cycleNumber}'),
        elevation: 0,
      ),
      body: stagesAsync.when(
        data: (stages) {
          if (stages.isEmpty) {
            return Center(
              child: Text(
                'Aucune étape dans ce cycle.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stages.length,
            itemBuilder: (context, index) {
              final stage = stages[index];
              final color = phaseColorForStatus(stage.status);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration:
                            BoxDecoration(shape: BoxShape.circle, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayLabelForStage(stage),
                              style: AppTypography.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusLabelFor(stage.status),
                              style: AppTypography.bodySmall
                                  .copyWith(color: color),
                            ),
                          ],
                        ),
                      ),
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
    );
  }
}
