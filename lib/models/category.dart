import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String icon; // Emoji
  final int color; // Color int value
  final String type; // 'income' or 'expense'

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });
}

// Predefined categories
final List<Category> defaultCategories = [
  // Expenses
  const Category(id: 'food', name: 'Alimentación', icon: '🍔', color: 0xFFFF9800, type: 'expense'),
  const Category(id: 'transport', name: 'Transporte', icon: '🚌', color: 0xFF2196F3, type: 'expense'),
  const Category(id: 'entertainment', name: 'Diversión', icon: '🎮', color: 0xFF9C27B0, type: 'expense'),
  const Category(id: 'health', name: 'Salud', icon: '💊', color: 0xFFF44336, type: 'expense'),
  const Category(id: 'education', name: 'Educación', icon: '📚', color: 0xFF4CAF50, type: 'expense'),
  const Category(id: 'home', name: 'Hogar', icon: '🏠', color: 0xFF795548, type: 'expense'),
  const Category(id: 'clothing', name: 'Ropa', icon: '👕', color: 0xFFE91E63, type: 'expense'),
  const Category(id: 'services', name: 'Servicios', icon: '📱', color: 0xFF00BCD4, type: 'expense'),
  const Category(id: 'savings', name: 'Ahorro', icon: '🐷', color: 0xFFFFC107, type: 'expense'),
  const Category(id: 'gift_expense', name: 'Regalos', icon: '🎁', color: 0xFFE91E63, type: 'expense'),
  const Category(id: 'other_expense', name: 'Otros', icon: '📦', color: 0xFF607D8B, type: 'expense'),
  
  // Income
  const Category(id: 'salary', name: 'Sueldo', icon: '💰', color: 0xFF4CAF50, type: 'income'),
  const Category(id: 'freelance', name: 'Freelance', icon: '💻', color: 0xFF2196F3, type: 'income'),
  const Category(id: 'gift', name: 'Regalo', icon: '🎁', color: 0xFFE91E63, type: 'income'),
  const Category(id: 'other_income', name: 'Otros', icon: '✨', color: 0xFFFFC107, type: 'income'),
];
