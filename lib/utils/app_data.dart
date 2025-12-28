import '../models/meal_model.dart';

class AppData {
  // السعرات
  static double todayTotalCalories = 0;

  // الماكروز
  static double todayTotalProtein = 0;
  static double todayTotalCarbs = 0;
  static double todayTotalFat = 0;

  // الوجبات
  static List<Meal> todayMeals = [];

  // ⭐⭐ دالة لحساب السعرات المتبقية ⭐⭐
  static double getRemainingCalories(double dailyGoal) {
    double remaining = dailyGoal - todayTotalCalories;
    return remaining > 0 ? remaining : 0;
  }

  // دالة محسنة لإضافة وجبة
  static void addMeal(Meal meal) {
    todayMeals.add(meal);
    todayTotalCalories += meal.calories;
    todayTotalProtein += meal.protein;
    todayTotalCarbs += meal.carbs;
    todayTotalFat += meal.fat;

    print('✅ AppData: Added ${meal.name}');
  }

  // دالة للحصول على الماكروز
  static Map<String, double> getMacros() {
    return {
      'protein': todayTotalProtein,
      'carbs': todayTotalCarbs,
      'fat': todayTotalFat,
    };
  }

  // دالة لحساب نسب الماكروز
  static Map<String, double> getMacroPercentages() {
    Map<String, double> percentages = {'protein': 0, 'carbs': 0, 'fat': 0};

    if (todayTotalCalories > 0) {
      percentages['protein'] = (todayTotalProtein * 4 / todayTotalCalories * 100);
      percentages['carbs'] = (todayTotalCarbs * 4 / todayTotalCalories * 100);
      percentages['fat'] = (todayTotalFat * 9 / todayTotalCalories * 100);

      // تأكد أن المجموع 100%
      double total = percentages.values.reduce((a, b) => a + b);
      if (total > 0) {
        percentages['protein'] = (percentages['protein']! / total * 100);
        percentages['carbs'] = (percentages['carbs']! / total * 100);
        percentages['fat'] = (percentages['fat']! / total * 100);
      }
    }

    return percentages;
  }

  static void reset() {
    todayTotalCalories = 0;
    todayTotalProtein = 0;
    todayTotalCarbs = 0;
    todayTotalFat = 0;
    todayMeals.clear();
  }
}