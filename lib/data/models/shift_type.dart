import 'package:hive_ce/hive.dart';

part 'shift_type.g.dart';

@HiveType(typeId: 0)
enum ShiftType {
  @HiveField(0)
  day,
  @HiveField(1)
  night,
  @HiveField(2)
  afternoon,
  @HiveField(3)
  off,
}
