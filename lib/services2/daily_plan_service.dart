import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyPlanService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static Future<void> ensureDailyPlanExists() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = _todayKey();

    final planRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('dailyPlans')
        .doc(today);

    final snapshot = await planRef.get();
    if (snapshot.exists) return;

    final userDoc =
    await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) return;

    final nutritionPlan =
    userDoc.data()?['nutritionPlan'] as Map<String, dynamic>?;

    if (nutritionPlan == null) return;

    final dailyCalories = nutritionPlan['dailyCalories'] ?? 1800;

    final meals = _generateMeals(dailyCalories);

    await planRef.set({
      'date': today,
      'completed': false,
      'meals': meals,
    });
  }

  static Map<String, dynamic> _generateMeals(int dailyCalories) {
    final random = Random(DateTime.now().millisecondsSinceEpoch);

    final breakfastCalories = (dailyCalories * 0.25).round();
    final lunchCalories = (dailyCalories * 0.35).round();
    final dinnerCalories = (dailyCalories * 0.30).round();
    final snackCalories = (dailyCalories * 0.10).round();

    final breakfast =
    _pickMeal(_breakfastMeals, breakfastCalories, random);
    final lunch = _pickMeal(_lunchMeals, lunchCalories, random);
    final dinner = _pickMeal(_dinnerMeals, dinnerCalories, random);
    final snack = _pickMeal(_snackMeals, snackCalories, random);

    return {
      'breakfast': _mealToMap(breakfast),
      'lunch': _mealToMap(lunch),
      'dinner': _mealToMap(dinner),
      'snacks': _mealToMap(snack),
    };
  }
  static Map<String, dynamic> _mealToMap(Meal meal) {
    return {
      'name': meal.name,
      'calories': meal.calories,
      'protein': meal.protein,
      'carbs': meal.carbs,
      'fat': meal.fat,
      'logged': false,
    };
  }

  static Meal _pickMeal(
      List<Meal> meals, int targetCalories, Random random) {
    final filtered = meals
        .where((m) =>
    (m.calories - targetCalories).abs() <= targetCalories * 0.2)
        .toList();

    if (filtered.isEmpty) {
      return meals[random.nextInt(meals.length)];
    }

    return filtered[random.nextInt(filtered.length)];
  }

  static String _todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
}

class Meal {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  Meal({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

final List<Meal> _breakfastMeals = [
  Meal(name: "Oatmeal with Banana", calories: 350, protein: 18, carbs: 45, fat: 10),
  Meal(name: "Eggs & Toast", calories: 400, protein: 25, carbs: 30, fat: 15),
  Meal(name: "Greek Yogurt & Berries", calories: 300, protein: 20, carbs: 25, fat: 8),
];

final List<Meal> _lunchMeals = [
  Meal(name: "Grilled Chicken & Rice", calories: 550, protein: 40, carbs: 60, fat: 15),
  Meal(name: "Beef Pasta", calories: 600, protein: 35, carbs: 65, fat: 18),
  Meal(name: "Tuna Salad", calories: 500, protein: 30, carbs: 40, fat: 20),
];

final List<Meal> _dinnerMeals = [
  Meal(name: "Salmon & Veggies", calories: 450, protein: 35, carbs: 30, fat: 18),
  Meal(name: "Chicken Stir Fry", calories: 480, protein: 38, carbs: 35, fat: 14),
  Meal(name: "Turkey & Potatoes", calories: 520, protein: 40, carbs: 45, fat: 12),
];

final List<Meal> _snackMeals = [
  Meal(name: "Protein Bar", calories: 180, protein: 15, carbs: 20, fat: 5),
  Meal(name: "Apple & Peanut Butter", calories: 200, protein: 6, carbs: 25, fat: 9),
  Meal(name: "Greek Yogurt", calories: 150, protein: 12, carbs: 10, fat: 5),
];
