import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/journey_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/phase_labels.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _stageShortLabel(dynamic stage) {
    final custom = stage.customName as String?;
    if (custom != null && custom.trim().isNotEmpty) return custom.trim();
    return getPhaseShort(stage.type as String);
  }

  Color _getPhaseColor(String? status) {
    if (status == 'done') return AppColors.sage;
    if (status == 'in_progress') return AppColors.clay;
    return AppColors.border1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = ref.watch(stagesProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Couple header with gradient background
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatars with overlap
                  user.when(
                    data: (userData) {
                      final userFirstLetter =
                          userData?.name?.isNotEmpty == true
                              ? userData!.name![0].toUpperCase()
                              : '?';

                      return SizedBox(
                        width: 130,
                        height: 64,
                        child: Stack(
                          children: [
                            // First avatar (user)
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.sage,
                              ),
                              child: Center(
                                child: Text(
                                  userFirstLetter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Second avatar (partner or heart)
                            Positioned(
                              left: 40,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.clay,
                                  border: Border.all(
                                    color: AppColors.cream,
                                    width: 3,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '❤️',
                                    style: TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sage,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, __) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sage,
                      ),
                      child: const Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  user.when(
                    data: (userData) => Text(
                      userData?.name ?? 'Léa & Tom',
                      style: AppTypography.titleLarge,
                    ),
                    loading: () => Text(
                      'Chargement...',
                      style: AppTypography.titleLarge,
                    ),
                    error: (_, __) => Text(
                      'Léa & Tom',
                      style: AppTypography.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Parcours commencé en mars 2026',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Journey info card
                  stages.when(
                    data: (stageList) {
                      try {
                        dynamic inProgressPhase;
                        try {
                          inProgressPhase = stageList
                              .firstWhere((s) => s.status == 'in_progress');
                        } catch (e) {
                          inProgressPhase = null;
                        }

                        final statusLabel = inProgressPhase != null
                            ? 'En cours'
                            : 'À venir';

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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tentative ${stageList.length > 0 ? stageList.length : 1}',
                                      style: AppTypography.bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.sage.withAlpha(30),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.sage,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Horizontal timeline - built from the couple's
                            // actual configured steps (any count, renamed or
                            // not), not a fixed default list of 5.
                            SizedBox(
                              height: 80,
                              child: stageList.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Aucune étape configurée',
                                        style: AppTypography.bodySmall
                                            .copyWith(
                                          color: AppColors.inkTertiary,
                                        ),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: List.generate(
                                            stageList.length * 2 - 1, (index) {
                                          if (index.isEven) {
                                            final stage =
                                                stageList[index ~/ 2];
                                            final color =
                                                _getPhaseColor(stage.status);

                                            return SizedBox(
                                              width: 64,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          color.withAlpha(30),
                                                      border: Border.all(
                                                        color: color,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: stage.status ==
                                                            'done'
                                                        ? Icon(
                                                            Icons.check,
                                                            color: color,
                                                            size: 18,
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _stageShortLabel(stage),
                                                    textAlign:
                                                        TextAlign.center,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                      fontSize: 10,
                                                      color: AppColors
                                                          .inkTertiary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else {
                                            return SizedBox(
                                              width: 20,
                                              child: Center(
                                                child: Container(
                                                  height: 2,
                                                  color: AppColors.border1,
                                                ),
                                              ),
                                            );
                                          }
                                        }),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                        } catch (e) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border1),
                            ),
                            child: Text('Erreur: $e'),
                          );
                        }
                      },
                    loading: () => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border1),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border1),
                      ),
                      child: Text('Erreur: $error'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Navigation tiles - list layout
                  Column(
                    spacing: 12,
                    children: [
                      _ActionTile(
                        icon: Icons.edit,
                        label: 'Mes traitements',
                        onTap: () => context.push('/traitements'),
                      ),
                      _ActionTile(
                        icon: Icons.event_note,
                        label: 'Mes rendez-vous',
                        onTap: () => context.push('/appointments/all'),
                      ),
                      _ActionTile(
                        icon: Icons.notifications_outlined,
                        label: 'Rappels & notifications',
                        onTap: () => context.push('/notifications-settings'),
                      ),
                      _ActionTile(
                        icon: Icons.share,
                        label: 'Partage avec le partenaire',
                        onTap: () => context.push('/partner-sharing'),
                      ),
                      _ActionTile(
                        icon: Icons.map,
                        label: 'Configuration du parcours',
                        onTap: () => context.push('/journey/configure'),
                      ),
                      _ActionTile(
                        icon: Icons.person,
                        label: 'Infos personnelles',
                        onTap: () => context.push('/profile/edit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sageBgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.sage, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }
}
