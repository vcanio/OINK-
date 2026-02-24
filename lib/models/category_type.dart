import 'package:hive/hive.dart';

part 'category_type.g.dart';

@HiveType(typeId: 3)
enum CategoryType {
  @HiveField(0)
  food,
  @HiveField(1)
  transport,
  @HiveField(2)
  entertainment,
  @HiveField(3)
  health,
  @HiveField(4)
  education,
  @HiveField(5)
  home,
  @HiveField(6)
  clothing,
  @HiveField(7)
  services,
  @HiveField(8)
  savings,
  @HiveField(9)
  giftExpense,
  @HiveField(10)
  otherExpense,
  @HiveField(11)
  salary,
  @HiveField(12)
  freelance,
  @HiveField(13)
  giftIncome,
  @HiveField(14)
  otherIncome,
}
