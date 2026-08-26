import 'package:hive_flutter/hive_flutter.dart';

part 'treatment_cycle.g.dart';

@HiveType(typeId: 9)
class TreatmentCycle extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String coupleId;

  @HiveField(2)
  int cycleNumber;

  @HiveField(3)
  DateTime startDate;

  @HiveField(4)
  DateTime? endDate;

  @HiveField(5)
  String status; // in_progress, failed, succeeded

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  TreatmentCycle({
    required this.id,
    required this.coupleId,
    required this.cycleNumber,
    required this.startDate,
    this.endDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TreatmentCycle.fromJson(Map<String, dynamic> json) {
    return TreatmentCycle(
      id: json['id'].toString(),
      coupleId: json['couple_id'].toString(),
      cycleNumber: json['cycle_number'] as int,
      startDate: DateTime.parse(json['start_date'] as String).toLocal(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String).toLocal()
          : null,
      status: json['status'] as String? ?? 'in_progress',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
