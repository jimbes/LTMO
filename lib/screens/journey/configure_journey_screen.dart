import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/journey_provider.dart';

class ConfigureJourneyScreen extends ConsumerWidget {
  const ConfigureJourneyScreen({super.key});

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

  Color _getPhaseColor(String status) {
    switch (status) {
      case 'done':
        return AppColors.sage;
      case 'in_progress':
        return AppColors.clay;
      default:
        return AppColors.border1;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = ref.watch(stagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurer mon parcours FIV'),
        elevation: 0,
      ),
      body: stages.when(
        data: (stageList) {
          final phases = [
            'stimulation',
            'declenchement',
            'ponction',
            'transfert',
            'attente_test'
          ];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: phases.length,
            itemBuilder: (context, index) {
              final phase = phases[index];
              final stage = stageList.cast<dynamic>().firstWhere(
                (s) => (s as dynamic).type == phase,
                orElse: () => null,
              ) as dynamic?;

              final status = stage?.status ?? 'upcoming';
              final startDate = stage?.startDate;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _showEditStageSheet(context, ref, stage, phase),
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getPhaseColor(status),
                          ),
                          child: status == 'done'
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 24)
                              : status == 'in_progress'
                                  ? const Icon(Icons.play_arrow,
                                      color: Colors.white, size: 24)
                                  : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getPhaseLabel(phase),
                                style: AppTypography.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              if (startDate != null)
                                Text(
                                  'Débuté le ${startDate.day}/${startDate.month}/${startDate.year}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.inkTertiary,
                                  ),
                                )
                              else
                                Text(
                                  'Non commencé',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.inkTertiary,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getPhaseColor(status)
                                      .withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status == 'done'
                                      ? 'Terminé'
                                      : status == 'in_progress'
                                          ? 'En cours'
                                          : 'À venir',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getPhaseColor(status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_outlined,
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

  void _showEditStageSheet(
    BuildContext context,
    WidgetRef ref,
    dynamic stage,
    String phaseType,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditStageSheet(
        stage: stage,
        phaseType: phaseType,
      ),
    );
  }
}

class _EditStageSheet extends ConsumerStatefulWidget {
  final dynamic stage;
  final String phaseType;

  const _EditStageSheet({
    required this.stage,
    required this.phaseType,
  });

  @override
  ConsumerState<_EditStageSheet> createState() => _EditStageSheetState();
}

class _EditStageSheetState extends ConsumerState<_EditStageSheet> {
  late DateTime _selectedDate;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.stage?.startDate ?? DateTime.now();
    _selectedStatus = widget.stage?.status ?? 'upcoming';
  }

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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveStage() {
    // For now, we're just closing the sheet
    // In production, this would call ref.read(journeyProvider.notifier).updateStage()
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Étape mise à jour')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Modifier ${_getPhaseLabel(widget.phaseType)}',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 24),

            // Date selector
            Text('Date de début', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: AppTypography.bodyMedium,
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status selector
            Text('Statut', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['upcoming', 'in_progress', 'done'].map((status) {
                final isSelected = _selectedStatus == status;
                final statusLabel = status == 'upcoming'
                    ? 'À venir'
                    : status == 'in_progress'
                        ? 'En cours'
                        : 'Terminé';
                return FilterChip(
                  label: Text(statusLabel),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedStatus = status);
                  },
                  selectedColor: AppColors.sage,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.ink,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sage,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _saveStage,
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
