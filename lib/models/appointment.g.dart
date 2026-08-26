// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppointmentAdapter extends TypeAdapter<Appointment> {
  @override
  final int typeId = 5;

  @override
  Appointment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Appointment(
      id: fields[0] as String,
      coupleId: fields[1] as String,
      title: fields[2] as String,
      appointmentDate: fields[3] as DateTime,
      appointmentTime: fields[4] as DateTime?,
      location: fields[5] as String?,
      doctorName: fields[6] as String?,
      description: fields[7] as String?,
      type: fields[8] as String?,
      notifyUser1: fields[9] as bool,
      notifyUser2: fields[10] as bool,
      completed: fields[11] as bool,
      reminderOffsets: (fields[12] as List).cast<int>(),
      createdAt: fields[13] as DateTime,
      updatedAt: fields[14] as DateTime,
      journeyStageId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Appointment obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.coupleId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.appointmentDate)
      ..writeByte(4)
      ..write(obj.appointmentTime)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.doctorName)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.type)
      ..writeByte(9)
      ..write(obj.notifyUser1)
      ..writeByte(10)
      ..write(obj.notifyUser2)
      ..writeByte(11)
      ..write(obj.completed)
      ..writeByte(12)
      ..write(obj.reminderOffsets)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.journeyStageId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
