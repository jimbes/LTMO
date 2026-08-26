// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treatment_cycle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TreatmentCycleAdapter extends TypeAdapter<TreatmentCycle> {
  @override
  final int typeId = 9;

  @override
  TreatmentCycle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TreatmentCycle(
      id: fields[0] as String,
      coupleId: fields[1] as String,
      cycleNumber: fields[2] as int,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime?,
      status: fields[5] as String,
      notes: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TreatmentCycle obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.coupleId)
      ..writeByte(2)
      ..write(obj.cycleNumber)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreatmentCycleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
