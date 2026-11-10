import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inspection_check.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class InspectionCheck {
  @HiveField(0)
  final DateTime lastInspectedAt;

  @HiveField(1)
  final int cycleMonths;

  InspectionCheck({
    required this.lastInspectedAt,
    this.cycleMonths = 6,
  });

  DateTime get nextInspectionDate => DateTime(
        lastInspectedAt.year,
        lastInspectedAt.month + cycleMonths,
        lastInspectedAt.day,
      );

  int daysRemaining(DateTime now) {
    return nextInspectionDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  InspectionCheck completeInspection(DateTime now) {
    return InspectionCheck(
      lastInspectedAt: now,
      cycleMonths: cycleMonths,
    );
  }

  factory InspectionCheck.fromJson(Map<String, dynamic> json) =>
      _$InspectionCheckFromJson(json);
  Map<String, dynamic> toJson() => _$InspectionCheckToJson(this);
}
