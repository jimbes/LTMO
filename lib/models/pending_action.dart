import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

part 'pending_action.g.dart';

@HiveType(typeId: 10)
class PendingAction extends HiveObject {
  @HiveField(0)
  String id;

  // e.g. 'appointment', 'medication', 'schedule', 'medication_taken_log',
  // 'journey_stage', 'practitioner', 'notification_preference'.
  @HiveField(1)
  String entityType;

  // 'create', 'update', or 'delete'.
  @HiveField(2)
  String operation;

  // Null only for 'create' - the server assigns the id once synced.
  @HiveField(3)
  String? targetId;

  @HiveField(4)
  Map<String, dynamic> payload;

  // The updated_at this device last saw for the record, sent back on sync so
  // the server can detect whether someone else changed it first. Null for
  // 'create' (nothing to compare against yet).
  @HiveField(5)
  String? knownUpdatedAt;

  @HiveField(6)
  DateTime createdAt;

  PendingAction({
    required this.id,
    required this.entityType,
    required this.operation,
    this.targetId,
    required this.payload,
    this.knownUpdatedAt,
    required this.createdAt,
  });

  static String newId() {
    final rand = Random().nextInt(1 << 32).toRadixString(16);
    return 'local-${DateTime.now().microsecondsSinceEpoch}-$rand';
  }
}
