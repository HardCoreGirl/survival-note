import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

@HiveType(typeId: 0)
@JsonEnum()
enum SurvivalMode {
  @HiveField(0)
  survivalBag, // 72h Evacuation

  @HiveField(1)
  shelterInPlace, // 30d Isolation
}

class SurvivalModeAdapter extends TypeAdapter<SurvivalMode> {
  @override
  final int typeId = 0;

  @override
  SurvivalMode read(BinaryReader reader) {
    final index = reader.readByte();
    return SurvivalMode.values[index];
  }

  @override
  void write(BinaryWriter writer, SurvivalMode obj) {
    writer.writeByte(obj.index);
  }
}
