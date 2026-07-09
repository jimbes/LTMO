import 'package:hive_flutter/hive_flutter.dart';

part 'medication.g.dart';

@HiveType(typeId: 2)
class Medication extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String coupleId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String dosage;

  @HiveField(4)
  String unit;

  @HiveField(5)
  String? description;

  @HiveField(6)
  String? form; // injection, comprimé, patch, ovule

  @HiveField(7)
  String forPartner; // user1, user2, both

  @HiveField(8)
  bool active;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  Medication({
    required this.id,
    required this.coupleId,
    required this.name,
    required this.dosage,
    required this.unit,
    this.description,
    this.form,
    required this.forPartner,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  Medication copyWith({
    String? id,
    String? coupleId,
    String? name,
    String? dosage,
    String? unit,
    String? description,
    String? form,
    String? forPartner,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      form: form ?? this.form,
      forPartner: forPartner ?? this.forPartner,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'].toString(),
      coupleId: json['couple_id'].toString(),
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      unit: json['unit'] as String,
      description: json['description'] as String?,
      form: json['form'] as String?,
      forPartner: json['for_partner'] as String? ?? 'both',
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'description': description,
      'form': form,
      'for_partner': forPartner,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
