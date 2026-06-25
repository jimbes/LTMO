import 'package:dio/dio.dart';
import 'package:pma_flutter/config/api_config.dart';
import 'package:pma_flutter/models/notification.dart' as models;
import 'api_client.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getNotifications({
    String? status,
    String? type,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (status != null) {
        queryParams['status'] = status;
      }
      if (type != null) {
        queryParams['type'] = type;
      }

      final response = await _apiClient.get(
        ApiConfig.notifications,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final notifications = (response.data['data'] as List)
            .map((json) => models.Notification.fromJson(json))
            .toList();

        return {
          'success': true,
          'notifications': notifications,
          'pagination': response.data['meta'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch notifications',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> getNotification(int id) async {
    try {
      final response =
          await _apiClient.get('${ApiConfig.notifications}/$id');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'notification':
              models.Notification.fromJson(response.data['notification']),
        };
      } else {
        return {
          'success': false,
          'error': 'Notification not found',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.deviceTokens,
        data: {
          'token': token,
          'platform': platform,
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Device token registered',
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to register token',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> revokeDeviceToken(int tokenId) async {
    try {
      final response =
          await _apiClient.delete('${ApiConfig.deviceTokens}/$tokenId');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Device token revoked',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to revoke token',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }
}
