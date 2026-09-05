import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication.dart';
import '../models/medication_schedule.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/journey_provider.dart';
import '../models/journey_stage.dart';
import '../utils/phase_labels.dart';
import 'cycle_day_badge.dart';
import 'reminder_offsets_picker.dart';

typedef MedicationFormCallback = Future<void> Function(
  Medication medication,
  MedicationSchedule schedule,
);

class MedicationForm extends ConsumerStatefulWidget {
  final String title;
  final String buttonLabel;
  final Medication? initialMedication;
  final MedicationSchedule? initialSchedule;
  final MedicationFormCallback onSubmit;

  const MedicationForm({
    super.key,
    required this.title,
    required this.buttonLabel,
    required this.onSubmit,
    this.initialMedication,
    this.initialSchedule,
  });

  @override
  ConsumerState<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends ConsumerState<MedicationForm> {
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late String _selectedUnit;
  late String _selectedForm;
  late String _frequency;
  late List<int> _selectedDays;
  late List<TimeOfDay> _reminderTimes;
  late bool _reminderEnabled;
  late List<int> _reminderOffsets;
  late String? _selectedJourneyStageId;
  late DateTime? _selectedEndDate;
  bool _submitting = false;

  final List<String> units = ['mg', 'ml', 'g', 'µg', 'UI'];
  final List<String> forms = ['injection', 'comprimé', 'patch', 'ovule'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialMedication?.name ?? '',
    );
    _dosageController = TextEditingController(
      text: widget.initialMedication?.dosage ?? '',
    );
    _selectedUnit = widget.initialMedication?.unit ?? 'mg';
    _selectedForm = widget.initialMedication?.form ?? 'injection';
    _frequency = widget.initialSchedule?.frequency ?? 'daily';
    _selectedDays = List.from(widget.initialSchedule?.daysOfWeek ?? []);
    _reminderTimes = widget.initialSchedule != null
        ? (widget.initialSchedule!.reminderTimes
            .map((t) {
              final parts = t.split(':');
              return TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            })
            .toList())
        : [const TimeOfDay(hour: 20, minute: 0)];
    _reminderEnabled = widget.initialSchedule?.notifyUser1 ?? true;
    _reminderOffsets = List.from(widget.initialSchedule?.reminderOffsets ?? [15]);
    _selectedJourneyStageId = widget.initialSchedule?.journeyStageId;
    _selectedEndDate = widget.initialSchedule?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  String _getFormLabel(String form) {
    switch (form) {
      case 'injection':
        return 'Injection';
      case 'comprimé':
        return 'Comprimé';
      case 'patch':
        return 'Patch';
      case 'ovule':
        return 'Ovule';
      default:
        return form;
    }
  }

  /// A stage's own name if it was renamed, otherwise its category label.
  /// Stages are matched by this name in lists, not by category - the type
  /// stays as an underlying grouping, but two stages of the same type (e.g.
  /// two "Ponction" cycles) are distinguished by their own name/date.
  String _stageLabel(JourneyStage stage) {
    final custom = stage.customName;
    if (custom != null && custom.trim().isNotEmpty) return custom.trim();
    return getPhaseLabel(stage.type);
  }

  Color _getFormColor(String form) {
    switch (form) {
      case 'injection':
        return AppColors.sage;
      case 'comprimé':
        return AppColors.clay;
      case 'patch':
        return const Color(0xFFE8C5B3);
      case 'ovule':
        return const Color(0xFFD4A5A5);
      default:
        return AppColors.sage;
    }
  }

  void _addReminderTime() {
    setState(() {
      _reminderTimes.add(const TimeOfDay(hour: 20, minute: 0));
    });
  }

  void _removeReminderTime(int index) {
    if (_reminderTimes.length > 1) {
      setState(() {
        _reminderTimes.removeAt(index);
      });
    }
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );
    if (picked != null) {
      setState(() {
        _reminderTimes[index] = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_nameController.text.isEmpty || _dosageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final effectiveStartDate = widget.initialSchedule?.startDate ??
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (_selectedEndDate != null && _selectedEndDate!.isBefore(effectiveStartDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit être après la date de début'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final now = DateTime.now();
      final medication = Medication(
        id: widget.initialMedication?.id ?? DateTime.now().toString(),
        coupleId: widget.initialMedication?.coupleId ?? '',
        name: _nameController.text,
        dosage: _dosageController.text,
        unit: _selectedUnit,
        form: _selectedForm,
        forPartner: widget.initialMedication?.forPartner ?? 'both',
        active: widget.initialMedication?.active ?? true,
        createdAt: widget.initialMedication?.createdAt ?? now,
        updatedAt: now,
      );

      // Create start date at midnight (00:00:00) to ensure proper filtering
      final todayAtMidnight = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      final schedule = MedicationSchedule(
        id: widget.initialSchedule?.id ?? DateTime.now().toString(),
        medicationId: medication.id,
        coupleId: widget.initialMedication?.coupleId ?? '',
        journeyStageId: _selectedJourneyStageId,
        frequency: _frequency,
        daysOfWeek: _frequency == 'specific_days' ? _selectedDays : null,
        reminderTimes: _reminderTimes
            .map((t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
            .toList(),
        reminderOffsets: _reminderOffsets,
        notifyUser1: _reminderEnabled,
        notifyUser2: _reminderEnabled,
        startDate: widget.initialSchedule?.startDate ?? todayAtMidnight,
        endDate: _selectedEndDate,
        createdAt: widget.initialSchedule?.createdAt ?? now,
        updatedAt: now,
      );

      await widget.onSubmit(medication, schedule);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Medication name
        Text(
          'NOM DU MÉDICAMENT',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.inkTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Gonal-F',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Dosage and unit
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DOSE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.inkTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dosageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '225',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNITÉ',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.inkTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedUnit = value ?? 'mg');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Form selector
        Text(
          'FORME',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.inkTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: forms.map((form) {
            final isSelected = _selectedForm == form;
            final color = _getFormColor(form);
            return GestureDetector(
              onTap: () {
                setState(() => _selectedForm = form);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  border: Border.all(
                    color: color,
                    width: isSelected ? 0 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getFormLabel(form),
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Journey stage tag (informational only - doesn't affect when this
        // medication shows up in the agenda, that's governed by the dates
        // below)
        Text(
          'ÉTAPE DU PARCOURS (INFORMATIF)',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.inkTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, child) {
            final stagesAsync = ref.watch(stagesProvider);
            return stagesAsync.when(
              data: (stages) {
                return DropdownButtonFormField<String?>(
                  value: _selectedJourneyStageId,
                  decoration: InputDecoration(
                    hintText: 'Aucune étape',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: (() {
                    // Show every stage, including completed ones - hiding
                    // them entirely turned out to remove a real capability
                    // (tagging a medication with a phase that's already
                    // over is sometimes intentional). Completed phases are
                    // instead clearly marked "(Terminé)" so a selection is
                    // a conscious choice, not an accident.

                    // Show every stage by its own name, not grouped/deduped
                    // by category - a couple can have several stages of the
                    // same type (e.g. two "Ponction" cycles), each renamed
                    // differently. When two stages share the exact same
                    // name, append the start date so the user can still
                    // tell them apart.
                    final labelCounts = <String, int>{};
                    for (final stage in stages) {
                      final label = _stageLabel(stage);
                      labelCounts[label] = (labelCounts[label] ?? 0) + 1;
                    }
                    final items = <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Aucune étape (optionnel)'),
                      ),
                    ];
                    items.addAll(stages.map((stage) {
                      final baseLabel = _stageLabel(stage);
                      final isDuplicate = (labelCounts[baseLabel] ?? 0) > 1;
                      final date = stage.startDate;
                      var label = isDuplicate
                          ? '$baseLabel (${date.day}/${date.month}/${date.year})'
                          : baseLabel;
                      if (stage.status == 'done') {
                        label = '$label (Terminé)';
                      }
                      return DropdownMenuItem<String?>(
                        value: stage.id,
                        child: Text(
                          label,
                          style: stage.status == 'done'
                              ? TextStyle(color: AppColors.inkTertiary)
                              : null,
                        ),
                      );
                    }));
                    return items;
                  })(),
                  onChanged: (value) {
                    setState(() {
                      _selectedJourneyStageId = value;
                      // Convenience default only, not a lasting link: picking
                      // a stage suggests stopping the treatment when that
                      // stage ends, but the date stays freely editable below
                      // right after - e.g. if treatment gets extended past
                      // what the stage originally planned, or the couple
                      // moves on to a different stage than expected.
                      if (value != null) {
                        final stage = stages.where((s) => s.id == value).toList();
                        if (stage.isNotEmpty) {
                          _selectedEndDate = stage.first.endDate;
                        }
                      }
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Text(
                'Erreur lors du chargement des étapes',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.ink,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // End date - what actually governs when this medication stops
        // showing up in the agenda. Leave empty for an ongoing treatment;
        // set/adjust it any time (e.g. after a doctor's visit).
        Row(
          children: [
            Text(
              'DATE DE FIN (OPTIONNELLE)',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.inkTertiary,
                letterSpacing: 0.5,
              ),
            ),
            if (_selectedEndDate != null) ...[
              const SizedBox(width: 8),
              CycleDayBadge(date: _selectedEndDate!, compact: true),
            ],
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedEndDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (picked != null) {
              setState(() => _selectedEndDate = picked);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                      : 'Traitement en cours (sans date de fin)',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _selectedEndDate != null
                        ? AppColors.ink
                        : AppColors.inkTertiary,
                  ),
                ),
                Row(
                  children: [
                    if (_selectedEndDate != null)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedEndDate = null),
                        child: const Icon(Icons.close,
                            size: 18, color: AppColors.inkTertiary),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Recurrence
        Text(
          'RÉCURRENCE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.inkTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _frequency = 'daily');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _frequency == 'daily' ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: AppColors.border1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Tous les jours',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _frequency = 'specific_days');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _frequency == 'specific_days'
                        ? Colors.white
                        : Colors.transparent,
                    border: Border.all(
                      color: AppColors.border1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Jours précis',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Reminder times
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: List.generate(_reminderTimes.length, (index) {
                final time = _reminderTimes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _selectTime(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sageBgLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.sage,
                            ),
                          ),
                        ),
                      ),
                      if (index == 0) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _addReminderTime,
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                size: 16,
                                color: AppColors.inkTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ajouter une heure',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.inkTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => _removeReminderTime(index),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Reminder toggle + lead times
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rappel',
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          ReminderOffsetsLabel(offsets: _reminderOffsets),
                        ],
                      ),
                      Switch(
                        value: _reminderEnabled,
                        onChanged: (value) {
                          setState(() => _reminderEnabled = value);
                        },
                        activeThumbColor: AppColors.sage,
                      ),
                    ],
                  ),
                  if (_reminderEnabled) ...[
                    const SizedBox(height: 12),
                    ReminderOffsetsPicker(
                      selected: _reminderOffsets,
                      onChanged: (offsets) =>
                          setState(() => _reminderOffsets = offsets),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sage,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.buttonLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
