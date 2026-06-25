// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_stage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JourneyStageAdapter extends TypeAdapter<JourneyStage> {
  @override
  final int typeId = 6;

  @override
  JourneyStage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JourneyStage(
      id: fields[0] as String,
      coupleId: fields[1] as String,
      type: fields[2] as String,
      startDate: fields[3] as DateTime,
      startTime: fields[4] as DateTime?,
      status: fields[5] as String,
      reminderEnabled: fields[6] as bool,
      notes: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, JourneyStage obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.coupleId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.reminderEnabled)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyStageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
