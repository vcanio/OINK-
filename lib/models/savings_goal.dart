import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime startDate;
  final DateTime endDate;
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

class SavingsGoalAdapter extends TypeAdapter<SavingsGoal> {
  @override
  final int typeId = 1;

  @override
  SavingsGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsGoal(
      id: fields[0] as String,
      name: fields[1] as String,
      targetAmount: fields[2] as double,
      savedAmount: fields[3] as double,
      startDate: fields[4] as DateTime,
      endDate: fields[5] as DateTime,
      color: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsGoal obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.savedAmount)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.color);
  }
}
