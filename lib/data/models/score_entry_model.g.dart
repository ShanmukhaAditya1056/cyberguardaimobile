// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_entry_model.dart';

class ScoreEntryModelAdapter extends TypeAdapter<ScoreEntryModel> {
  @override
  final int typeId = 3;

  @override
  ScoreEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreEntryModel(
      date: fields[0] as DateTime,
      unifiedScore: fields[1] as int,
      phishingScore: fields[2] as int,
      malwareScore: fields[3] as int,
      breachScore: fields[4] as int,
      wifiScore: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreEntryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.unifiedScore)
      ..writeByte(2)
      ..write(obj.phishingScore)
      ..writeByte(3)
      ..write(obj.malwareScore)
      ..writeByte(4)
      ..write(obj.breachScore)
      ..writeByte(5)
      ..write(obj.wifiScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
