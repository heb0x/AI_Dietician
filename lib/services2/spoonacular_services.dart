import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SpoonacularService {
  static const String _apiKey = '558c001b97564f3c858915bcb3ce1fb5';
  static const String _baseUrl ='https://api.spoonacular.com/mealplanner/generate';

  static Future<List<Map<String, dynamic>>> generateDailyMealPlan({
    required double dailyCalories,
    required String goal,
    required String dietType,
    required List<String> dietaryRestrictions,
    required int mealsPerDay,
    required String cuisinePreference,
  }) async {
    String exclude = dietaryRestrictions.join(',');

    final uri = Uri.parse(
      '$_baseUrl'
          '?timeFrame=day'
          '&targetCalories=${dailyCalories.round()}'
          '&diet=$dietType'
          '&exclude=$exclude'
          '&numMeals=$mealsPerDay'
          '&apiKey=$_apiKey',


    );

    final response = await  http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Spoonacular API error: ${response.body}');
    }

    final data = json.decode(response.body);
    final meals = data['meals'] as List<dynamic>;
    final nutrients = data['nutrients'];
    final caloriesPerMeal = (nutrients['calories'] as num).toDouble() / meals.length;
    final proteinPerMeal = (nutrients['protein'] as num).toDouble() / meals.length;
    final carbsPerMeal = (nutrients['carbohydrates'] as num).toDouble() / meals.length;
    final fatPerMeal = (nutrients['fat'] as num).toDouble() / meals.length;

    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    return meals.asMap().entries.map((entry) {
      final index = entry.key;
      final meal = entry.value;

      return {
        'id': meal['id'],
        'mealType': index < mealTypes.length ? mealTypes[index] : 'Meal ${index + 1}',
        'name': meal['title'],
        'description': 'AI-generated ${dietType} meal tailored to your ${goal} goal',
        'calories': caloriesPerMeal,
        'protein': proteinPerMeal,
        'carbs': carbsPerMeal,
        'fat': fatPerMeal,
        'ingredients': <String>[],
        'preparationTime': '${meal['readyInMinutes']} mins',
        'difficulty': 'Medium',
        'source': 'Spoonacular',
        'sourceId': meal['id'].toString(),
        'imageUrl': 'https://spoonacular.com/recipeImages/${meal['id']}-556x370.jpg',
        'readyInMinutes': meal['readyInMinutes'],
        'servings': meal['servings'],
        'smartNote': _goalNote(goal),
      };
    }).toList();
  }
  static Future<void> saveGeneratedMealsToFirebase(List<Map<String, dynamic>> meals) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ai_generated_meals')
        .doc(today)
        .set({
      'meals': meals,
      'createdAt': Timestamp.now(),
      'source': 'Spoonacular',
    });
  }

  static String _goalNote(String goal) {
    switch (goal) {
      case 'lose': return 'Calorie-controlled for weight loss';
      case 'gain': return 'Nutrient-dense for muscle building';
      default: return 'Balanced for health maintenance';
    }
  }
}