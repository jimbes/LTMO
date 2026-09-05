import 'package:hive_flutter/hive_flutter.dart';

part 'appointment.g.dart';

@HiveType(typeId: 5)
class Appointment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String coupleId;

  @HiveField(2)
  String title;

  @HiveField(3)
  DateTime appointmentDate;

  @HiveField(4)
  DateTime? appointmentTime;

  @HiveField(5)
  String? location;

  @HiveField(6)
  String? doctorName;

  @HiveField(7)
  String? description;

  // A visit can cover more than one subject (e.g. écho + prise de sang the
  // same day) - echo, blood_test, consult, ponction, transfert, other.
  @HiveField(8)
  List<String> types;

  @HiveField(9)
  bool notifyUser1;

  @HiveField(10)
  bool notifyUser2;

  @HiveField(11)
  bool completed;

  // Minutes before the appointment to remind - can have several reminders
  // (e.g. 24h before AND 12h before), not just one.
  @HiveField(12)
  List<int> reminderOffsets;

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  DateTime updatedAt;

  // The journey stage this appointment relates to, if any - lets the app
  // offer quick "mark stage skipped" / "start new cycle" actions right after
  // the appointment once we know what it was for.
  @HiveField(15)
  String? journeyStageId;

  Appointment({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.appointmentDate,
    this.appointmentTime,
    this.location,
    this.doctorName,
    this.description,
    this.types = const [],
    required this.notifyUser1,
    required this.notifyUser2,
    required this.completed,
    required this.reminderOffsets,
    required this.createdAt,
    required this.updatedAt,
    this.journeyStageId,
  });

  Appointment copyWith({
    String? id,
    String? coupleId,
    String? title,
    DateTime? appointmentDate,
    DateTime? appointmentTime,
    String? location,
    String? doctorName,
    String? description,
    List<String>? types,
    bool? notifyUser1,
    bool? notifyUser2,
    bool? completed,
    List<int>? reminderOffsets,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? journeyStageId,
    bool clearJourneyStageId = false,
  }) {
    return Appointment(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      location: location ?? this.location,
      doctorName: doctorName ?? this.doctorName,
      description: description ?? this.description,
      types: types ?? this.types,
      notifyUser1: notifyUser1 ?? this.notifyUser1,
      notifyUser2: notifyUser2 ?? this.notifyUser2,
      completed: completed ?? this.completed,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      journeyStageId: clearJourneyStageId
          ? null
          : (journeyStageId ?? this.journeyStageId),
    );
  }

  static DateTime _parseTimeOnDate(String timeStr, DateTime date) {
    final parts = timeStr.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    // .toLocal() is required - see the same note in medication_schedule.dart.
    final appointmentDate =
        DateTime.parse(json['appointment_date'] as String).toLocal();
    return Appointment(
      id: json['id'].toString(),
      coupleId: json['couple_id'].toString(),
      title: json['title'] as String,
      appointmentDate: appointmentDate,
      appointmentTime: json['appointment_time'] != null
          ? _parseTimeOnDate(
              json['appointment_time'] as String, appointmentDate)
          : null,
      location: json['location'] as String?,
      doctorName: json['doctor_name'] as String?,
      description: json['description'] as String?,
      types: (json['types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      notifyUser1: json['notify_user_1'] as bool? ?? true,
      notifyUser2: json['notify_user_2'] as bool? ?? true,
      completed: json['completed'] as bool? ?? false,
      reminderOffsets: (json['reminder_offsets'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [60],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      journeyStageId: json['journey_stage_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'title': title,
      'appointment_date': appointmentDate.toIso8601String(),
      'appointment_time': appointmentTime?.toIso8601String(),
      'location': location,
      'doctor_name': doctorName,
      'description': description,
      'types': types,
      'notify_user_1': notifyUser1,
      'notify_user_2': notifyUser2,
      'completed': completed,
      'reminder_offsets': reminderOffsets,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'journey_stage_id': journeyStageId,
    };
  }
}
