// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preference.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationPreferenceAdapter
    extends TypeAdapter<NotificationPreference> {
  @override
  final int typeId = 8;

  @override
  NotificationPreference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationPreference(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as String,
      channel: fields[3] as String,
      enabled: fields[4] as bool,
      reminderMinutesBefore: fields[5] as int,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationPreference obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.channel)
      ..writeByte(4)
      ..write(obj.enabled)
      ..writeByte(5)
      ..write(obj.reminderMinutesBefore)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
