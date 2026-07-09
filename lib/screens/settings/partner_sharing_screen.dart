import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/partner_provider.dart';

class PartnerSharingScreen extends ConsumerStatefulWidget {
  const PartnerSharingScreen({super.key});

  @override
  ConsumerState<PartnerSharingScreen> createState() =>
      _PartnerSharingScreenState();
}

class _PartnerSharingScreenState extends ConsumerState<PartnerSharingScreen> {
  final _inviteEmailController = TextEditingController();
  final _joinCodeController = TextEditingController();
  bool _sendingInvite = false;
  bool _joining = false;

  @override
  void dispose() {
    _inviteEmailController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _sendingInvite = true);
    try {
      final result =
          await ref.read(partnerNotifierProvider.notifier).invitePartner(email);
      _inviteEmailController.clear();

      if (mounted) {
        final daysLeft = result.expiresAt.difference(DateTime.now()).inDays;
        final expiryLabel =
            DateFormat('d MMMM yyyy', 'fr_FR').format(result.expiresAt);

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invitation envoyée ✓'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: AppTypography.bodyMedium,
                    children: [
                      const TextSpan(text: 'Une invitation a bien été créée pour '),
                      TextSpan(
                        text: result.inviteeEmail,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result.existingUser
                      ? 'Cette personne a déjà un compte : demandez-lui de se connecter, puis d\'entrer ce code dans "J\'ai un code d\'invitation".'
                      : 'Cette personne n\'a pas encore de compte : partagez-lui ce code pour qu\'elle puisse s\'inscrire et rejoindre automatiquement votre couple.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sageBgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    result.token,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: AppColors.clay),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Valable jusqu\'au $expiryLabel ($daysLeft jours restants)',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.clay,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: result.token));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copié')),
                    );
                  }
                },
                child: const Text('Copier le code'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
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
      if (mounted) setState(() => _sendingInvite = false);
    }
  }

  Future<void> _cancelInvitation(String invitationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler l\'invitation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(partnerNotifierProvider.notifier)
          .cancelInvitation(invitationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation annulée')),
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

  Future<void> _joinCouple() async {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _joining = true);
    try {
      await ref.read(partnerNotifierProvider.notifier).joinCouple(code);
      _joinCodeController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous avez rejoint le couple !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _acceptReceivedInvitation(ReceivedInvitation invitation) async {
    setState(() => _joining = true);
    try {
      await ref.read(partnerNotifierProvider.notifier).joinCouple(invitation.token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous avez rejoint le couple !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _declineReceivedInvitation(ReceivedInvitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Refuser cette invitation ?'),
        content: Text(
          'Vous ne rejoindrez pas le couple de ${invitation.inviterName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(partnerNotifierProvider.notifier)
          .declineInvitation(invitation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation refusée')),
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

  Widget _buildReceivedInvitationCard(ReceivedInvitation invitation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sageBgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_border,
                  color: AppColors.sage, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Invitation reçue',
                  style: AppTypography.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: AppTypography.bodyMedium,
              children: [
                TextSpan(
                  text: invitation.inviterName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                  text: ' vous a invité·e à rejoindre son couple.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sage,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed:
                      _joining ? null : () => _acceptReceivedInvitation(invitation),
                  child: Text(
                    _joining ? '...' : 'Accepter',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _declineReceivedInvitation(invitation),
                  child: const Text('Refuser'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(String partnerId, String partnerName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retirer le/la partenaire'),
        content: Text(
          'Voulez-vous vraiment retirer $partnerName ? Vous ne partagerez '
          'plus vos données, mais son compte restera actif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(partnerNotifierProvider.notifier)
                    .removePartner(partnerId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Partenaire retiré')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInvitationCard(InvitationResult invitation) {
    final daysLeft = invitation.expiresAt.difference(DateTime.now()).inDays;
    final expiryLabel =
        DateFormat('d MMMM yyyy', 'fr_FR').format(invitation.expiresAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sageBgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline, color: AppColors.sage, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Invitation envoyée',
                  style: AppTypography.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: AppTypography.bodyMedium,
              children: [
                const TextSpan(text: 'Envoyée à '),
                TextSpan(
                  text: invitation.inviteeEmail,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: AppColors.clay),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  daysLeft > 0
                      ? 'Expire le $expiryLabel ($daysLeft jours restants)'
                      : 'Expire aujourd\'hui ($expiryLabel)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.clay,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: invitation.token),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copié')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copier le code'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _cancelInvitation(invitation.id),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnerAsync = ref.watch(partnerProvider);
    final pendingInvitationAsync = ref.watch(pendingInvitationProvider);
    final receivedInvitationsAsync = ref.watch(receivedInvitationsProvider);

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
              partnerAsync.when(
                data: (partner) {
                  if (partner != null) {
                    return Container(
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
                            child: Text(
                              partner.name.isNotEmpty
                                  ? partner.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(partner.name,
                                    style: AppTypography.titleMedium),
                                Text(
                                  partner.email,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.inkTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _showRemoveDialog(
                              partner.id,
                              partner.name,
                            ),
                            child: const Text('Retirer'),
                          ),
                        ],
                      ),
                    );
                  }

                  final pendingInvitation = pendingInvitationAsync.maybeWhen(
                    data: (invitation) => invitation,
                    orElse: () => null,
                  );

                  if (pendingInvitation != null) {
                    return _buildPendingInvitationCard(pendingInvitation);
                  }

                  final receivedInvitations =
                      receivedInvitationsAsync.maybeWhen(
                    data: (invitations) => invitations,
                    orElse: () => <ReceivedInvitation>[],
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vous n\'avez pas encore de partenaire lié·e.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text('Inviter par email',
                          style: AppTypography.titleMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _inviteEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'email@exemple.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sage,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _sendingInvite ? null : _sendInvite,
                          child: Text(
                            _sendingInvite ? '...' : 'Envoyer l\'invitation',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (receivedInvitations.isNotEmpty) ...[
                        Text('Invitation reçue',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: 12),
                        ...receivedInvitations.map(
                          (invitation) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildReceivedInvitationCard(invitation),
                          ),
                        ),
                      ] else ...[
                        Text('J\'ai un code d\'invitation',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _joinCodeController,
                          decoration: InputDecoration(
                            hintText: 'Code reçu de votre partenaire',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _joining ? null : _joinCouple,
                            child: Text(_joining ? '...' : 'Rejoindre'),
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Erreur: $error'),
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
                      'Une fois lié·e, vous partagez automatiquement les '
                      'rendez-vous, médicaments et le parcours FIV avec votre '
                      'partenaire. Seules vos informations de profil restent '
                      'personnelles.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
