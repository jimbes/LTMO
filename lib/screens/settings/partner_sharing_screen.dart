import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class PartnerSharingScreen extends StatefulWidget {
  const PartnerSharingScreen({super.key});

  @override
  State<PartnerSharingScreen> createState() => _PartnerSharingScreenState();
}

class _PartnerSharingScreenState extends State<PartnerSharingScreen> {
  bool _shareAppointments = true;
  bool _shareMedications = true;
  bool _shareJourneyStages = true;
  bool _shareNotes = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partage avec le partenaire'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Partner info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sageBgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border1),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.sage,
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tom', style: AppTypography.titleMedium),
                          Text(
                            'Partenaire lié',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Partenaire dissocié')),
                        );
                      },
                      child: const Text('Dissocier'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Sharing options
              Text('Que partager ?', style: AppTypography.titleMedium),
              const SizedBox(height: 16),

              // Appointments toggle
              _ShareToggleTile(
                title: 'Rendez-vous médicaux',
                subtitle: 'Partager tous les rendez-vous',
                value: _shareAppointments,
                onChanged: (value) {
                  setState(() => _shareAppointments = value);
                },
                icon: Icons.event_outlined,
              ),
              const SizedBox(height: 12),

              // Medications toggle
              _ShareToggleTile(
                title: 'Médicaments',
                subtitle: 'Partager les médicaments et horaires de prise',
                value: _shareMedications,
                onChanged: (value) {
                  setState(() => _shareMedications = value);
                },
                icon: Icons.medication_outlined,
              ),
              const SizedBox(height: 12),

              // Journey stages toggle
              _ShareToggleTile(
                title: 'Étapes du parcours FIV',
                subtitle: 'Partager la progression du traitement',
                value: _shareJourneyStages,
                onChanged: (value) {
                  setState(() => _shareJourneyStages = value);
                },
                icon: Icons.trending_up_outlined,
              ),
              const SizedBox(height: 12),

              // Notes toggle
              _ShareToggleTile(
                title: 'Notes et observations',
                subtitle: 'Partager les notes personnelles',
                value: _shareNotes,
                onChanged: (value) {
                  setState(() => _shareNotes = value);
                },
                icon: Icons.sticky_note_2_outlined,
              ),
              const SizedBox(height: 32),

              // Info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outlined,
                            color: AppColors.clay, size: 20),
                        const SizedBox(width: 8),
                        Text('À savoir', style: AppTypography.labelMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les modifications apportées par l\'un des partenaires sont visibles en temps réel à l\'autre partenaire.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
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
                        content: Text('Paramètres de partage mis à jour'),
                      ),
                    );
                  },
                  child: const Text(
                    'Enregistrer les paramètres',
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

class _ShareToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final IconData icon;

  const _ShareToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.sageBgLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.sage, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.sage,
          ),
        ],
      ),
    );
  }
}
