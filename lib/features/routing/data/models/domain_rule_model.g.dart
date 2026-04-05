// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_rule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DomainRuleModelAdapter extends TypeAdapter<DomainRuleModel> {
  @override
  final typeId = 2;

  @override
  DomainRuleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DomainRuleModel(
      domain: fields[0] as String,
      actionIndex: (fields[1] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DomainRuleModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.domain)
      ..writeByte(1)
      ..write(obj.actionIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainRuleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
