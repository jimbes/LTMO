import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://pma.besse.dev/api/v1';

  late Dio _dio;
  final _secureStorage = const FlutterSecureStorage();

  /// Called when a request comes back 401 (token expired/revoked server-side).
  /// Set by the app layer so it can clear auth state and route to login.
  void Function()? onSessionExpired;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // The token is dead (expired/revoked/couple removed). Clear it so
          // no further request keeps trying to use it, and let the app layer
          // know so it can reset auth state and route back to login rather
          // than silently keep serving stale cached data.
          await _secureStorage.delete(key: 'auth_token');
          onSessionExpired?.call();
        }
        return handler.next(error);
      },
    ));
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      final token = response.data['token'] as String;
      await _secureStorage.write(key: 'auth_token', value: token);

      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Registration failed';
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['token'] as String;
      await _secureStorage.write(key: 'auth_token', value: token);

      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Login failed';
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post(
        '/auth/google',
        data: {'id_token': idToken},
      );

      final token = response.data['token'] as String;
      await _secureStorage.write(key: 'auth_token', value: token);

      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Google sign-in failed';
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore errors on logout
    } finally {
      await _secureStorage.delete(key: 'auth_token');
    }
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data['user'] ?? {};
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final response = await _dio.put('/auth/me', data: data);
    return response.data['user'] ?? {};
  }

  Future<List<dynamic>> getMedications() async {
    final response = await _dio.get('/medications');
    return response.data['medications'] ?? [];
  }

  Future<Map<String, dynamic>> createMedication(Map<String, dynamic> data) async {
    final response = await _dio.post('/medications', data: data);
    return response.data['medication'] ?? {};
  }

  Future<Map<String, dynamic>> updateMedication(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/medications/$id', data: data);
    return response.data['medication'] ?? {};
  }

  Future<void> deleteMedication(String id) async {
    await _dio.delete('/medications/$id');
  }

  Future<List<dynamic>> getSchedules() async {
    final response = await _dio.get('/schedules');
    return response.data['schedules'] ?? [];
  }

  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> data) async {
    final response = await _dio.post('/schedules', data: data);
    return response.data['schedule'] ?? {};
  }

  Future<Map<String, dynamic>> updateSchedule(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/schedules/$id', data: data);
    return response.data['schedule'] ?? {};
  }

  Future<void> deleteSchedule(String id) async {
    await _dio.delete('/schedules/$id');
  }

  Future<List<dynamic>> getMedicationTakenLogs() async {
    final response = await _dio.get('/medication-taken-logs');
    return response.data['logs'] ?? [];
  }

  Future<Map<String, dynamic>> markMedicationTaken(
    String scheduleId,
    String date, {
    String? time,
  }) async {
    final response = await _dio.post(
      '/schedules/$scheduleId/mark-taken',
      data: {'date': date, 'time': time},
    );
    return response.data['log'] ?? {};
  }

  Future<Map<String, dynamic>> markMedicationNotTaken(
    String scheduleId,
    String date, {
    String? time,
  }) async {
    final response = await _dio.put(
      '/schedules/$scheduleId/mark-not-taken',
      data: {'date': date, 'time': time},
    );
    return response.data['log'] ?? {};
  }

  Future<List<dynamic>> getAppointments() async {
    final response = await _dio.get('/appointments');
    return response.data['appointments'] ?? [];
  }

  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> data) async {
    final response = await _dio.post('/appointments', data: data);
    return response.data['appointment'] ?? {};
  }

  Future<Map<String, dynamic>> updateAppointment(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/appointments/$id', data: data);
    return response.data['appointment'] ?? {};
  }

  Future<void> deleteAppointment(String id) async {
    await _dio.delete('/appointments/$id');
  }

  Future<List<dynamic>> getJourneyStages() async {
    final response = await _dio.get('/journey-stages');
    return response.data['journey_stages'] ?? [];
  }

  Future<Map<String, dynamic>> createJourneyStage(Map<String, dynamic> data) async {
    final response = await _dio.post('/journey-stages', data: data);
    return response.data['journey_stage'] ?? {};
  }

  Future<Map<String, dynamic>> updateJourneyStage(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/journey-stages/$id', data: data);
    return response.data['journey_stage'] ?? {};
  }

  Future<void> deleteJourneyStage(String id) async {
    await _dio.delete('/journey-stages/$id');
  }

  Future<Map<String, dynamic>> closeJourneyStage(String id) async {
    final response = await _dio.post('/journey-stages/$id/close');
    return response.data['journey_stage'] ?? {};
  }

  Future<List<dynamic>> getPractitioners() async {
    final response = await _dio.get('/practitioners');
    return response.data['practitioners'] ?? [];
  }

  Future<Map<String, dynamic>> createPractitioner(Map<String, dynamic> data) async {
    final response = await _dio.post('/practitioners', data: data);
    return response.data['practitioner'] ?? {};
  }

  Future<Map<String, dynamic>> updatePractitioner(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/practitioners/$id', data: data);
    return response.data['practitioner'] ?? {};
  }

  Future<void> deletePractitioner(String id) async {
    await _dio.delete('/practitioners/$id');
  }

  Future<List<dynamic>> getNotificationPreferences() async {
    final response = await _dio.get('/notification-preferences');
    return response.data['notification_preferences'] ?? [];
  }

  Future<Map<String, dynamic>> createNotificationPreference(Map<String, dynamic> data) async {
    final response = await _dio.post('/notification-preferences', data: data);
    return response.data['notification_preference'] ?? {};
  }

  Future<Map<String, dynamic>> updateNotificationPreference(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/notification-preferences/$id', data: data);
    return response.data['notification_preference'] ?? {};
  }

  Future<void> deleteNotificationPreference(String id) async {
    await _dio.delete('/notification-preferences/$id');
  }

  Future<Map<String, dynamic>?> getPartner() async {
    final response = await _dio.get('/partner');
    return response.data['partner'] as Map<String, dynamic>?;
  }

  Future<void> removePartner(String partnerId) async {
    await _dio.delete('/partner/$partnerId');
  }

  Future<Map<String, dynamic>> invitePartner(String email) async {
    final response = await _dio.post(
      '/auth/invite-partner',
      data: {'email': email},
    );
    return response.data['invitation'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getCurrentInvitation() async {
    final response = await _dio.get('/auth/invite-partner');
    return response.data['invitation'] as Map<String, dynamic>?;
  }

  Future<void> cancelInvitation(String id) async {
    await _dio.delete('/auth/invite-partner/$id');
  }

  Future<List<dynamic>> getReceivedInvitations() async {
    final response = await _dio.get('/auth/my-invitations');
    return response.data['invitations'] ?? [];
  }

  Future<void> declineInvitation(String id) async {
    await _dio.delete('/auth/my-invitations/$id');
  }

  Future<Map<String, dynamic>> acceptInvite({
    required String token,
    required String name,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dio.post(
      '/auth/accept-invite/$token',
      data: {
        'name': name,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final userToken = response.data['token'] as String;
    await _secureStorage.write(key: 'auth_token', value: userToken);

    return response.data['user'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinCouple(String token) async {
    final response = await _dio.post(
      '/auth/join-couple',
      data: {'token': token},
    );
    return response.data['user'] as Map<String, dynamic>;
  }

  Future<void> registerDeviceToken(String token) async {
    await _dio.post(
      '/devices/register',
      data: {'token': token, 'platform': 'flutter'},
    );
  }
}
