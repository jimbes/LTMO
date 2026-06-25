import 'package:dio/dio.dart';
import 'package:pma_flutter/config/api_config.dart';
import 'package:pma_flutter/models/user.dart';
import 'api_client.dart';

class PartnerService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getPartner() async {
    try {
      final response = await _apiClient.get(ApiConfig.partner);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'partner': User.fromJson(response.data['partner']),
        };
      } else {
        return {
          'success': false,
          'error': 'Partner not found',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> removePartner() async {
    try {
      final response = await _apiClient.delete(ApiConfig.partner);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Partner removed',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to remove partner',
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
