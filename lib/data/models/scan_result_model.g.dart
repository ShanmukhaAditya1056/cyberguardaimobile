// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_result_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanResultModelAdapter extends TypeAdapter<ScanResultModel> {
  @override
  final int typeId = 0;

  @override
  ScanResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanResultModel(
      id: fields[0] as String,
      type: fields[1] as String,
      input: fields[2] as String,
      verdict: fields[3] as String,
      confidence: fields[4] as int,
      shapReasons: (fields[5] as List).cast<String>(),
      timestamp: fields[6] as DateTime,
      isRead: fields[7] as bool,
      extraData: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanResultModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.input)
      ..writeByte(3)
      ..write(obj.verdict)
      ..writeByte(4)
      ..write(obj.confidence)
      ..writeByte(5)
      ..write(obj.shapReasons)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.isRead)
      ..writeByte(8)
      ..write(obj.extraData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppScanModelAdapter extends TypeAdapter<AppScanModel> {
  @override
  final int typeId = 5;

  @override
  AppScanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppScanModel(
      packageName: fields[0] as String,
      appName: fields[1] as String,
      riskScore: fields[2] as int,
      riskLevel: fields[3] as String,
      dangerousPermissions: (fields[4] as List).cast<String>(),
      shapReasons: (fields[5] as List).cast<String>(),
      scannedAt: fields[6] as DateTime,
      permissionCount: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AppScanModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.appName)
      ..writeByte(2)
      ..write(obj.riskScore)
      ..writeByte(3)
      ..write(obj.riskLevel)
      ..writeByte(4)
      ..write(obj.dangerousPermissions)
      ..writeByte(5)
      ..write(obj.shapReasons)
      ..writeByte(6)
      ..write(obj.scannedAt)
      ..writeByte(7)
      ..write(obj.permissionCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppScanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
