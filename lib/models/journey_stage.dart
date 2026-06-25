import 'package:hive_flutter/hive_flutter.dart';

part 'journey_stage.g.dart';

@HiveType(typeId: 6)
class JourneyStage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String coupleId;

  @HiveField(2)
  String type; // stimulation, declenchement, ponction, transfert, attente_test

  @HiveField(3)
  DateTime startDate;

  @HiveField(4)
  DateTime? startTime;

  @HiveField(5)
  String status; // upcoming, in_progress, done

  @HiveField(6)
  bool reminderEnabled;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  JourneyStage({
    required this.id,
    required this.coupleId,
    required this.type,
    required this.startDate,
    this.startTime,
    required this.status,
    required this.reminderEnabled,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  JourneyStage copyWith({
    String? id,
    String? coupleId,
    String? type,
    DateTime? startDate,
    DateTime? startTime,
    String? status,
    bool? reminderEnabled,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JourneyStage(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      status: status ?? this.status,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory JourneyStage.fromJson(Map<String, dynamic> json) {
    return JourneyStage(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      type: json['type'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      status: json['status'] as String? ?? 'upcoming',
      reminderEnabled: json['reminder_enabled'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'type': type,
      'start_date': startDate.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'status': status,
      'reminder_enabled': reminderEnabled,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
