import 'package:hive_flutter/hive_flutter.dart';

part 'notification_preference.g.dart';

@HiveType(typeId: 8)
class NotificationPreference extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String type; // medication_reminder, appointment, journey_stage

  @HiveField(3)
  String channel; // push, email, both

  @HiveField(4)
  bool enabled;

  @HiveField(5)
  int reminderMinutesBefore;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  NotificationPreference({
    required this.id,
    required this.userId,
    required this.type,
    required this.channel,
    required this.enabled,
    required this.reminderMinutesBefore,
    required this.createdAt,
    required this.updatedAt,
  });

  NotificationPreference copyWith({
    String? id,
    String? userId,
    String? type,
    String? channel,
    bool? enabled,
    int? reminderMinutesBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      enabled: enabled ?? this.enabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      channel: json['channel'] as String? ?? 'both',
      enabled: json['enabled'] as bool? ?? true,
      reminderMinutesBefore: json['reminder_minutes_before'] as int? ?? 15,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'channel': channel,
      'enabled': enabled,
      'reminder_minutes_before': reminderMinutesBefore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
