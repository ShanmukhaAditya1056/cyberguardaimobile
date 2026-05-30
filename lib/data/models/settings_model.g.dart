// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 4;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      realTimeAlerts: fields[0] as bool? ?? true,
      clipboardScan: fields[1] as bool? ?? true,
      autoScanFrequency: fields[2] as String? ?? 'Weekly',
      wifiAutoScan: fields[3] as bool? ?? true,
      hibpApiKey: fields[4] as String? ?? '',
      language: fields[5] as String? ?? 'English',
      onboardingComplete: fields[6] as bool? ?? false,
      lastScanDate: fields[7] as DateTime?,
      phishingScore: fields[8] as int? ?? 85,
      malwareScore: fields[9] as int? ?? 85,
      breachScore: fields[10] as int? ?? 85,
      wifiScore: fields[11] as int? ?? 85,
      hasActiveBreach: fields[12] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.realTimeAlerts)
      ..writeByte(1)
      ..write(obj.clipboardScan)
      ..writeByte(2)
      ..write(obj.autoScanFrequency)
      ..writeByte(3)
      ..write(obj.wifiAutoScan)
      ..writeByte(4)
      ..write(obj.hibpApiKey)
      ..writeByte(5)
      ..write(obj.language)
      ..writeByte(6)
      ..write(obj.onboardingComplete)
      ..writeByte(7)
      ..write(obj.lastScanDate)
      ..writeByte(8)
      ..write(obj.phishingScore)
      ..writeByte(9)
      ..write(obj.malwareScore)
      ..writeByte(10)
      ..write(obj.breachScore)
      ..writeByte(11)
      ..write(obj.wifiScore)
      ..writeByte(12)
      ..write(obj.hasActiveBreach);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
