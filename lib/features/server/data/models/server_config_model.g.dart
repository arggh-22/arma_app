// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_config_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServerConfigModelAdapter extends TypeAdapter<ServerConfigModel> {
  @override
  final typeId = 0;

  @override
  ServerConfigModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServerConfigModel(
      id: fields[0] as String,
      name: fields[1] as String,
      protocolIndex: (fields[2] as num).toInt(),
      address: fields[5] as String,
      port: (fields[6] as num).toInt(),
      uuid: fields[10] as String?,
      password: fields[11] as String?,
      encryption: fields[12] == null ? 'none' : fields[12] as String,
      network: fields[13] == null ? 'tcp' : fields[13] as String,
      security: fields[14] == null ? 'none' : fields[14] as String,
      sni: fields[15] as String?,
      host: fields[20] as String?,
      path: fields[21] as String?,
      alpn: fields[22] as String?,
      fingerprint: fields[23] as String?,
      flow: fields[24] as String?,
      alterId: fields[25] == null ? 0 : (fields[25] as num).toInt(),
      serviceName: fields[30] as String?,
      authority: fields[31] as String?,
      publicKey: fields[32] as String?,
      shortId: fields[33] as String?,
      spiderX: fields[34] as String?,
      method: fields[35] as String?,
      obfs: fields[40] as String?,
      obfsPassword: fields[41] as String?,
      subscriptionId: fields[42] as String?,
      groupName: fields[43] == null ? 'Manual' : fields[43] as String,
      addedAtMillis: (fields[44] as num).toInt(),
      upMbps: (fields[45] as num?)?.toInt(),
      downMbps: (fields[46] as num?)?.toInt(),
      insecure: fields[47] == null ? false : fields[47] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ServerConfigModel obj) {
    writer
      ..writeByte(31)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.protocolIndex)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.port)
      ..writeByte(10)
      ..write(obj.uuid)
      ..writeByte(11)
      ..write(obj.password)
      ..writeByte(12)
      ..write(obj.encryption)
      ..writeByte(13)
      ..write(obj.network)
      ..writeByte(14)
      ..write(obj.security)
      ..writeByte(15)
      ..write(obj.sni)
      ..writeByte(20)
      ..write(obj.host)
      ..writeByte(21)
      ..write(obj.path)
      ..writeByte(22)
      ..write(obj.alpn)
      ..writeByte(23)
      ..write(obj.fingerprint)
      ..writeByte(24)
      ..write(obj.flow)
      ..writeByte(25)
      ..write(obj.alterId)
      ..writeByte(30)
      ..write(obj.serviceName)
      ..writeByte(31)
      ..write(obj.authority)
      ..writeByte(32)
      ..write(obj.publicKey)
      ..writeByte(33)
      ..write(obj.shortId)
      ..writeByte(34)
      ..write(obj.spiderX)
      ..writeByte(35)
      ..write(obj.method)
      ..writeByte(40)
      ..write(obj.obfs)
      ..writeByte(41)
      ..write(obj.obfsPassword)
      ..writeByte(42)
      ..write(obj.subscriptionId)
      ..writeByte(43)
      ..write(obj.groupName)
      ..writeByte(44)
      ..write(obj.addedAtMillis)
      ..writeByte(45)
      ..write(obj.upMbps)
      ..writeByte(46)
      ..write(obj.downMbps)
      ..writeByte(47)
      ..write(obj.insecure);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerConfigModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
