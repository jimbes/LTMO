import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/practitioner_provider.dart';
import '../../models/practitioner.dart';

class PractitionersScreen extends ConsumerWidget {
  const PractitionersScreen({super.key});

  Color _getAvatarColor(int index) {
    return index % 2 == 0 ? AppColors.sage : AppColors.clay;
  }

  String _getFirstLetter(String name) {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _showAddPractitionerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddPractitionerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practitioners = ref.watch(practitionersProvider);

    return Scaffold(
      body: practitioners.when(
        data: (practitionerList) {
          final medicalTeam = practitionerList.where((p) => p.specialty != null).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                  color: AppColors.cream,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Praticiens & cliniques',
                        style: AppTypography.headline1,
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medical team section
                      if (medicalTeam.isNotEmpty) ...[
                        Text(
                          'ÉQUIPE MÉDICALE',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.inkTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          spacing: 12,
                          children: List.generate(medicalTeam.length, (index) {
                            final practitioner = medicalTeam[index];
                            final avatarColor = _getAvatarColor(index);

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: avatarColor,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getFirstLetter(practitioner.name),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              practitioner.name,
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              practitioner.specialty ?? 'Praticien',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: AppColors.inkTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    spacing: 8,
                                    children: [
                                      if (practitioner.phone != null)
                                        Expanded(
                                          child: _ActionButton(
                                            icon: Icons.phone_outlined,
                                            label: 'Appeler',
                                            onTap: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Tel: ${practitioner.phone}',
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      if (practitioner.email != null)
                                        Expanded(
                                          child: _ActionButton(
                                            icon: Icons.mail_outline,
                                            label: 'Écrire',
                                            backgroundColor:
                                                AppColors.clayBgLight,
                                            iconColor: AppColors.clay,
                                            onTap: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Email: ${practitioner.email}',
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Clinics section
                      if (practitionerList.any((p) => p.clinicName != null)) ...[
                        Text(
                          'LIEUX',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.inkTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          spacing: 12,
                          children: practitionerList
                              .where((p) => p.clinicName != null)
                              .map((practitioner) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: AppColors.sageBgLight,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.location_on,
                                            color: AppColors.sage,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              practitioner.clinicName ?? 'Clinique',
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (practitioner.address != null)
                                              Text(
                                                practitioner.address!,
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                  color:
                                                      AppColors.inkTertiary,
                                                ),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Directions: ${practitioner.address}',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.sageBgLight,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Itinéraire',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.sage,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: AppColors.sage,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Add contact button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sage,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () =>
                              _showAddPractitionerSheet(context, ref),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text(
                                'Ajouter un contact',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.backgroundColor = AppColors.sageBgLight,
    this.iconColor = AppColors.sage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPractitionerSheet extends ConsumerStatefulWidget {
  const _AddPractitionerSheet();

  @override
  ConsumerState<_AddPractitionerSheet> createState() =>
      _AddPractitionerSheetState();
}

class _AddPractitionerSheetState extends ConsumerState<_AddPractitionerSheet> {
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _clinicController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _clinicController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _savePractitioner() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom')),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final practitioner = Practitioner(
        id: now.toString(),
        coupleId: '',
        name: _nameController.text,
        specialty: _specialtyController.text.isNotEmpty ? _specialtyController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        clinicName: _clinicController.text.isNotEmpty ? _clinicController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(practitionerProvider.notifier).addPractitioner(practitioner);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact ajouté avec succès')),
        );
      }
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
            Text('Ajouter un contact', style: AppTypography.titleLarge),
            const SizedBox(height: 24),
            _buildField('Nom', _nameController, 'Dr. Jean Dupont'),
            _buildField('Spécialité', _specialtyController, 'Gynécologue-fertilité'),
            _buildField('Téléphone', _phoneController, '+33 1 23 45 67 89'),
            _buildField('Email', _emailController, 'dr@clinic.fr'),
            _buildField('Clinique', _clinicController, 'Clinique ABC'),
            _buildField('Adresse', _addressController, '123 Rue de Paris'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sage,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _savePractitioner,
                child: const Text(
                  'Ajouter',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.inkTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
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
        ],
      ),
    );
  }
}
