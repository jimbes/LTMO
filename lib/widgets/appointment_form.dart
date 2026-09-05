import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../models/journey_stage.dart';
import '../providers/journey_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/phase_labels.dart';
import 'cycle_day_badge.dart';
import 'reminder_offsets_picker.dart';

String _stageOptionLabel(JourneyStage stage) {
  final custom = stage.customName;
  if (custom != null && custom.trim().isNotEmpty) return custom.trim();
  return getPhaseLabel(stage.type);
}

typedef AppointmentFormCallback = Future<void> Function(Appointment appointment);

const List<String> appointmentTypes = [
  'echo',
  'blood_test',
  'consult',
  'ponction',
  'transfert',
];

const Map<String, String> appointmentTypeLabels = {
  'echo': 'Échographie',
  'blood_test': 'Prise de sang',
  'consult': 'Consultation',
  'ponction': 'Ponction',
  'transfert': 'Transfert',
};

class AppointmentForm extends ConsumerStatefulWidget {
  final String buttonLabel;
  final Appointment? initialAppointment;
  final AppointmentFormCallback onSubmit;
  final Future<void> Function()? onDelete;

  const AppointmentForm({
    super.key,
    required this.buttonLabel,
    required this.onSubmit,
    this.initialAppointment,
    this.onDelete,
  });

  @override
  ConsumerState<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends ConsumerState<AppointmentForm> {
  late TextEditingController _practitionerController;
  late TextEditingController _clinicController;
  late TextEditingController _notesController;

  late String _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _reminderEnabled;
  late List<int> _reminderOffsets;
  String? _selectedStageId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final apt = widget.initialAppointment;
    _practitionerController =
        TextEditingController(text: apt?.doctorName ?? '');
    _clinicController = TextEditingController(text: apt?.location ?? '');
    _notesController = TextEditingController(text: apt?.description ?? '');
    _selectedType = apt?.type ?? 'echo';
    _selectedDate = apt?.appointmentDate ?? DateTime.now();
    _selectedTime = apt?.appointmentTime != null
        ? TimeOfDay(
            hour: apt!.appointmentTime!.hour,
            minute: apt.appointmentTime!.minute,
          )
        : const TimeOfDay(hour: 9, minute: 0);
    _reminderOffsets = (apt?.reminderOffsets.isNotEmpty ?? false)
        ? List.from(apt!.reminderOffsets)
        : [60];
    _reminderEnabled = apt == null || apt.reminderOffsets.isNotEmpty;
    _selectedStageId = apt?.journeyStageId;
  }

  @override
  void dispose() {
    _practitionerController.dispose();
    _clinicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Future<void> _selectDate() async {
    // The window must include _selectedDate itself - when editing an
    // appointment older than 365 days, a fixed ±365-day-from-today range
    // would leave initialDate outside [firstDate, lastDate], so the
    // picker opens with every day disabled and taps silently do nothing.
    final defaultFirst = DateTime.now().subtract(const Duration(days: 365));
    final defaultLast = DateTime.now().add(const Duration(days: 365));
    final firstDate =
        _selectedDate.isBefore(defaultFirst) ? _selectedDate : defaultFirst;
    final lastDate =
        _selectedDate.isAfter(defaultLast) ? _selectedDate : defaultLast;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final appointmentDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final now = DateTime.now();
    final apt = widget.initialAppointment;

    final appointment = Appointment(
      id: apt?.id ?? DateTime.now().toString(),
      coupleId: apt?.coupleId ?? '',
      title: '${appointmentTypeLabels[_selectedType]} - '
          '${_practitionerController.text.isNotEmpty ? _practitionerController.text : "Rendez-vous"}',
      appointmentDate: _selectedDate,
      appointmentTime: appointmentDateTime,
      type: _selectedType,
      reminderOffsets: _reminderEnabled ? _reminderOffsets : [],
      location:
          _clinicController.text.isNotEmpty ? _clinicController.text : null,
      doctorName: _practitionerController.text.isNotEmpty
          ? _practitionerController.text
          : null,
      description:
          _notesController.text.isNotEmpty ? _notesController.text : null,
      completed: apt?.completed ?? false,
      notifyUser1: apt?.notifyUser1 ?? true,
      notifyUser2: apt?.notifyUser2 ?? true,
      createdAt: apt?.createdAt ?? now,
      updatedAt: now,
      journeyStageId: _selectedStageId,
    );

    try {
      await widget.onSubmit(appointment);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type selector
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: appointmentTypes.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedType = type);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.sage : Colors.white,
                  border: Border.all(
                    color: AppColors.sage,
                    width: isSelected ? 0 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appointmentTypeLabels[type]!,
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.sage,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Optional link to a journey stage - lets the app offer quick
        // "mark stage skipped" / "start new cycle" actions once this
        // appointment is edited/completed.
        Text(
          'ÉTAPE LIÉE (OPTIONNEL)',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.inkTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, _) {
            final stagesAsync = ref.watch(stagesProvider);
            return stagesAsync.when(
              data: (stages) {
                final validSelection = stages.any((s) => s.id == _selectedStageId)
                    ? _selectedStageId
                    : null;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: validSelection,
                      hint: const Text('Aucune'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Aucune'),
                        ),
                        ...stages.map((stage) => DropdownMenuItem<String?>(
                              value: stage.id,
                              child: Text(_stageOptionLabel(stage)),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStageId = value);
                      },
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),
        const SizedBox(height: 24),

        // Date and time row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'DATE',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.inkTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CycleDayBadge(date: _selectedDate, compact: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(_selectedDate),
                            style: AppTypography.bodySmall,
                          ),
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AppColors.inkTertiary,
                          ),
                        ],
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
                    'HEURE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.inkTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.bodySmall,
                          ),
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: AppColors.inkTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Practitioner and clinic section
        Text(
          'PRATICIEN · LIEU',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.inkTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _practitionerController,
          decoration: InputDecoration(
            hintText: 'Dr. Martin',
            hintStyle: TextStyle(color: AppColors.inkTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _clinicController,
          decoration: InputDecoration(
            hintText: 'Clinique de la Muette',
            hintStyle: TextStyle(color: AppColors.inkTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: Icon(
              Icons.location_on_outlined,
              size: 20,
              color: AppColors.inkTertiary,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Reminder section
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
                      Text('Rappel', style: AppTypography.bodyMedium),
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
        const SizedBox(height: 24),

        // Notes field
        Text(
          'NOTE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.inkTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Venir avec la vessie pleine...',
            hintStyle: TextStyle(color: AppColors.inkTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
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
            onPressed: _saving ? null : _save,
            child: _saving
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

        if (widget.onDelete != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Supprimer le rendez-vous'),
            ),
          ),
        ],
      ],
    );
  }
}
