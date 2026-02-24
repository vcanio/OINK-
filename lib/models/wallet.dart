import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

part 'wallet.g.dart';

@HiveType(typeId: 4)
class Wallet {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  double balance;

  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  final int iconCodePoint;

  // A getter to safely fetch IconData based on the codePoint without breaking tree-shaking
  IconData get iconData {
    // We try to match known icons if they were dynamically assigned.
    // However, the best practice is to always return a const IconData.
    // If we wanted to support more, we can add them to this switch statement.
    if (iconCodePoint == Icons.account_balance_wallet.codePoint) {
      return Icons.account_balance_wallet;
    }
    // Add fallback
    return Icons.account_balance_wallet;
  }

  Wallet({
    required this.id,
    required this.name,
    this.balance = 0.0,
    required this.colorValue,
    required this.iconCodePoint,
  });

  factory Wallet.create({
    required String name,
    double initialBalance = 0.0,
    required int colorValue,
    required int iconCodePoint,
  }) {
    return Wallet(
      id: const Uuid().v4(),
      name: name,
      balance: initialBalance,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
    );
  }
}
