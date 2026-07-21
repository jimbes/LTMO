import 'package:hive_flutter/hive_flutter.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String? photo;

  @HiveField(4)
  DateTime? birthDate;

  @HiveField(5)
  String? coupleId;

  @HiveField(6)
  String language;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  // Whether this account is couple->users()->first() - i.e. which of
  // notify_user_1/notify_user_2 (on appointments/schedules) applies to it.
  // Defaults true (couple not joined yet, or field missing) so a solo
  // account still gets its own reminders.
  @HiveField(9)
  bool isPrimaryUser;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photo,
    this.birthDate,
    this.coupleId,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
    this.isPrimaryUser = true,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photo,
    DateTime? birthDate,
    String? coupleId,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPrimaryUser,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      birthDate: birthDate ?? this.birthDate,
      coupleId: coupleId ?? this.coupleId,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrimaryUser: isPrimaryUser ?? this.isPrimaryUser,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      photo: json['photo'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      coupleId: json['couple_id'] != null ? json['couple_id'].toString() : null,
      language: json['language'] as String? ?? 'fr',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      isPrimaryUser: json['is_primary_user'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photo': photo,
      'birth_date': birthDate?.toIso8601String(),
      'couple_id': coupleId,
      'language': language,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_primary_user': isPrimaryUser,
    };
  }
}
