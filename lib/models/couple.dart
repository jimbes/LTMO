import 'package:hive_flutter/hive_flutter.dart';

part 'couple.g.dart';

@HiveType(typeId: 1)
class Couple extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String user1Id;

  @HiveField(2)
  String? user2Id;

  @HiveField(3)
  Map<String, dynamic> sharingSettings;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  Couple({
    required this.id,
    required this.user1Id,
    this.user2Id,
    Map<String, dynamic>? sharingSettings,
    required this.createdAt,
    required this.updatedAt,
  }) : sharingSettings = sharingSettings ?? {};

  Couple copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    Map<String, dynamic>? sharingSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Couple(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      sharingSettings: sharingSettings ?? this.sharingSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Couple.fromJson(Map<String, dynamic> json) {
    return Couple(
      id: json['id'] as String,
      user1Id: json['user_1_id'] as String,
      user2Id: json['user_2_id'] as String?,
      sharingSettings: Map<String, dynamic>.from(
        json['sharing_settings'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_1_id': user1Id,
      'user_2_id': user2Id,
      'sharing_settings': sharingSettings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
