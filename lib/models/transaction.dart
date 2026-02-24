import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'transaction_type.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final String typeString; 
  @HiveField(3)
  final String categoryId;
  @HiveField(4)
  final String description;
  @HiveField(5)
  final DateTime date;
  @HiveField(6)
  final DateTime createdAt;
  @HiveField(7, defaultValue: false)
  final bool isRecurring;
  @HiveField(8, defaultValue: null)
  final String? frequency; // 'monthly', 'weekly', etc.
  @HiveField(9, defaultValue: 'default')
  final String walletId;
  @HiveField(10, defaultValue: null)
  final String? groupId;
  @HiveField(11, defaultValue: null)
  final String? recurrenceId;

  Transaction({
    required this.id,
    required this.amount,
    required this.typeString,
    required this.categoryId,
    this.description = '',
    required this.date,
    required this.createdAt,
    this.isRecurring = false,
    this.frequency,
    this.walletId = 'default',
    this.groupId,
    this.recurrenceId,
  });

  TransactionType get type => typeString == 'income' ? TransactionType.income : TransactionType.expense;

  bool get isExpense => type == TransactionType.expense;

  factory Transaction.create({
    required double amount,
    required TransactionType type,
    required String categoryId,
    String description = '',
    required DateTime date,
    bool isRecurring = false,
    String? frequency,
    String walletId = 'default',
    String? groupId,
    String? recurrenceId,
  }) {
    return Transaction(
      id: const Uuid().v4(),
      amount: amount,
      typeString: type.name,
      categoryId: categoryId,
      description: description,
      date: date,
      createdAt: DateTime.now(),
      isRecurring: isRecurring,
      frequency: frequency,
      walletId: walletId,
      groupId: groupId,
      recurrenceId: recurrenceId,
    );
  }
}
