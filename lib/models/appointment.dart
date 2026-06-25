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

  @HiveField(12)
  int reminderMinutesBefore;

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
    required this.reminderMinutesBefore,
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
    int? reminderMinutesBefore,
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
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      title: json['title'] as String,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      appointmentTime: json['appointment_time'] != null
          ? DateTime.parse(json['appointment_time'] as String)
          : null,
      location: json['location'] as String?,
      doctorName: json['doctor_name'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      notifyUser1: json['notify_user_1'] as bool? ?? true,
      notifyUser2: json['notify_user_2'] as bool? ?? true,
      completed: json['completed'] as bool? ?? false,
      reminderMinutesBefore: json['reminder_before_minutes'] as int? ?? 60,
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
      'reminder_before_minutes': reminderMinutesBefore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
