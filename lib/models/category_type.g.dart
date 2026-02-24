// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryTypeAdapter extends TypeAdapter<CategoryType> {
  @override
  final int typeId = 3;

  @override
  CategoryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CategoryType.food;
      case 1:
        return CategoryType.transport;
      case 2:
        return CategoryType.entertainment;
      case 3:
        return CategoryType.health;
      case 4:
        return CategoryType.education;
      case 5:
        return CategoryType.home;
      case 6:
        return CategoryType.clothing;
      case 7:
        return CategoryType.services;
      case 8:
        return CategoryType.savings;
      case 9:
        return CategoryType.giftExpense;
      case 10:
        return CategoryType.otherExpense;
      case 11:
        return CategoryType.salary;
      case 12:
        return CategoryType.freelance;
      case 13:
        return CategoryType.giftIncome;
      case 14:
        return CategoryType.otherIncome;
      default:
        return CategoryType.food;
    }
  }

  @override
  void write(BinaryWriter writer, CategoryType obj) {
    switch (obj) {
      case CategoryType.food:
        writer.writeByte(0);
        break;
      case CategoryType.transport:
        writer.writeByte(1);
        break;
      case CategoryType.entertainment:
        writer.writeByte(2);
        break;
      case CategoryType.health:
        writer.writeByte(3);
        break;
      case CategoryType.education:
        writer.writeByte(4);
        break;
      case CategoryType.home:
        writer.writeByte(5);
        break;
      case CategoryType.clothing:
        writer.writeByte(6);
        break;
      case CategoryType.services:
        writer.writeByte(7);
        break;
      case CategoryType.savings:
        writer.writeByte(8);
        break;
      case CategoryType.giftExpense:
        writer.writeByte(9);
        break;
      case CategoryType.otherExpense:
        writer.writeByte(10);
        break;
      case CategoryType.salary:
        writer.writeByte(11);
        break;
      case CategoryType.freelance:
        writer.writeByte(12);
        break;
      case CategoryType.giftIncome:
        writer.writeByte(13);
        break;
      case CategoryType.otherIncome:
        writer.writeByte(14);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
