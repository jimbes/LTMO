import 'package:dio/dio.dart';
import 'package:pma_flutter/config/api_config.dart';
import 'package:pma_flutter/models/medication.dart';
import 'package:pma_flutter/models/medication_schedule.dart';
import 'package:pma_flutter/models/medication_taken_log.dart';
import 'api_client.dart';

class MedicationService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getMedications() async {
    try {
      final response = await _apiClient.get(ApiConfig.medications);

      if (response.statusCode == 200) {
        final medications = (response.data['data'] as List)
            .map((json) => Medication.fromJson(json))
            .toList();

        return {
          'success': true,
          'medications': medications,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch medications',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> getMedication(int id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.medications}/$id');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'medication': Medication.fromJson(response.data['medication']),
        };
      } else {
        return {
          'success': false,
          'error': 'Medication not found',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> createMedication({
    required String name,
    required String dosage,
    required String unit,
    String? description,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.medications,
        data: {
          'name': name,
          'dosage': dosage,
          'unit': unit,
          'description': description,
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'medication': Medication.fromJson(response.data['medication']),
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to create medication',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> updateMedication(
    int id, {
    required String name,
    required String dosage,
    required String unit,
    String? description,
  }) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.medications}/$id',
        data: {
          'name': name,
          'dosage': dosage,
          'unit': unit,
          'description': description,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'medication': Medication.fromJson(response.data['medication']),
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to update medication',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> deactivateMedication(int id) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.medications}/$id',
        data: {'active': false},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'medication': Medication.fromJson(response.data['medication']),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to deactivate medication',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> deleteMedication(int id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.medications}/$id');

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': 'Failed to delete medication',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  // Medication Schedules
  Future<Map<String, dynamic>> getSchedules({int? medicationId}) async {
    try {
      final path = medicationId != null
          ? '${ApiConfig.medications}/$medicationId${ApiConfig.medicationSchedules}'
          : ApiConfig.medicationSchedules;

      final response = await _apiClient.get(path);

      if (response.statusCode == 200) {
        final schedules = (response.data['data'] as List)
            .map((json) => MedicationSchedule.fromJson(json))
            .toList();

        return {
          'success': true,
          'schedules': schedules,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch schedules',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> createSchedule({
    required int medicationId,
    required DateTime startDate,
    DateTime? endDate,
    required String frequency,
    List<int>? daysOfWeek,
    required List<String> reminderTimes,
    int? reminderOffsetHours,
    required bool notifyUser1,
    required bool notifyUser2,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.medicationSchedules,
        data: {
          'medication_id': medicationId,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate?.toIso8601String().split('T')[0],
          'frequency': frequency,
          'days_of_week': daysOfWeek,
          'reminder_times': reminderTimes,
          'reminder_offset_hours': reminderOffsetHours,
          'notify_user_1': notifyUser1,
          'notify_user_2': notifyUser2,
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'schedule': MedicationSchedule.fromJson(response.data['schedule']),
        };
      } else {
        return {
          'success': false,
          'error':
              response.data['message'] ?? 'Failed to create schedule',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  // Medication Adherence
  Future<Map<String, dynamic>> getAdherenceHistory(int scheduleId) async {
    try {
      final response = await _apiClient
          .get('${ApiConfig.medicationSchedules}/$scheduleId/history');

      if (response.statusCode == 200) {
        final logs = (response.data['logs'] as List)
            .map((json) => MedicationTakenLog.fromJson(json))
            .toList();

        return {
          'success': true,
          'logs': logs,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch adherence history',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> markMedicationTaken(
    int scheduleId, {
    required DateTime date,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.medicationSchedules}/$scheduleId/mark-taken',
        data: {
          'date': date.toIso8601String().split('T')[0],
          'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'log': MedicationTakenLog.fromJson(response.data['log']),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to mark medication taken',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> markMedicationNotTaken(
    int scheduleId, {
    required DateTime date,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.medicationSchedules}/$scheduleId/mark-not-taken',
        data: {
          'date': date.toIso8601String().split('T')[0],
          'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'log': MedicationTakenLog.fromJson(response.data['log']),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to mark medication not taken',
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
