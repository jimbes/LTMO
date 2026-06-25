import 'package:dio/dio.dart';
import 'package:pma_flutter/config/api_config.dart';
import 'package:pma_flutter/models/user.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.authRegister,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if (response.statusCode == 201) {
        final token = response.data['token'];
        final userData = response.data['user'];

        await _storage.saveAuthToken(token);
        await _storage.saveUserId(userData['id']);
        await _storage.saveCoupleId(userData['couple_id']);

        return {
          'success': true,
          'user': User.fromJson(userData),
          'token': token,
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Registration failed',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.authLogin,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final userData = response.data['user'];

        await _storage.saveAuthToken(token);
        await _storage.saveUserId(userData['id']);
        await _storage.saveCoupleId(userData['couple_id']);

        return {
          'success': true,
          'user': User.fromJson(userData),
          'token': token,
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Login failed',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConfig.authMe);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': User.fromJson(response.data['user']),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch user',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _apiClient.post(ApiConfig.authLogout);

      await _storage.clearAll();

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': 'Logout failed',
        };
      }
    } on DioException catch (e) {
      await _storage.clearAll();
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> invitePartner({
    required String email,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.authInvitePartner,
        data: {'email': email},
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Invitation sent successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to send invitation',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> acceptInvite({
    required String token,
    required String name,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.authAcceptInvite,
        data: {
          'token': token,
          'name': name,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if (response.statusCode == 200) {
        final authToken = response.data['token'];
        final userData = response.data['user'];

        await _storage.saveAuthToken(authToken);
        await _storage.saveUserId(userData['id']);
        await _storage.saveCoupleId(userData['couple_id']);

        return {
          'success': true,
          'user': User.fromJson(userData),
          'token': authToken,
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to accept invitation',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<bool> isLoggedIn() {
    return _storage.isLoggedIn();
  }
}
