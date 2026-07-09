import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/journey_provider.dart';
import '../../models/journey_stage.dart';
import '../../utils/phase_labels.dart';

String _displayLabel(JourneyStage stage) {
  final custom = stage.customName;
  if (custom != null && custom.trim().isNotEmpty) return custom.trim();
  return getPhaseLabel(stage.type);
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

class ConfigureJourneyScreen extends ConsumerWidget {
  const ConfigureJourneyScreen({super.key});

  void _showAddStageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ajouter une étape', style: AppTypography.titleLarge),
                const SizedBox(height: 16),
                ...defaultJourneyStageTypes.map((type) {
                  return ListTile(
                    title: Text(getPhaseLabel(type)),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(journeyProvider.notifier).addStageAtEnd(type);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditStageSheet(
    BuildContext context,
    WidgetRef ref,
    JourneyStage stage,
    bool isLast,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditStageSheet(stage: stage, isLast: isLast),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(stagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurer mon parcours FIV'),
        elevation: 0,
      ),
      body: stagesAsync.when(
        data: (stages) {
          return Column(
            children: [
              Expanded(
                child: stages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Aucune étape configurée. Ajoutez votre première étape.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.inkTertiary,
                            ),
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: stages.length,
                        onReorder: (oldIndex, newIndex) {
                          final newList = List<JourneyStage>.from(stages);
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = newList.removeAt(oldIndex);
                          newList.insert(newIndex, item);
                          ref
                              .read(journeyProvider.notifier)
                              .reorderStages(newList)
                              .catchError((e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
                          });
                        },
                        itemBuilder: (context, index) {
                          final stage = stages[index];
                          final isLast = index == stages.length - 1;
                          final status = stage.status;

                          return Padding(
                            key: ValueKey(stage.id),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () => _showEditStageSheet(
                                context,
                                ref,
                                stage,
                                isLast,
                              ),
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
                                                  color: Colors.white,
                                                  size: 24)
                                              : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _displayLabel(stage),
                                            style: AppTypography.titleSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Du ${stage.startDate.day}/${stage.startDate.month}/${stage.startDate.year}'
                                            '${stage.endDate != null ? ' au ${stage.endDate!.day}/${stage.endDate!.month}/${stage.endDate!.year}' : ''}'
                                            '${!isLast && stage.durationDays != null ? ' (${stage.durationDays} j)' : ''}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.inkTertiary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getPhaseColor(status)
                                                  .withAlpha(30),
                                              borderRadius:
                                                  BorderRadius.circular(6),
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
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(Icons.drag_handle,
                                            color: AppColors.inkTertiary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sage,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showAddStageSheet(context, ref),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Ajouter une étape',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}

class _EditStageSheet extends ConsumerStatefulWidget {
  final JourneyStage stage;
  final bool isLast;

  const _EditStageSheet({
    required this.stage,
    required this.isLast,
  });

  @override
  ConsumerState<_EditStageSheet> createState() => _EditStageSheetState();
}

class _EditStageSheetState extends ConsumerState<_EditStageSheet> {
  late TextEditingController _nameController;
  late DateTime _selectedStartDate;
  late String _selectedStatus;
  late DateTime? _selectedEndDate;
  late int _durationDays;
  late bool _manualEndDate;
  bool _showMoreOptions = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _displayLabel(widget.stage));
    _selectedStartDate = widget.stage.startDate;
    _selectedStatus = widget.stage.status;
    _selectedEndDate = widget.stage.endDate;
    _durationDays = widget.stage.durationDays ?? 3;
    // The last stage always uses a manual end date; for other stages this
    // reflects whether the user explicitly overrode the computed one.
    _manualEndDate = widget.isLast || widget.stage.manualEndDate;
    _showMoreOptions = !widget.isLast && widget.stage.manualEndDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedStartDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? DateTime.now(),
      firstDate: _selectedStartDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedEndDate = picked);
    }
  }

  void _changeDuration(int delta) {
    setState(() {
      _durationDays = (_durationDays + delta).clamp(1, 365);
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      final isManual = widget.isLast || _manualEndDate;
      final endDateValue = isManual ? _selectedEndDate : null;
      final durationValue = widget.isLast ? null : _durationDays;
      final trimmedName = _nameController.text.trim();
      final defaultLabel = getPhaseLabel(widget.stage.type);
      final customNameValue =
          trimmedName.isEmpty || trimmedName == defaultLabel
              ? null
              : trimmedName;

      final updatedStage = widget.stage.copyWith(
        startDate: _selectedStartDate,
        status: _selectedStatus,
        endDate: endDateValue,
        clearEndDate: endDateValue == null,
        durationDays: durationValue,
        clearDurationDays: durationValue == null,
        manualEndDate: isManual,
        customName: customNameValue,
        clearCustomName: customNameValue == null,
      );

      await ref.read(journeyProvider.notifier).updateStage(updatedStage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Étape enregistrée'),
            duration: Duration(milliseconds: 1500),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _removeStage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette étape ?'),
        content: const Text(
          'Les étapes suivantes seront automatiquement décalées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _saving = true);
      try {
        await ref.read(journeyProvider.notifier).removeStage(widget.stage.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Modifier ${_displayLabel(widget.stage)}',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 24),

            // Custom name (the type stays a fixed category, but the
            // displayed label can be personalized, e.g. "Ponction ovocytes")
            Text('Nom de l\'étape', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: getPhaseLabel(widget.stage.type),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Catégorie : ${getPhaseLabel(widget.stage.type)}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
            const SizedBox(height: 24),

            // Start date selector (only truly editable for the first stage;
            // for chained stages it's computed, but still shown read-only)
            Text('Date de début', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.stage.order == 0 ? _selectStartDate : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border1),
                  borderRadius: BorderRadius.circular(12),
                  color: widget.stage.order == 0
                      ? Colors.transparent
                      : AppColors.sageBgLight,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedStartDate.day}/${_selectedStartDate.month}/${_selectedStartDate.year}',
                      style: AppTypography.bodyMedium,
                    ),
                    if (widget.stage.order == 0)
                      const Icon(Icons.calendar_today)
                    else
                      Text(
                        'Auto',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Duration (non-last stages) or manual end date (last stage)
            if (!widget.isLast) ...[
              if (!_manualEndDate) ...[
                Text('Durée (jours)', style: AppTypography.labelMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeDuration(-1),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.sage,
                    ),
                    Expanded(
                      child: Text(
                        '$_durationDays jour${_durationDays > 1 ? 's' : ''}',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeDuration(1),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.sage,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Date de fin calculée automatiquement',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ] else ...[
                Text('Date de fin', style: AppTypography.labelMedium),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectEndDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedEndDate != null
                              ? '${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}'
                              : 'Non définie',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _selectedEndDate != null
                                ? AppColors.ink
                                : AppColors.inkTertiary,
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // "More options" — lets the user override the auto-computed
              // end date for a non-last stage instead of using the duration.
              InkWell(
                onTap: () =>
                    setState(() => _showMoreOptions = !_showMoreOptions),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _showMoreOptions
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppColors.inkTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Plus d\'options',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showMoreOptions)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Définir une date de fin manuelle'),
                  subtitle: const Text(
                    'Sinon, elle est calculée à partir de la durée',
                  ),
                  value: _manualEndDate,
                  activeThumbColor: AppColors.sage,
                  onChanged: (value) {
                    setState(() {
                      _manualEndDate = value;
                      if (value) {
                        _selectedEndDate ??= _selectedStartDate
                            .add(Duration(days: _durationDays));
                      }
                    });
                  },
                ),
              const SizedBox(height: 24),
            ] else ...[
              Text('Date de fin (optionnelle)', style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectEndDate,
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
                        _selectedEndDate != null
                            ? '${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}'
                            : 'Non définie',
                        style: AppTypography.bodyMedium.copyWith(
                          color: _selectedEndDate != null
                              ? AppColors.ink
                              : AppColors.inkTertiary,
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

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
                    setState(() {
                      _selectedStatus = status;
                      if (status == 'done' && widget.isLast) {
                        _selectedEndDate ??= DateTime.now();
                      }
                    });
                  },
                  selectedColor: AppColors.sage,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.ink,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _removeStage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sage,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _saving ? null : _saveChanges,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
