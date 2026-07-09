// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_taken_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationTakenLogAdapter extends TypeAdapter<MedicationTakenLog> {
  @override
  final int typeId = 4;

  @override
  MedicationTakenLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationTakenLog(
      id: fields[0] as String,
      medicationScheduleId: fields[1] as String,
      date: fields[2] as DateTime,
      taken: fields[3] as bool,
      takenAt: fields[4] as DateTime?,
      userLoggedById: fields[5] as String?,
      notes: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      time: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationTakenLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicationScheduleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.taken)
      ..writeByte(4)
      ..write(obj.takenAt)
      ..writeByte(5)
      ..write(obj.userLoggedById)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.time);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationTakenLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
