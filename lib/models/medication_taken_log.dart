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
    );
  }

  factory MedicationTakenLog.fromJson(Map<String, dynamic> json) {
    return MedicationTakenLog(
      id: json['id'] as String,
      medicationScheduleId: json['medication_schedule_id'] as String,
      date: DateTime.parse(json['date'] as String),
      taken: json['taken'] as bool? ?? false,
      takenAt: json['taken_at'] != null
          ? DateTime.parse(json['taken_at'] as String)
          : null,
      userLoggedById: json['user_logged_by'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
    };
  }
}
