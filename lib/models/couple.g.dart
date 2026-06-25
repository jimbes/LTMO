// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'couple.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CoupleAdapter extends TypeAdapter<Couple> {
  @override
  final int typeId = 1;

  @override
  Couple read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Couple(
      id: fields[0] as String,
      user1Id: fields[1] as String,
      user2Id: fields[2] as String?,
      sharingSettings: (fields[3] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Couple obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.user1Id)
      ..writeByte(2)
      ..write(obj.user2Id)
      ..writeByte(3)
      ..write(obj.sharingSettings)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoupleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
