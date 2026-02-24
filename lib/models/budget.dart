import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'budget.g.dart';

@HiveType(typeId: 2)
class Budget {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String categoryId;
  @HiveField(2)
  double amount;
  
  // Opcional: para permitir presupuestos por mes
  // Si year y month son null, es un presupuesto mensual general
  @HiveField(3)
  final int? year;
  @HiveField(4)
  final int? month;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    this.year,
    this.month,
  });

  factory Budget.create({
    required String categoryId,
    required double amount,
    int? year,
    int? month,
  }) {
    return Budget(
      id: const Uuid().v4(),
      categoryId: categoryId,
      amount: amount,
      year: year,
      month: month,
    );
  }
}
