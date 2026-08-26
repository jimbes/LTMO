import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

/// True when [e] means "the request never reached the server" (no network,
/// DNS failure, timeout) - the case that should queue a write for later
/// instead of surfacing it as a real error (422, 409, etc.).
bool isNetworkError(Object e) {
  return e is DioException && isNetworkErrorType(e.type);
}

/// Combines two signals: the OS-reported network interface state
/// (connectivity_plus - fast, but a false positive on "wifi with no real
/// internet access") and actual Dio request failures (authoritative, but
/// only observed when a request is attempted). Either source can mark the
/// app offline; only a fresh OS-level connectivity change marks it online
/// again, at which point the next real request confirms or corrects it.
final isOnlineProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final notifier = ConnectivityNotifier();
  apiService.onNetworkError = notifier.markOffline;
  return notifier;
});

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    Connectivity().checkConnectivity().then(_applyOsResult);
    _subscription = Connectivity().onConnectivityChanged.listen(_applyOsResult);
  }

  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  void _applyOsResult(List<ConnectivityResult> results) {
    state = results.any((r) => r != ConnectivityResult.none);
  }

  void markOffline() {
    state = false;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
