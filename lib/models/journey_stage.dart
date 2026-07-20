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

  @HiveField(10)
  DateTime? endDate;

  @HiveField(11)
  int order;

  @HiveField(12)
  int? durationDays;

  @HiveField(13)
  String? customName;

  @HiveField(14)
  bool manualEndDate;

  @HiveField(15)
  bool manualStartDate;

  JourneyStage({
    required this.id,
    required this.coupleId,
    required this.type,
    required this.startDate,
    this.startTime,
    this.endDate,
    required this.status,
    required this.reminderEnabled,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.order = 0,
    this.durationDays,
    this.customName,
    this.manualEndDate = false,
    this.manualStartDate = false,
  });

  JourneyStage copyWith({
    String? id,
    String? coupleId,
    String? type,
    DateTime? startDate,
    DateTime? startTime,
    DateTime? endDate,
    bool clearEndDate = false,
    String? status,
    bool? reminderEnabled,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? order,
    int? durationDays,
    bool clearDurationDays = false,
    String? customName,
    bool clearCustomName = false,
    bool? manualEndDate,
    bool? manualStartDate,
  }) {
    return JourneyStage(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      status: status ?? this.status,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      order: order ?? this.order,
      durationDays:
          clearDurationDays ? null : (durationDays ?? this.durationDays),
      customName: clearCustomName ? null : (customName ?? this.customName),
      manualEndDate: manualEndDate ?? this.manualEndDate,
      manualStartDate: manualStartDate ?? this.manualStartDate,
    );
  }

  factory JourneyStage.fromJson(Map<String, dynamic> json) {
    return JourneyStage(
      id: json['id'].toString(),
      coupleId: json['couple_id'].toString(),
      type: json['type'] as String,
      // .toLocal() is required - see the same note in medication_schedule.dart.
      startDate: DateTime.parse(json['start_date'] as String).toLocal(),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String).toLocal()
          : null,
      status: json['status'] as String? ?? 'upcoming',
      reminderEnabled: json['reminder_enabled'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      order: json['order'] as int? ?? 0,
      durationDays: json['duration_days'] as int?,
      customName: json['custom_name'] as String?,
      manualEndDate: json['manual_end_date'] as bool? ?? false,
      manualStartDate: json['manual_start_date'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'type': type,
      'custom_name': customName,
      'order': order,
      'start_date': startDate.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'duration_days': durationDays,
      'manual_end_date': manualEndDate,
      'manual_start_date': manualStartDate,
      'status': status,
      'reminder_enabled': reminderEnabled,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
