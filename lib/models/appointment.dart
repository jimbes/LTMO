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

  @HiveField(8)
  String? type; // echo, blood_test, consult, ponction, transfert, other

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

  Appointment({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.appointmentDate,
    this.appointmentTime,
    this.location,
    this.doctorName,
    this.description,
    this.type,
    required this.notifyUser1,
    required this.notifyUser2,
    required this.completed,
    required this.reminderOffsets,
    required this.createdAt,
    required this.updatedAt,
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
    String? type,
    bool? notifyUser1,
    bool? notifyUser2,
    bool? completed,
    List<int>? reminderOffsets,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      type: type ?? this.type,
      notifyUser1: notifyUser1 ?? this.notifyUser1,
      notifyUser2: notifyUser2 ?? this.notifyUser2,
      completed: completed ?? this.completed,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      type: json['type'] as String?,
      notifyUser1: json['notify_user_1'] as bool? ?? true,
      notifyUser2: json['notify_user_2'] as bool? ?? true,
      completed: json['completed'] as bool? ?? false,
      reminderOffsets: (json['reminder_offsets'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [60],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
      'type': type,
      'notify_user_1': notifyUser1,
      'notify_user_2': notifyUser2,
      'completed': completed,
      'reminder_offsets': reminderOffsets,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
