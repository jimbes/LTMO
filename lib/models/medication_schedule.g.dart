// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationScheduleAdapter extends TypeAdapter<MedicationSchedule> {
  @override
  final int typeId = 3;

  @override
  MedicationSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationSchedule(
      id: fields[0] as String,
      medicationId: fields[1] as String,
      coupleId: fields[2] as String,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime?,
      frequency: fields[5] as String,
      daysOfWeek: (fields[6] as List?)?.cast<int>(),
      reminderTimes: (fields[7] as List).cast<String>(),
      reminderOffsets: (fields[8] as List).cast<int>(),
      notifyUser1: fields[9] as bool,
      notifyUser2: fields[10] as bool,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      journeyStageId: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationSchedule obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicationId)
      ..writeByte(2)
      ..write(obj.coupleId)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(13)
      ..write(obj.journeyStageId)
      ..writeByte(5)
      ..write(obj.frequency)
      ..writeByte(6)
      ..write(obj.daysOfWeek)
      ..writeByte(7)
      ..write(obj.reminderTimes)
      ..writeByte(8)
      ..write(obj.reminderOffsets)
      ..writeByte(9)
      ..write(obj.notifyUser1)
      ..writeByte(10)
      ..write(obj.notifyUser2)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
