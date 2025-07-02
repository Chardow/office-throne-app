// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionLogAdapter extends TypeAdapter<SessionLog> {
  @override
  final int typeId = 0;

  @override
  SessionLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionLog(
      timestamp: fields[0] as DateTime,
      durationInSeconds: fields[1] as int,
      earnedMoney: fields[2] as double,
      weightInKg: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SessionLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.durationInSeconds)
      ..writeByte(2)
      ..write(obj.earnedMoney)
      ..writeByte(3)
      ..write(obj.weightInKg);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
