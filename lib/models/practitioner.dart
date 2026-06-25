import 'package:hive_flutter/hive_flutter.dart';

part 'practitioner.g.dart';

@HiveType(typeId: 7)
class Practitioner extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String coupleId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String? specialty;

  @HiveField(4)
  String? phone;

  @HiveField(5)
  String? email;

  @HiveField(6)
  String? clinicName;

  @HiveField(7)
  String? address;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  Practitioner({
    required this.id,
    required this.coupleId,
    required this.name,
    this.specialty,
    this.phone,
    this.email,
    this.clinicName,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  Practitioner copyWith({
    String? id,
    String? coupleId,
    String? name,
    String? specialty,
    String? phone,
    String? email,
    String? clinicName,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Practitioner(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      clinicName: clinicName ?? this.clinicName,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Practitioner.fromJson(Map<String, dynamic> json) {
    return Practitioner(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      name: json['name'] as String,
      specialty: json['specialty'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      clinicName: json['clinic_name'] as String?,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'name': name,
      'specialty': specialty,
      'phone': phone,
      'email': email,
      'clinic_name': clinicName,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
