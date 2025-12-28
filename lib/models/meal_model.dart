import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String mealType; // breakfast, lunch, dinner, snacks
  final DateTime date;

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'mealType': mealType,
      'date': date,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      name: map['name'],
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      mealType: map['mealType'],
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}