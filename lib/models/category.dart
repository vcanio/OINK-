import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'category_type.dart';
import 'transaction_type.dart';

part 'category.g.dart';

@HiveType(typeId: 4)
class Category {
  @HiveField(0)
  final String id; 
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int iconCodePoint; 
  @HiveField(3)
  final int colorValue; 
  @HiveField(4)
  final String typeString;

  const Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.typeString,
  });
  
  static final Map<int, IconData> _iconMap = {
    Icons.category_rounded.codePoint: Icons.category_rounded,
    Icons.shopping_bag_rounded.codePoint: Icons.shopping_bag_rounded,
    Icons.flight_rounded.codePoint: Icons.flight_rounded,
    Icons.pets_rounded.codePoint: Icons.pets_rounded,
    Icons.directions_car_rounded.codePoint: Icons.directions_car_rounded,
    Icons.local_dining_rounded.codePoint: Icons.local_dining_rounded,
    Icons.local_cafe_rounded.codePoint: Icons.local_cafe_rounded,
    Icons.fitness_center_rounded.codePoint: Icons.fitness_center_rounded,
    Icons.movie_rounded.codePoint: Icons.movie_rounded,
    Icons.child_care_rounded.codePoint: Icons.child_care_rounded,
    Icons.house_rounded.codePoint: Icons.house_rounded,
    Icons.water_drop_rounded.codePoint: Icons.water_drop_rounded,
    Icons.electric_bolt_rounded.codePoint: Icons.electric_bolt_rounded,
    Icons.wifi_rounded.codePoint: Icons.wifi_rounded,
    Icons.phone_android_rounded.codePoint: Icons.phone_android_rounded,
    Icons.laptop_chromebook_rounded.codePoint: Icons.laptop_chromebook_rounded,
    Icons.menu_book_rounded.codePoint: Icons.menu_book_rounded,
    Icons.palette_rounded.codePoint: Icons.palette_rounded,
    Icons.music_note_rounded.codePoint: Icons.music_note_rounded,
    Icons.medication_rounded.codePoint: Icons.medication_rounded,
    Icons.card_giftcard_rounded.codePoint: Icons.card_giftcard_rounded,
    Icons.fastfood_rounded.codePoint: Icons.fastfood_rounded,
    Icons.directions_bus_rounded.codePoint: Icons.directions_bus_rounded,
    Icons.sports_esports_rounded.codePoint: Icons.sports_esports_rounded,
    Icons.medical_services_rounded.codePoint: Icons.medical_services_rounded,
    Icons.school_rounded.codePoint: Icons.school_rounded,
    Icons.checkroom_rounded.codePoint: Icons.checkroom_rounded,
    Icons.receipt_long_rounded.codePoint: Icons.receipt_long_rounded,
    Icons.savings_rounded.codePoint: Icons.savings_rounded,
    Icons.inventory_2_rounded.codePoint: Icons.inventory_2_rounded,
    Icons.monetization_on_rounded.codePoint: Icons.monetization_on_rounded,
    Icons.computer_rounded.codePoint: Icons.computer_rounded,
    Icons.auto_awesome_rounded.codePoint: Icons.auto_awesome_rounded,
  };

  // Helpers
  IconData get icon => _iconMap[iconCodePoint] ?? Icons.category_rounded;
  int get color => colorValue;
  TransactionType get type => typeString == 'income' ? TransactionType.income : TransactionType.expense;

  // For dynamic creation
  factory Category.create({
    required String name,
    required IconData icon,
    required Color color,
    required TransactionType type,
  }) {
    return Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Time-based unique ID
      name: name,
      iconCodePoint: icon.codePoint,
      colorValue: color.value,
      typeString: type.name,
    );
  }
}

// Predefined categories (using the enum names as string IDs for backward compatibility)
final List<Category> defaultCategories = [
  // Expenses
  Category(id: CategoryType.food.name, name: 'Alimentación', iconCodePoint: Icons.fastfood_rounded.codePoint, colorValue: 0xFFFF9800, typeString: 'expense'),
  Category(id: CategoryType.transport.name, name: 'Transporte', iconCodePoint: Icons.directions_bus_rounded.codePoint, colorValue: 0xFF2196F3, typeString: 'expense'),
  Category(id: CategoryType.entertainment.name, name: 'Diversión', iconCodePoint: Icons.sports_esports_rounded.codePoint, colorValue: 0xFF9C27B0, typeString: 'expense'),
  Category(id: CategoryType.health.name, name: 'Salud', iconCodePoint: Icons.medical_services_rounded.codePoint, colorValue: 0xFFF44336, typeString: 'expense'),
  Category(id: CategoryType.education.name, name: 'Educación', iconCodePoint: Icons.school_rounded.codePoint, colorValue: 0xFF4CAF50, typeString: 'expense'),
  Category(id: CategoryType.home.name, name: 'Hogar', iconCodePoint: Icons.home_rounded.codePoint, colorValue: 0xFF795548, typeString: 'expense'),
  Category(id: CategoryType.clothing.name, name: 'Ropa', iconCodePoint: Icons.checkroom_rounded.codePoint, colorValue: 0xFFE91E63, typeString: 'expense'),
  Category(id: CategoryType.services.name, name: 'Servicios', iconCodePoint: Icons.receipt_long_rounded.codePoint, colorValue: 0xFF00BCD4, typeString: 'expense'),
  Category(id: CategoryType.savings.name, name: 'Ahorro', iconCodePoint: Icons.savings_rounded.codePoint, colorValue: 0xFF26A69A, typeString: 'expense'),
  Category(id: CategoryType.giftExpense.name, name: 'Regalos', iconCodePoint: Icons.card_giftcard_rounded.codePoint, colorValue: 0xFFE91E63, typeString: 'expense'),
  Category(id: CategoryType.otherExpense.name, name: 'Otros', iconCodePoint: Icons.inventory_2_rounded.codePoint, colorValue: 0xFF607D8B, typeString: 'expense'),
  
  // Income
  Category(id: CategoryType.salary.name, name: 'Sueldo', iconCodePoint: Icons.monetization_on_rounded.codePoint, colorValue: 0xFF4CAF50, typeString: 'income'),
  Category(id: CategoryType.freelance.name, name: 'Freelance', iconCodePoint: Icons.computer_rounded.codePoint, colorValue: 0xFF2196F3, typeString: 'income'),
  Category(id: CategoryType.giftIncome.name, name: 'Regalo', iconCodePoint: Icons.card_giftcard_rounded.codePoint, colorValue: 0xFFE91E63, typeString: 'income'),
  Category(id: CategoryType.otherIncome.name, name: 'Otros', iconCodePoint: Icons.auto_awesome_rounded.codePoint, colorValue: 0xFF26A69A, typeString: 'income'),
];
