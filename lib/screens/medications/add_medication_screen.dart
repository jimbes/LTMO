import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/medication.dart';
import '../../models/medication_schedule.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/medication_provider.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  String _selectedUnit = 'mg';
  String _selectedForm = 'injection';
  String _frequency = 'daily';
  final List<int> _selectedDays = [];
  final List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 9, minute: 0)];

  final List<String> units = ['mg', 'ml', 'g', 'µg', 'UI'];
  final List<String> forms = ['injection', 'comprimé', 'patch', 'ovule'];
  final List<String> daysLabel = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  void _addReminderTime() {
    setState(() {
      _reminderTimes.add(const TimeOfDay(hour: 9, minute: 0));
    });
  }

  void _removeReminderTime(int index) {
    setState(() {
      _reminderTimes.removeAt(index);
    });
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

  void _saveMedication() {
    if (_nameController.text.isEmpty || _dosageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final now = DateTime.now();
    final medication = Medication(
      id: DateTime.now().toString(),
      coupleId: '1',
      name: _nameController.text,
      dosage: _dosageController.text,
      unit: _selectedUnit,
      form: _selectedForm,
      forPartner: 'both',
      active: true,
      createdAt: now,
      updatedAt: now,
    );

    final schedule = MedicationSchedule(
      id: DateTime.now().toString(),
      medicationId: medication.id,
      coupleId: '1',
      frequency: _frequency,
      daysOfWeek: _frequency == 'specific_days' ? _selectedDays : null,
      reminderTimes: _reminderTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList(),
      reminderOffsetHours: 0,
      notifyUser1: true,
      notifyUser2: true,
      startDate: DateTime.now(),
      endDate: null,
      createdAt: now,
      updatedAt: now,
    );

    ref.read(medicationProvider.notifier).addMedication(medication);
    ref.read(medicationProvider.notifier).addSchedule(schedule);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Médicament ajouté avec succès')),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un médicament'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              Text('Nom du médicament', style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ex: Gonal-F',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                        Text('Dosage', style: AppTypography.labelMedium),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _dosageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '75',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Unité', style: AppTypography.labelMedium),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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
              Text('Forme', style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: forms.map((form) {
                  final isSelected = _selectedForm == form;
                  return FilterChip(
                    label: Text(form),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedForm = form);
                    },
                    selectedColor: AppColors.sage,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.ink,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Frequency selector
              Text('Fréquence', style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['daily', 'specific_days'].map((freq) {
                  final isSelected = _frequency == freq;
                  return FilterChip(
                    label: Text(freq == 'daily' ? 'Tous les jours' : 'Jours spécifiques'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _frequency = freq);
                    },
                    selectedColor: AppColors.clay,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.ink,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Days of week selector
              if (_frequency == 'specific_days')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sélectionner les jours', style: AppTypography.labelSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: List.generate(7, (index) {
                        final isSelected = _selectedDays.contains(index);
                        return ChoiceChip(
                          label: Text(daysLabel[index]),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(index);
                              } else {
                                _selectedDays.remove(index);
                              }
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),

              // Reminder times
              Text('Heures de prise', style: AppTypography.labelMedium),
              const SizedBox(height: 12),
              Column(
                children: List.generate(_reminderTimes.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_reminderTimes[index].hour.toString().padLeft(2, '0')}:${_reminderTimes[index].minute.toString().padLeft(2, '0')}',
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_reminderTimes.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeReminderTime(index),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _addReminderTime,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une heure'),
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
                  onPressed: _saveMedication,
                  child: const Text(
                    'Ajouter le médicament',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
