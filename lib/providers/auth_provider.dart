import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/local_notification_service.dart';
import '../services/push_notification_service.dart';
import 'data_refresh.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final service = ApiService();
  service.onSessionExpired = () {
    ref.read(userProvider.notifier).forceLogout();
    UserNotifier.navigateToLogin?.call();
  };
  return service;
});

final authTokenProvider = FutureProvider<String?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getToken();
});

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  return UserNotifier(ref);
});

class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  UserNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Set once from router.dart (which owns the GoRouter instance) so this
  /// provider can trigger navigation without importing the router - avoids
  /// a circular import (router -> screens -> this file -> router).
  static void Function()? navigateToLogin;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      final user = User.fromJson(response['user']);
      state = AsyncValue.data(user);

      // Clear old mock data and refresh providers
      await _clearHiveBoxes();
      _onAuthSuccess();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> acceptInvite({
    required String token,
    required String name,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.acceptInvite(
        token: token,
        name: name,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      final user = User.fromJson(response);
      state = AsyncValue.data(user);

      await _clearHiveBoxes();
      _onAuthSuccess();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.loginWithGoogle(idToken);

      final user = User.fromJson(response['user']);
      state = AsyncValue.data(user);

      await _clearHiveBoxes();
      _onAuthSuccess();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.login(
        email: email,
        password: password,
      );

      final user = User.fromJson(response['user']);
      state = AsyncValue.data(user);

      // Clear old mock data and refresh providers
      await _clearHiveBoxes();
      _onAuthSuccess();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> fetchCurrentUser() async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      final token = await apiService.getToken();

      if (token == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final response = await apiService.getMe();
      final user = User.fromJson(response);
      state = AsyncValue.data(user);

      // Same as a fresh login: an already-logged-in session resuming (e.g.
      // app relaunch) still needs its notifications (re)synced, since local
      // notifications aren't persisted server-side.
      _onAuthSuccess();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateUser(User user) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);

      final data = {
        'name': user.name,
        'email': user.email,
      };

      final response = await apiService.updateMe(data);
      final updatedUser = User.fromJson(response);
      state = AsyncValue.data(updatedUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.logout();
      state = const AsyncValue.data(null);

      // Clear Hive cache on logout
      await _clearHiveBoxes();
      _invalidateDataProviders();

      // Cancel every scheduled reminder so the next session (possibly a
      // different user on the same device) doesn't inherit stale ones.
      await LocalNotificationService.instance.cancelAll();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Triggered by ApiService when a request comes back 401 - the token is
  /// already dead server-side, so unlike logout() this doesn't call the
  /// logout endpoint (that would just 401 again). Just resets local state.
  Future<void> forceLogout() async {
    state = const AsyncValue.data(null);
    await _clearHiveBoxes();
    _invalidateDataProviders();
    await LocalNotificationService.instance.cancelAll();
  }

  Future<void> _clearHiveBoxes() async {
    try {
      await Hive.box('medications_box').clear();
      await Hive.box('schedules_box').clear();
      await Hive.box('logs_box').clear();
      await Hive.box('appointments_box').clear();
      await Hive.box('stages_box').clear();
      await Hive.box('practitioners_box').clear();
      await Hive.box('notif_prefs_box').clear();
    } catch (e) {
      // Boxes might not be open yet
    }
  }

  void _invalidateDataProviders() {
    // Every data provider (medications, appointments, journey stages, etc.)
    // watches authTokenProvider.future to know whether a user is logged in.
    // Invalidating it cascades a refetch to all of them - without this,
    // they keep serving whatever they last resolved to (often "no token,
    // return empty") even after a different user logs in in the same
    // app session.
    ref.invalidate(authTokenProvider);
  }

  /// Call after a successful register/login/Google-login/accept-invite.
  /// Local notifications don't sync with the server, so a fresh
  /// install/device has none scheduled until this runs once per login.
  void _onAuthSuccess() {
    _invalidateDataProviders();
    LocalNotificationService.instance.requestPermissions().then((_) {
      resyncAllNotifications(ref);
    });

    // Registers this device for server-driven push (FCM) - separate from
    // local notifications above, this is what lets the *partner's* phone
    // get notified too, and survives the app being killed by battery
    // management (a known issue with the local-alarm approach on Samsung).
    final apiService = ref.read(apiServiceProvider);
    PushNotificationService.instance.init(
      onTokenReady: (token) => apiService.registerDeviceToken(token),
    );
  }
}
