import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/auth_provider.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _emailController;
  late DateTime _birthDate;
  String _language = 'fr';
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    try {
      if (!_initialized) return;

      final user = ref.read(userProvider).value;
      if (user == null) return;

      // Create updated user data
      final updatedUser = user.copyWith(
        name: _firstNameController.text,
        email: _emailController.text,
      );

      // Call auth provider to update user
      await ref.read(userProvider.notifier).updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${_extractErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(userProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  String _extractErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['errors'] is Map) {
          final errors = (data['errors'] as Map).values.expand((v) => v is List ? v : [v]);
          if (errors.isNotEmpty) return errors.join(', ');
        }
        if (data['message'] != null) return data['message'].toString();
      }
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return user.when(
      data: (userData) {
        // Initialize controllers on first build with real user data
        if (!_initialized && userData != null) {
          _firstNameController = TextEditingController(text: userData.name ?? '');
          _emailController = TextEditingController(text: userData.email ?? '');
          _birthDate = DateTime.now();
          _initialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Infos personnelles'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar section
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.sageBgLight,
                          child: const Icon(Icons.person, size: 48, color: AppColors.sage),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sélectionner une photo')),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Changer la photo'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Personal info section
                  Text('Informations personnelles', style: AppTypography.titleMedium),
                  const SizedBox(height: 16),

                  // First name field
                  Text('Prénom', style: AppTypography.labelMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      hintText: 'Votre prénom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email field
                  Text('Email', style: AppTypography.labelMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'votre@email.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Birth date picker
                  Text('Date de naissance', style: AppTypography.labelMedium),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectBirthDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
                            style: AppTypography.bodyMedium,
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Preferences section
                  Text('Préférences', style: AppTypography.titleMedium),
                  const SizedBox(height: 16),

                  // Language selector
                  Text('Langue', style: AppTypography.labelMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _language,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                      DropdownMenuItem(value: 'es', child: Text('Español')),
                    ],
                    onChanged: (value) {
                      setState(() => _language = value ?? 'fr');
                    },
                  ),
                  const SizedBox(height: 32),

                  // Security section
                  Text('Sécurité', style: AppTypography.titleMedium),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.sageBgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mot de passe',
                          style: AppTypography.labelMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Écran de changement de mot de passe'),
                                ),
                              );
                            },
                            child: const Text('Changer le mot de passe'),
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
                      onPressed: _saveProfile,
                      child: const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Infos personnelles')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Infos personnelles')),
        body: const Center(child: Text('Erreur de chargement')),
      ),
    );
  }
}
