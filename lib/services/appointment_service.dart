import 'package:dio/dio.dart';
import 'package:pma_flutter/config/api_config.dart';
import 'package:pma_flutter/models/appointment.dart';
import 'api_client.dart';

class AppointmentService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getAppointments() async {
    try {
      final response = await _apiClient.get(ApiConfig.appointments);

      if (response.statusCode == 200) {
        final appointments = (response.data['data'] as List)
            .map((json) => Appointment.fromJson(json))
            .toList();

        return {
          'success': true,
          'appointments': appointments,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch appointments',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> getAppointment(int id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.appointments}/$id');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'appointment': Appointment.fromJson(response.data['appointment']),
        };
      } else {
        return {
          'success': false,
          'error': 'Appointment not found',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> createAppointment({
    required String title,
    required DateTime appointmentDate,
    String? appointmentTime,
    String? location,
    String? doctorName,
    String? description,
    required bool notifyUser1,
    required bool notifyUser2,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.appointments,
        data: {
          'title': title,
          'appointment_date':
              appointmentDate.toIso8601String().split('T')[0],
          'appointment_time': appointmentTime,
          'location': location,
          'doctor_name': doctorName,
          'description': description,
          'notify_user_1': notifyUser1,
          'notify_user_2': notifyUser2,
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'appointment': Appointment.fromJson(response.data['appointment']),
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to create appointment',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> updateAppointment(
    int id, {
    required String title,
    required DateTime appointmentDate,
    String? appointmentTime,
    String? location,
    String? doctorName,
    String? description,
    required bool notifyUser1,
    required bool notifyUser2,
  }) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.appointments}/$id',
        data: {
          'title': title,
          'appointment_date':
              appointmentDate.toIso8601String().split('T')[0],
          'appointment_time': appointmentTime,
          'location': location,
          'doctor_name': doctorName,
          'description': description,
          'notify_user_1': notifyUser1,
          'notify_user_2': notifyUser2,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'appointment': Appointment.fromJson(response.data['appointment']),
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to update appointment',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> markAppointmentComplete(int id) async {
    try {
      final response =
          await _apiClient.post('${ApiConfig.appointments}/$id/mark-complete');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'appointment': Appointment.fromJson(response.data['appointment']),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to mark appointment complete',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> deleteAppointment(int id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.appointments}/$id');

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': 'Failed to delete appointment',
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
