// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionModelAdapter extends TypeAdapter<SubscriptionModel> {
  @override
  final typeId = 1;

  @override
  SubscriptionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionModel(
      id: fields[0] as String,
      name: fields[1] as String,
      url: fields[2] as String,
      userAgent: fields[3] == null ? '' : fields[3] as String,
      uploadBytes: (fields[6] as num?)?.toInt(),
      downloadBytes: (fields[7] as num?)?.toInt(),
      totalBytes: (fields[8] as num?)?.toInt(),
      expireMillis: (fields[9] as num?)?.toInt(),
      lastUpdatedMillis: (fields[15] as num).toInt(),
      addedAtMillis: (fields[16] as num).toInt(),
      autoUpdate: fields[17] == null ? true : fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.userAgent)
      ..writeByte(6)
      ..write(obj.uploadBytes)
      ..writeByte(7)
      ..write(obj.downloadBytes)
      ..writeByte(8)
      ..write(obj.totalBytes)
      ..writeByte(9)
      ..write(obj.expireMillis)
      ..writeByte(15)
      ..write(obj.lastUpdatedMillis)
      ..writeByte(16)
      ..write(obj.addedAtMillis)
      ..writeByte(17)
      ..write(obj.autoUpdate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
