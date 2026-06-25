import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _medicationReminders = true;
  bool _appointmentReminders = true;
  bool _journeyStageReminders = true;
  String _medicationChannel = 'push';
  String _appointmentChannel = 'both';
  String _journeyChannel = 'push';
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 8, minute: 0);
  bool _quietHoursEnabled = false;

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietStart : _quietEnd,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietStart = picked;
        } else {
          _quietEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rappels & notifications'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication reminders section
              Text('Rappels médicaments', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              _NotificationCard(
                title: 'Activer les rappels',
                enabled: _medicationReminders,
                onChanged: (value) {
                  setState(() => _medicationReminders = value);
                },
              ),
              const SizedBox(height: 12),
              _ChannelSelector(
                label: 'Canal de notification',
                value: _medicationChannel,
                onChanged: (value) {
                  setState(() => _medicationChannel = value);
                },
              ),
              const SizedBox(height: 24),

              // Appointment reminders section
              Text('Rappels rendez-vous', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              _NotificationCard(
                title: 'Activer les rappels',
                enabled: _appointmentReminders,
                onChanged: (value) {
                  setState(() => _appointmentReminders = value);
                },
              ),
              const SizedBox(height: 12),
              _ChannelSelector(
                label: 'Canal de notification',
                value: _appointmentChannel,
                onChanged: (value) {
                  setState(() => _appointmentChannel = value);
                },
              ),
              const SizedBox(height: 24),

              // Journey stage reminders section
              Text('Rappels étapes du parcours', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              _NotificationCard(
                title: 'Activer les rappels',
                enabled: _journeyStageReminders,
                onChanged: (value) {
                  setState(() => _journeyStageReminders = value);
                },
              ),
              const SizedBox(height: 12),
              _ChannelSelector(
                label: 'Canal de notification',
                value: _journeyChannel,
                onChanged: (value) {
                  setState(() => _journeyChannel = value);
                },
              ),
              const SizedBox(height: 32),

              // Quiet hours section
              Text('Ne pas déranger', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
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
                        Text(
                          'Activer les heures sans notification',
                          style: AppTypography.bodyMedium,
                        ),
                        Switch(
                          value: _quietHoursEnabled,
                          onChanged: (value) {
                            setState(() => _quietHoursEnabled = value);
                          },
                          activeColor: AppColors.sage,
                        ),
                      ],
                    ),
                    if (_quietHoursEnabled) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('De', style: AppTypography.labelSmall),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _selectTime(true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.border1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_quietStart.hour.toString().padLeft(2, '0')}:${_quietStart.minute.toString().padLeft(2, '0')}',
                                      style: AppTypography.bodySmall,
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
                                Text('À', style: AppTypography.labelSmall),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _selectTime(false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.border1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_quietEnd.hour.toString().padLeft(2, '0')}:${_quietEnd.minute.toString().padLeft(2, '0')}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paramètres de notification mis à jour'),
                      ),
                    );
                  },
                  child: const Text(
                    'Enregistrer',
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

class _NotificationCard extends StatelessWidget {
  final String title;
  final bool enabled;
  final Function(bool) onChanged;

  const _NotificationCard({
    required this.title,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.bodyMedium),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: AppColors.sage,
          ),
        ],
      ),
    );
  }
}

class _ChannelSelector extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;

  const _ChannelSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['push', 'email', 'both'].map((channel) {
            final isSelected = value == channel;
            final label = channel == 'push'
                ? 'Notification'
                : channel == 'email'
                    ? 'Email'
                    : 'Les deux';
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(channel);
              },
              selectedColor: AppColors.sage,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.ink,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
