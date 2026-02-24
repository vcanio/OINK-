import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'savings_goal.g.dart';

@HiveType(typeId: 1)
class SavingsGoal {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double targetAmount;
  @HiveField(3)
  final double savedAmount;
  @HiveField(4)
  final DateTime startDate;
  @HiveField(5)
  final DateTime endDate;
  @HiveField(6)
  final int color;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.startDate,
    required this.endDate,
    required this.color,
  });

  factory SavingsGoal.create({
    required String name,
    required double targetAmount,
    required DateTime startDate,
    required DateTime endDate,
    required int color,
  }) {
    return SavingsGoal(
      id: const Uuid().v4(),
      name: name,
      targetAmount: targetAmount,
      savedAmount: 0.0,
      startDate: startDate,
      endDate: endDate,
      color: color,
    );
  }
    
    SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? startDate,
    DateTime? endDate,
    int? color,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
    );
  }
}
