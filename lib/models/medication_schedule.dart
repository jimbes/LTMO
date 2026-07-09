import 'package:hive_flutter/hive_flutter.dart';

part 'medication_schedule.g.dart';

@HiveType(typeId: 3)
class MedicationSchedule extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String medicationId;

  @HiveField(2)
  String coupleId;

  @HiveField(3)
  DateTime startDate;

  @HiveField(4)
  DateTime? endDate;

  @HiveField(13)
  String? journeyStageId;

  @HiveField(5)
  String frequency; // daily, specific_days

  @HiveField(6)
  List<int>? daysOfWeek; // 0-6, Monday-Sunday

  @HiveField(7)
  List<String> reminderTimes; // HH:MM format

  // Minutes before each dose time to remind - a dose can have several
  // reminders (e.g. 1h before AND 15min before), not just one.
  @HiveField(8)
  List<int> reminderOffsets;

  @HiveField(9)
  bool notifyUser1;

  @HiveField(10)
  bool notifyUser2;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  MedicationSchedule({
    required this.id,
    required this.medicationId,
    required this.coupleId,
    required this.startDate,
    this.endDate,
    required this.frequency,
    this.daysOfWeek,
    required this.reminderTimes,
    required this.reminderOffsets,
    required this.notifyUser1,
    required this.notifyUser2,
    required this.createdAt,
    required this.updatedAt,
    this.journeyStageId,
  });

  MedicationSchedule copyWith({
    String? id,
    String? medicationId,
    String? coupleId,
    DateTime? startDate,
    DateTime? endDate,
    String? frequency,
    List<int>? daysOfWeek,
    List<String>? reminderTimes,
    List<int>? reminderOffsets,
    bool? notifyUser1,
    bool? notifyUser2,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? journeyStageId,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      coupleId: coupleId ?? this.coupleId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      notifyUser1: notifyUser1 ?? this.notifyUser1,
      notifyUser2: notifyUser2 ?? this.notifyUser2,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      journeyStageId: journeyStageId ?? this.journeyStageId,
    );
  }

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      id: json['id'].toString(),
      medicationId: json['medication_id'].toString(),
      coupleId: json['couple_id'].toString(),
      // .toLocal() is required: the backend serializes date-only fields as
      // a UTC instant (e.g. Paris midnight -> previous day 22:00Z), so
      // reading year/month/day off the raw UTC value gives the wrong
      // calendar day. Without this, saving a schedule back unchanged
      // silently shifts start/end dates one day earlier every time.
      startDate: DateTime.parse(json['start_date'] as String).toLocal(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String).toLocal()
          : null,
      frequency: json['frequency'] as String,
      daysOfWeek: (json['days_of_week'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      reminderTimes: List<String>.from(
        json['reminder_times'] as List<dynamic>? ?? [],
      ),
      reminderOffsets: (json['reminder_offsets'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [15],
      notifyUser1: json['notify_user_1'] as bool? ?? true,
      notifyUser2: json['notify_user_2'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      journeyStageId: json['journey_stage_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'couple_id': coupleId,
      'journey_stage_id': journeyStageId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'frequency': frequency,
      'days_of_week': daysOfWeek,
      'reminder_times': reminderTimes,
      'reminder_offsets': reminderOffsets,
      'notify_user_1': notifyUser1,
      'notify_user_2': notifyUser2,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
