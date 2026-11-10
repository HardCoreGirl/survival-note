// GENERATED CODE - Hive TypeAdapter & JSON Serialization for InspectionCheck

part of 'inspection_check.dart';

class InspectionCheckAdapter extends TypeAdapter<InspectionCheck> {
  @override
  final int typeId = 2;

  @override
  InspectionCheck read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InspectionCheck(
      lastInspectedAt: fields[0] as DateTime,
      cycleMonths: fields[1] as int? ?? 6,
    );
  }

  @override
  void write(BinaryWriter writer, InspectionCheck obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.lastInspectedAt)
      ..writeByte(1)
      ..write(obj.cycleMonths);
  }
}

InspectionCheck _$InspectionCheckFromJson(Map<String, dynamic> json) =>
    InspectionCheck(
      lastInspectedAt: DateTime.parse(json['lastInspectedAt'] as String),
      cycleMonths: json['cycleMonths'] as int? ?? 6,
    );

Map<String, dynamic> _$InspectionCheckToJson(InspectionCheck instance) =>
    <String, dynamic>{
      'lastInspectedAt': instance.lastInspectedAt.toIso8601String(),
      'cycleMonths': instance.cycleMonths,
    };
