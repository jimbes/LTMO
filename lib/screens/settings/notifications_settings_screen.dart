import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/notification_preference.dart';
import '../../providers/notification_preference_provider.dart';

const _kMedicationType = 'medication_reminder';
const _kAppointmentType = 'appointment_reminder';
const _kJourneyType = 'journey_stage_reminder';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  bool _medicationReminders = true;
  bool _appointmentReminders = true;
  bool _journeyStageReminders = true;
  String _medicationChannel = 'push';
  String _appointmentChannel = 'both';
  String _journeyChannel = 'push';
  bool _seeded = false;
  bool _saving = false;

  // null = unknown/checking, true = exempted (reliable), false = not
  // exempted (OEM battery management can kill scheduled reminders).
  bool? _batteryExempted;

  @override
  void initState() {
    super.initState();
    _refreshBatteryStatus();
  }

  Future<void> _refreshBatteryStatus() async {
    if (kIsWeb) return;
    try {
      final granted = await Permission.ignoreBatteryOptimizations.isGranted;
      if (mounted) setState(() => _batteryExempted = granted);
    } catch (_) {
      // Not supported on this platform (iOS has no such concept) - leave
      // the card hidden rather than showing a confusing unknown state.
    }
  }

  Future<void> _requestBatteryExemption() async {
    await Permission.ignoreBatteryOptimizations.request();
    await _refreshBatteryStatus();
  }

  void _seedFromPreferences(List<NotificationPreference> prefs) {
    if (_seeded) return;
    for (final pref in prefs) {
      switch (pref.type) {
        case _kMedicationType:
          _medicationReminders = pref.enabled;
          _medicationChannel = pref.channel;
          break;
        case _kAppointmentType:
          _appointmentReminders = pref.enabled;
          _appointmentChannel = pref.channel;
          break;
        case _kJourneyType:
          _journeyStageReminders = pref.enabled;
          _journeyChannel = pref.channel;
          break;
      }
    }
    _seeded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final notifier = ref.read(notifPrefProvider.notifier);
    final now = DateTime.now();

    try {
      await notifier.addPreference(NotificationPreference(
        id: '',
        userId: '',
        type: _kMedicationType,
        channel: _medicationChannel,
        enabled: _medicationReminders,
        reminderMinutesBefore: 15,
        createdAt: now,
        updatedAt: now,
      ));
      await notifier.addPreference(NotificationPreference(
        id: '',
        userId: '',
        type: _kAppointmentType,
        channel: _appointmentChannel,
        enabled: _appointmentReminders,
        reminderMinutesBefore: 60,
        createdAt: now,
        updatedAt: now,
      ));
      await notifier.addPreference(NotificationPreference(
        id: '',
        userId: '',
        type: _kJourneyType,
        channel: _journeyChannel,
        enabled: _journeyStageReminders,
        reminderMinutesBefore: 15,
        createdAt: now,
        updatedAt: now,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres de notification mis à jour'),
          ),
        );
      }
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
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rappels & notifications'),
        elevation: 0,
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
        data: (prefs) {
          _seedFromPreferences(prefs);
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_batteryExempted == false) ...[
                    _BatteryOptimizationCard(onFix: _requestBatteryExemption),
                    const SizedBox(height: 24),
                  ],

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
                  Text('Rappels étapes du parcours',
                      style: AppTypography.titleMedium),
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
                          : const Text(
                              'Enregistrer',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shown when the OS reports the app is subject to battery optimization -
/// on Samsung/Xiaomi/etc. this is the main reason scheduled local reminders
/// silently stop firing, even with notification + exact-alarm permissions
/// granted.
class _BatteryOptimizationCard extends StatelessWidget {
  final VoidCallback onFix;

  const _BatteryOptimizationCard({required this.onFix});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sageBgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fiabilité des rappels', style: AppTypography.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Votre téléphone peut arrêter les rappels programmés en '
            'arrière-plan pour économiser la batterie. Autorisez LTMO à '
            'fonctionner en arrière-plan pour ne rater aucun rappel.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.inkTertiary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onFix,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.sage,
                side: const BorderSide(color: AppColors.sage),
              ),
              child: const Text('Autoriser'),
            ),
          ),
        ],
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
