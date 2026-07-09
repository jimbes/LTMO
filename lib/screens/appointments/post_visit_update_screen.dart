import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/journey_provider.dart';
import '../../models/appointment.dart';
import '../../utils/phase_labels.dart';
import '../../widgets/appointment_form.dart' show appointmentTypeLabels;

/// Shown right after marking a doctor's-visit appointment complete. Doses
/// and next steps in a real IVF protocol get decided at each visit, not
/// planned upfront - this captures what changed in one place instead of
/// making the user hunt through separate screens for "add appointment",
/// "edit each medication", and "update my phase".
class PostVisitUpdateScreen extends ConsumerStatefulWidget {
  const PostVisitUpdateScreen({super.key});

  @override
  ConsumerState<PostVisitUpdateScreen> createState() =>
      _PostVisitUpdateScreenState();
}

class _PostVisitUpdateScreenState extends ConsumerState<PostVisitUpdateScreen> {
  int _step = 0;

  // Step 1 - next appointment
  bool _knowsNextDate = false;
  DateTime _nextDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay? _nextTime;
  String _nextType = 'consult';
  final _nextTitleController = TextEditingController();
  bool _savingNext = false;

  @override
  void dispose() {
    _nextTitleController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      context.pop();
    }
  }

  Future<void> _submitNextAppointment() async {
    if (!_knowsNextDate) {
      _nextStep();
      return;
    }

    setState(() => _savingNext = true);
    try {
      final now = DateTime.now();
      DateTime? appointmentTime;
      if (_nextTime != null) {
        appointmentTime = DateTime(_nextDate.year, _nextDate.month,
            _nextDate.day, _nextTime!.hour, _nextTime!.minute);
      }

      final title = _nextTitleController.text.trim().isNotEmpty
          ? _nextTitleController.text.trim()
          : appointmentTypeLabels[_nextType]!;

      final appointment = Appointment(
        id: now.toString(),
        coupleId: '',
        title: title,
        appointmentDate:
            DateTime(_nextDate.year, _nextDate.month, _nextDate.day),
        appointmentTime: appointmentTime,
        type: _nextType,
        notifyUser1: true,
        notifyUser2: true,
        completed: false,
        reminderOffsets: const [60],
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(appointmentProvider.notifier).addAppointment(appointment);

      if (mounted) _nextStep();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNext = false);
    }
  }

  Future<void> _pickNextDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _nextDate = picked);
  }

  Future<void> _pickNextTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _nextTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _nextTime = picked);
  }

  Future<void> _extendSchedule(dynamic schedule, DateTime newEndDate) async {
    try {
      await ref
          .read(medicationProvider.notifier)
          .updateSchedule(schedule.copyWith(endDate: newEndDate));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _pickExtendDate(dynamic schedule) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) await _extendSchedule(schedule, picked);
  }

  Future<void> _setCurrentStage(String stageId) async {
    try {
      await ref.read(journeyProvider.notifier).setCurrentStage(stageId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Après le rendez-vous',
                    style: AppTypography.headline2,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= _step ? AppColors.sage : AppColors.border1,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: switch (_step) {
                  0 => _buildNextAppointmentStep(),
                  1 => _buildMedicationsStep(),
                  _ => _buildPhaseStep(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextAppointmentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prochain rendez-vous', style: AppTypography.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Si la date est déjà connue, ajoutez-la maintenant.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Je connais déjà la date'),
          value: _knowsNextDate,
          activeThumbColor: AppColors.sage,
          onChanged: (v) => setState(() => _knowsNextDate = v),
        ),
        if (_knowsNextDate) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: appointmentTypeLabels.entries.map((e) {
              final isSelected = _nextType == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: isSelected,
                onSelected: (_) => setState(() => _nextType = e.key),
                selectedColor: AppColors.sage,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.ink,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nextTitleController,
            decoration: InputDecoration(
              hintText: appointmentTypeLabels[_nextType],
              labelText: 'Titre (optionnel)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickNextDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    '${_nextDate.day}/${_nextDate.month}/${_nextDate.year}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickNextTime,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(
                    _nextTime != null ? _nextTime!.format(context) : 'Heure',
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sage,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _savingNext ? null : _submitNextAppointment,
            child: _savingNext
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _knowsNextDate ? 'Enregistrer et continuer' : 'Passer',
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationsStep() {
    final medicationsAsync = ref.watch(medicationsProvider);
    final schedulesAsync = ref.watch(schedulesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Médicaments à prendre', style: AppTypography.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Prolongez un traitement en cours, arrêtez-le, ou ajoutez-en un nouveau.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: 20),
        medicationsAsync.when(
          data: (medications) {
            return schedulesAsync.when(
              data: (schedules) {
                final medMap = {for (final m in medications) m.id: m};
                final today = DateTime.now();
                final todayOnly = DateTime(today.year, today.month, today.day);
                final active = schedules.where((s) {
                  final end = s.endDate;
                  return end == null ||
                      !DateTime(end.year, end.month, end.day)
                          .isBefore(todayOnly);
                }).toList();

                if (active.isEmpty) {
                  return Text(
                    'Aucun traitement en cours.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.inkTertiary),
                  );
                }

                return Column(
                  children: active.map((schedule) {
                    final med = medMap[schedule.medicationId];
                    if (med == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.name, style: AppTypography.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            '${med.dosage} ${med.unit}'
                            '${schedule.endDate != null ? " · jusqu'au ${schedule.endDate!.day}/${schedule.endDate!.month}/${schedule.endDate!.year}" : ' · en cours'}',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.inkTertiary),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _pickExtendDate(schedule),
                                  child: const Text('Prolonger'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  onPressed: () =>
                                      _extendSchedule(schedule, todayOnly),
                                  child: const Text('Arrêter aujourd\'hui'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Erreur: $e'),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Erreur: $e'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/medications/add'),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un médicament'),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sage,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _nextStep,
            child:
                const Text('Continuer', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseStep() {
    final stagesAsync = ref.watch(stagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Étape actuelle du parcours', style: AppTypography.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Avez-vous changé de phase ? C\'est juste une étiquette informative.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: 20),
        stagesAsync.when(
          data: (stages) {
            if (stages.isEmpty) {
              return Text(
                'Aucune étape configurée.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.inkTertiary),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stages.map((stage) {
                final label = (stage.customName?.trim().isNotEmpty ?? false)
                    ? stage.customName!.trim()
                    : getPhaseLabel(stage.type);
                final isCurrent = stage.status == 'in_progress';
                return ChoiceChip(
                  label: Text(label),
                  selected: isCurrent,
                  onSelected: (_) => _setCurrentStage(stage.id),
                  selectedColor: AppColors.sage,
                  labelStyle: TextStyle(
                    color: isCurrent ? Colors.white : AppColors.ink,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Erreur: $e'),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sage,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => context.pop(),
            child:
                const Text('Terminer', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
