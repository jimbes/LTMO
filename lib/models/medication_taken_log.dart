import 'package:hive_flutter/hive_flutter.dart';

part 'medication_taken_log.g.dart';

@HiveType(typeId: 4)
class MedicationTakenLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String medicationScheduleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  bool taken;

  @HiveField(4)
  DateTime? takenAt;

  @HiveField(5)
  String? userLoggedById;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  // The reminder time slot this log entry is for (e.g. "08:00"), so a
  // schedule with several reminder times a day can have each one marked
  // taken independently instead of sharing a single per-day entry. Null
  // means "the whole day" (legacy rows from before this field existed).
  @HiveField(9)
  String? time;

  MedicationTakenLog({
    required this.id,
    required this.medicationScheduleId,
    required this.date,
    required this.taken,
    this.takenAt,
    this.userLoggedById,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.time,
  });

  MedicationTakenLog copyWith({
    String? id,
    String? medicationScheduleId,
    DateTime? date,
    bool? taken,
    DateTime? takenAt,
    String? userLoggedById,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? time,
  }) {
    return MedicationTakenLog(
      id: id ?? this.id,
      medicationScheduleId: medicationScheduleId ?? this.medicationScheduleId,
      date: date ?? this.date,
      taken: taken ?? this.taken,
      takenAt: takenAt ?? this.takenAt,
      userLoggedById: userLoggedById ?? this.userLoggedById,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      time: time ?? this.time,
    );
  }

  // The backend returns taken_at as a bare "H:i:s" time string (a MySQL
  // TIME column, not a datetime) - DateTime.parse() can't parse that alone,
  // it needs to be combined with a date first (same issue as appointment
  // times, see Appointment._parseTimeOnDate).
  static DateTime _parseTimeOnDate(String timeStr, DateTime date) {
    final parts = timeStr.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts.length > 2 ? int.parse(parts[2]) : 0,
    );
  }

  factory MedicationTakenLog.fromJson(Map<String, dynamic> json) {
    // .toLocal() is required - see the same note in medication_schedule.dart.
    final date = DateTime.parse(json['date'] as String).toLocal();
    return MedicationTakenLog(
      id: json['id'].toString(),
      medicationScheduleId: json['medication_schedule_id'].toString(),
      date: date,
      taken: json['taken'] as bool? ?? false,
      takenAt: json['taken_at'] != null
          ? _parseTimeOnDate(json['taken_at'] as String, date)
          : null,
      userLoggedById: json['user_logged_by'] != null ? json['user_logged_by'].toString() : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      time: json['time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_schedule_id': medicationScheduleId,
      'date': date.toIso8601String(),
      'taken': taken,
      'taken_at': takenAt?.toIso8601String(),
      'user_logged_by': userLoggedById,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'time': time,
    };
  }
}
