import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/practitioner_provider.dart';

class PractitionersScreen extends ConsumerWidget {
  const PractitionersScreen({super.key});

  void _showContactOption(BuildContext context, String phone, String email) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phone.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Appeler'),
                subtitle: Text(phone),
                onTap: () => Navigator.pop(context),
              ),
            if (email.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Envoyer un email'),
                subtitle: Text(email),
                onTap: () => Navigator.pop(context),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddPractitionerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddPractitionerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practitioners = ref.watch(practitionersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes praticiens et cliniques'),
        elevation: 0,
      ),
      body: practitioners.when(
        data: (practitionerList) {
          if (practitionerList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline,
                      size: 64, color: AppColors.inkTertiary),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun praticien enregistré',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sage,
                    ),
                    onPressed: () =>
                        _showAddPractitionerSheet(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un praticien'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: practitionerList.length,
            itemBuilder: (context, index) {
              final practitioner = practitionerList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
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
                          CircleAvatar(
                            backgroundColor: AppColors.sageBgLight,
                            child: Icon(
                              Icons.person_outline,
                              color: AppColors.sage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  practitioner.name,
                                  style: AppTypography.titleSmall,
                                ),
                                if (practitioner.specialty != null)
                                  Text(
                                    practitioner.specialty!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.inkTertiary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (practitioner.clinicName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: AppColors.inkTertiary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  practitioner.clinicName!,
                                  style: AppTypography.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (practitioner.phone != null)
                            _ActionButton(
                              icon: Icons.phone_outlined,
                              label: 'Appeler',
                              onTap: () => _showContactOption(
                                context,
                                practitioner.phone ?? '',
                                practitioner.email ?? '',
                              ),
                            ),
                          if (practitioner.email != null)
                            _ActionButton(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              onTap: () => _showContactOption(
                                context,
                                practitioner.phone ?? '',
                                practitioner.email ?? '',
                              ),
                            ),
                          if (practitioner.address != null)
                            _ActionButton(
                              icon: Icons.location_on_outlined,
                              label: 'Localiser',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(practitioner.address!),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPractitionerSheet(context, ref),
        backgroundColor: AppColors.sage,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.sageBgLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.sage),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.sage,
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

  void _savePractitioner() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom')),
      );
      return;
    }

    // Mock save - in production would call ref.read(practitionerProvider.notifier).addPractitioner()
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Praticien ajouté')),
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
            Text('Ajouter un praticien', style: AppTypography.titleLarge),
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
                  style: TextStyle(color: Colors.white, fontSize: 16),
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
          Text(label, style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
