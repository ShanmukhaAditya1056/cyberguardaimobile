// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wifi_scan_model.dart';

class WifiScanModelAdapter extends TypeAdapter<WifiScanModel> {
  @override
  final int typeId = 2;

  @override
  WifiScanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WifiScanModel(
      ssid: fields[0] as String,
      bssid: fields[1] as String,
      rssi: fields[2] as int,
      trustScore: fields[3] as int,
      riskLevel: fields[4] as String,
      checks: (fields[5] as List).cast<String>(),
      timestamp: fields[6] as DateTime,
      ipAddress: fields[7] as String,
      frequency: fields[8] as int,
      linkSpeed: fields[9] as int,
      isEncrypted: fields[10] as bool? ?? true,
      dnsHealthy: fields[11] as bool? ?? true,
      latencyMs: fields[12] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, WifiScanModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.ssid)
      ..writeByte(1)
      ..write(obj.bssid)
      ..writeByte(2)
      ..write(obj.rssi)
      ..writeByte(3)
      ..write(obj.trustScore)
      ..writeByte(4)
      ..write(obj.riskLevel)
      ..writeByte(5)
      ..write(obj.checks)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.ipAddress)
      ..writeByte(8)
      ..write(obj.frequency)
      ..writeByte(9)
      ..write(obj.linkSpeed)
      ..writeByte(10)
      ..write(obj.isEncrypted)
      ..writeByte(11)
      ..write(obj.dnsHealthy)
      ..writeByte(12)
      ..write(obj.latencyMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WifiScanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
