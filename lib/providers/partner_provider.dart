import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'auth_provider.dart';
import 'medication_provider.dart';
import 'appointment_provider.dart';
import 'journey_provider.dart';

final partnerProvider = FutureProvider<User?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);

  if (token == null) return null;

  final data = await apiService.getPartner();
  if (data == null || data.isEmpty) return null;
  return User.fromJson(data);
});

class InvitationResult {
  final String id;
  final String token;
  final String inviteeEmail;
  final bool existingUser;
  final DateTime expiresAt;

  InvitationResult({
    required this.id,
    required this.token,
    required this.inviteeEmail,
    required this.existingUser,
    required this.expiresAt,
  });

  factory InvitationResult.fromJson(Map<String, dynamic> json) {
    return InvitationResult(
      id: json['id'].toString(),
      token: json['token'] as String,
      inviteeEmail: json['invitee_email'] as String,
      existingUser: json['existing_user'] as bool? ?? false,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

final pendingInvitationProvider = FutureProvider<InvitationResult?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);

  if (token == null) return null;

  final data = await apiService.getCurrentInvitation();
  if (data == null || data.isEmpty) return null;
  return InvitationResult.fromJson(data);
});

class ReceivedInvitation {
  final String id;
  final String token;
  final String inviterName;
  final DateTime expiresAt;

  ReceivedInvitation({
    required this.id,
    required this.token,
    required this.inviterName,
    required this.expiresAt,
  });

  factory ReceivedInvitation.fromJson(Map<String, dynamic> json) {
    return ReceivedInvitation(
      id: json['id'].toString(),
      token: json['token'] as String,
      inviterName: json['inviter_name'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

/// Invitations sent TO the current user's email, awaiting their response.
final receivedInvitationsProvider =
    FutureProvider<List<ReceivedInvitation>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);

  if (token == null) return [];

  final data = await apiService.getReceivedInvitations();
  return data
      .map((e) => ReceivedInvitation.fromJson(e as Map<String, dynamic>))
      .toList();
});

final partnerNotifierProvider =
    StateNotifierProvider<PartnerNotifier, AsyncValue<void>>((ref) {
  return PartnerNotifier(ref);
});

class PartnerNotifier extends StateNotifier<AsyncValue<void>> {
  PartnerNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<InvitationResult> invitePartner(String email) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final invitation = await apiService.invitePartner(email);

      ref.invalidate(pendingInvitationProvider);
      state = const AsyncValue.data(null);
      return InvitationResult.fromJson(invitation);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancelInvitation(String id) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      await apiService.cancelInvitation(id);

      ref.invalidate(pendingInvitationProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> joinCouple(String token) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      await apiService.joinCouple(token);

      ref.invalidate(partnerProvider);
      ref.invalidate(pendingInvitationProvider);
      ref.invalidate(receivedInvitationsProvider);
      await ref.read(userProvider.notifier).fetchCurrentUser();

      // Joining a couple changes couple_id without changing the auth token,
      // so providers keyed only off the token (medications, appointments,
      // journey stages...) wouldn't otherwise know to refetch. Force it.
      ref.invalidate(medicationsProvider);
      ref.invalidate(schedulesProvider);
      ref.invalidate(appointmentsProvider);
      ref.invalidate(stagesProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> declineInvitation(String id) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      await apiService.declineInvitation(id);

      ref.invalidate(receivedInvitationsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> removePartner(String partnerId) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      await apiService.removePartner(partnerId);

      ref.invalidate(partnerProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
