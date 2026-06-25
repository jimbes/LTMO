// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practitioner.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PractitionerAdapter extends TypeAdapter<Practitioner> {
  @override
  final int typeId = 7;

  @override
  Practitioner read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Practitioner(
      id: fields[0] as String,
      coupleId: fields[1] as String,
      name: fields[2] as String,
      specialty: fields[3] as String?,
      phone: fields[4] as String?,
      email: fields[5] as String?,
      clinicName: fields[6] as String?,
      address: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Practitioner obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.coupleId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.specialty)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.clinicName)
      ..writeByte(7)
      ..write(obj.address)
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
      other is PractitionerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
