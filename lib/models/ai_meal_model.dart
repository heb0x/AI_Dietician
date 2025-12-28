// // services/ai_meal_service.dart - معدل للاستخدام الفعلي
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
//
// class AIMealService {
//   // احصل على API Key من: https://makersuite.google.com/app/apikey
//   static const String _geminiApiKey = 'AIzaSyA8cvdy__xE3GdRKutokTaRR2a6OSAF3IA'; // مثال
//   static const String _geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
//
//   // دالة حقيقية لتوليد وجبات
//   static Future<List<Map<String, dynamic>>> generateDailyMealPlan({
//     required double dailyCalories,
//     required String goal,
//     required String dietaryPreferences,
//     required int mealsPerDay,
//     required String cuisinePreference,
//   }) async {
//     try {
//       // بناء الـ Prompt بناءً على بيانات المستخدم
//       String prompt = _buildPrompt(
//         dailyCalories: dailyCalories,
//         goal: goal,
//         dietaryPreferences: dietaryPreferences,
//         mealsPerDay: mealsPerDay,
//         cuisinePreference: cuisinePreference,
//       );
//
//       print('🔍 Sending request to Gemini API...');
//       print('📝 Prompt length: ${prompt.length} characters');
//
//       final response = await http.post(
//         Uri.parse('$_geminiUrl?key=$_geminiApiKey'),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           "contents": [
//             {
//               "parts": [
//                 {"text": prompt}
//               ]
//             }
//           ],
//           "generationConfig": {
//             "temperature": 0.7,
//             "topK": 40,
//             "topP": 0.95,
//             "maxOutputTokens": 2048,
//           },
//           "safetySettings": [
//             {
//               "category": "HARM_CATEGORY_HARASSMENT",
//               "threshold": "BLOCK_MEDIUM_AND_ABOVE"
//             },
//             {
//               "category": "HARM_CATEGORY_HATE_SPEECH",
//               "threshold": "BLOCK_MEDIUM_AND_ABOVE"
//             },
//             {
//               "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
//               "threshold": "BLOCK_MEDIUM_AND_ABOVE"
//             },
//             {
//               "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
//               "threshold": "BLOCK_MEDIUM_AND_ABOVE"
//             }
//           ]
//         }),
//       );
//
//       print('📡 Response status: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         print('✅ API Response received');
//
//         if (data['candidates'] != null && data['candidates'].isNotEmpty) {
//           final text = data['candidates'][0]['content']['parts'][0]['text'];
//           print('📄 AI Response text (first 500 chars): ${text.substring(0, text.length > 500 ? 500 : text.length)}...');
//
//           // محاولة استخراج JSON من النص
//           return _parseAIResponse(text);
//         } else {
//           print('❌ No candidates in response');
//           return _getFallbackMeals(dailyCalories, goal, mealsPerDay);
//         }
//       } else {
//         print('❌ API Error: ${response.statusCode} - ${response.body}');
//         return _getFallbackMeals(dailyCalories, goal, mealsPerDay);
//       }
//     } catch (e) {
//       print('❌ Exception in AI service: $e');
//       return _getFallbackMeals(dailyCalories, goal, mealsPerDay);
//     }
//   }
//
//   // بناء الـ Prompt الذكي
//   static String _buildPrompt({
//     required double dailyCalories,
//     required String goal,
//     required String dietaryPreferences,
//     required int mealsPerDay,
//     required String cuisinePreference,
//   }) {
//     String macroDistribution = '';
//
//     if (goal == 'lose') {
//       macroDistribution = '40% carbs, 30% protein, 30% fat for weight loss';
//     } else if (goal == 'gain') {
//       macroDistribution = '50% carbs, 25% protein, 25% fat for weight gain';
//     } else {
//       macroDistribution = '45% carbs, 30% protein, 25% fat for maintenance';
//     }
//
//     return '''
//     IMPORTANT: You are a professional nutritionist and meal planner. Create a personalized daily meal plan in JSON format.
//
//     USER PROFILE:
//     - Daily Calorie Goal: ${dailyCalories} calories
//     - Fitness Goal: ${goal} weight
//     - Dietary Preferences: ${dietaryPreferences}
//     - Meals per day: ${mealsPerDay}
//     - Cuisine Preference: ${cuisinePreference}
//     - Macro Distribution: ${macroDistribution}
//
//     REQUIREMENTS:
//     1. Create exactly $mealsPerDay meals for the day
//     2. Distribute calories evenly: ${(dailyCalories / mealsPerDay).round()} calories per meal on average
//     3. Provide exact nutritional values for each meal
//     4. Make meals realistic, easy to prepare, and affordable
//     5. Include variety in ingredients and cooking methods
//     6. Consider ${dietaryPreferences} restrictions
//     7. Use ${cuisinePreference} cuisine style
//     8. Each meal should include protein, carbs, and healthy fats
//
//     FORMAT: Return a JSON array ONLY with this exact structure for each meal:
//     [
//       {
//         "mealType": "Breakfast",
//         "name": "Creative meal name",
//         "description": "Appetizing description (1-2 sentences)",
//         "calories": number (must be between ${(dailyCalories * 0.2).round()} and ${(dailyCalories * 0.4).round()}),
//         "protein": number (in grams, realistic for the meal),
//         "carbs": number (in grams, realistic for the meal),
//         "fat": number (in grams, realistic for the meal),
//         "ingredients": ["item1", "item2", "item3", "item4", "item5"],
//         "preparationTime": "X-Y minutes",
//         "difficulty": "Easy/Medium/Hard"
//       }
//     ]
//
//     RULES:
//     - Calories per meal should be roughly: ${(dailyCalories / mealsPerDay).round()} calories
//     - Total daily protein: ${(dailyCalories * 0.3 / 4).round()}g
//     - Total daily carbs: ${(dailyCalories * 0.4 / 4).round()}g
//     - Total daily fat: ${(dailyCalories * 0.3 / 9).round()}g
//     - Use common, affordable ingredients
//     - Include vegetables in at least 2 meals
//     - Include lean protein sources
//     - Use healthy cooking methods (grill, bake, steam, stir-fry)
//
//     EXAMPLE MEAL STRUCTURE:
//     - Breakfast: ${(dailyCalories * 0.25).round()} calories
//     - Lunch: ${(dailyCalories * 0.35).round()} calories
//     - Dinner: ${(dailyCalories * 0.30).round()} calories
//     - Snack: ${(dailyCalories * 0.10).round()} calories (if mealsPerDay > 3)
//
//     IMPORTANT: Return ONLY the JSON array. No explanations, no markdown, no additional text.
//     ''';
//   }
//
//   // تحليل استجابة الـ AI
//   static List<Map<String, dynamic>> _parseAIResponse(String text) {
//     try {
//       // تنظيف النص
//       String cleanedText = text.trim();
//
//       // إزالة markdown إذا وجد
//       cleanedText = cleanedText.replaceAll('```json', '').replaceAll('```', '');
//
//       // البحث عن بداية ونهاية JSON
//       int jsonStart = cleanedText.indexOf('[');
//       int jsonEnd = cleanedText.lastIndexOf(']') + 1;
//
//       if (jsonStart != -1 && jsonEnd > jsonStart) {
//         String jsonString = cleanedText.substring(jsonStart, jsonEnd);
//         print('📊 Extracted JSON string: $jsonString');
//
//         List<dynamic> parsed = jsonDecode(jsonString);
//         List<Map<String, dynamic>> meals = List<Map<String, dynamic>>.from(parsed);
//
//         // التحقق من صحة البيانات
//         meals = _validateAndFixMeals(meals);
//
//         print('✅ Successfully parsed ${meals.length} meals from AI');
//         return meals;
//       } else {
//         print('❌ No JSON array found in response');
//         throw FormatException('Invalid AI response format');
//       }
//     } catch (e) {
//       print('❌ Error parsing AI response: $e');
//       // محاولة استخراج البيانات بطريقة أخرى
//       return _extractMealsFromText(text);
//     }
//   }
//
//   // استخراج البيانات من النص بطريقة ذكية
//   static List<Map<String, dynamic>> _extractMealsFromText(String text) {
//     try {
//       List<Map<String, dynamic>> meals = [];
//       List<String> lines = text.split('\n');
//
//       Map<String, dynamic>? currentMeal;
//
//       for (String line in lines) {
//         line = line.trim();
//
//         if (line.contains('mealType') || line.contains('"mealType"')) {
//           if (currentMeal != null) meals.add(currentMeal);
//           currentMeal = {};
//         }
//
//         if (currentMeal != null) {
//           // استخراج البيانات باستخدام regex بسيط
//           if (line.contains('"name"')) {
//             String? value = _extractJsonValue(line, 'name');
//             if (value != null) currentMeal['name'] = value;
//           } else if (line.contains('"mealType"')) {
//             String? value = _extractJsonValue(line, 'mealType');
//             if (value != null) currentMeal['mealType'] = value;
//           } else if (line.contains('"calories"')) {
//             String? value = _extractJsonValue(line, 'calories');
//             if (value != null) currentMeal['calories'] = double.tryParse(value) ?? 0;
//           } else if (line.contains('"protein"')) {
//             String? value = _extractJsonValue(line, 'protein');
//             if (value != null) currentMeal['protein'] = double.tryParse(value) ?? 0;
//           } else if (line.contains('"carbs"')) {
//             String? value = _extractJsonValue(line, 'carbs');
//             if (value != null) currentMeal['carbs'] = double.tryParse(value) ?? 0;
//           } else if (line.contains('"fat"')) {
//             String? value = _extractJsonValue(line, 'fat');
//             if (value != null) currentMeal['fat'] = double.tryParse(value) ?? 0;
//           } else if (line.contains('"description"')) {
//             String? value = _extractJsonValue(line, 'description');
//             if (value != null) currentMeal['description'] = value;
//           }
//         }
//       }
//
//       if (currentMeal != null && currentMeal.isNotEmpty) {
//         meals.add(currentMeal);
//       }
//
//       if (meals.isNotEmpty) {
//         meals = _validateAndFixMeals(meals);
//         return meals;
//       } else {
//         throw FormatException('Could not extract meals from text');
//       }
//     } catch (e) {
//       print('❌ Error extracting meals: $e');
//       return [];
//     }
//   }
//
//   static String? _extractJsonValue(String line, String key) {
//     try {
//       // البحث عن النمط: "key": "value"
//       RegExp regex = RegExp('"$key"\\s*:\\s*"([^"]+)"');
//       Match? match = regex.firstMatch(line);
//       if (match != null) return match.group(1);
//
//       // البحث عن النمط: "key": number
//       regex = RegExp('"$key"\\s*:\\s*(\\d+\\.?\\d*)');
//       match = regex.firstMatch(line);
//       if (match != null) return match.group(1);
//
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }
//
//   // التحقق من صحة البيانات وإصلاحها
//   static List<Map<String, dynamic>> _validateAndFixMeals(List<Map<String, dynamic>> meals) {
//     List<Map<String, dynamic>> fixedMeals = [];
//
//     for (var meal in meals) {
//       Map<String, dynamic> fixedMeal = Map.from(meal);
//
//       // التأكد من وجود جميع الحقول المطلوبة
//       fixedMeal['name'] = fixedMeal['name']?.toString() ?? 'AI Generated Meal';
//       fixedMeal['mealType'] = fixedMeal['mealType']?.toString() ?? 'Lunch';
//       fixedMeal['description'] = fixedMeal['description']?.toString() ?? 'Healthy and delicious meal';
//
//       // التأكد من أن القيم الرقمية صحيحة
//       fixedMeal['calories'] = (fixedMeal['calories'] as num?)?.toDouble() ?? 400.0;
//       fixedMeal['protein'] = (fixedMeal['protein'] as num?)?.toDouble() ?? 25.0;
//       fixedMeal['carbs'] = (fixedMeal['carbs'] as num?)?.toDouble() ?? 45.0;
//       fixedMeal['fat'] = (fixedMeal['fat'] as num?)?.toDouble() ?? 15.0;
//
//       // التأكد من أن المكونات هي List<String>
//       if (fixedMeal['ingredients'] is! List<String>) {
//         fixedMeal['ingredients'] = ['Chicken', 'Rice', 'Vegetables', 'Olive Oil', 'Spices'];
//       }
//
//       fixedMeal['preparationTime'] = fixedMeal['preparationTime']?.toString() ?? '15-20 minutes';
//       fixedMeal['difficulty'] = fixedMeal['difficulty']?.toString() ?? 'Easy';
//
//       fixedMeals.add(fixedMeal);
//     }
//
//     return fixedMeals;
//   }
//
//   // حفظ الوجبات المولدة
//   static Future<void> saveGeneratedMealsToFirebase(List<Map<String, dynamic>> meals) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       try {
//         final today = DateTime.now();
//         final dateStr = DateFormat('yyyy-MM-dd').format(today);
//
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .collection('ai_generated_meals')
//             .doc(dateStr)
//             .set({
//           'meals': meals,
//           'generatedAt': Timestamp.now(),
//           'date': Timestamp.fromDate(today),
//           'source': 'Gemini AI',
//         }, SetOptions(merge: true));
//
//         print('✅ Saved ${meals.length} AI-generated meals to Firebase');
//       } catch (e) {
//         print('❌ Error saving AI meals: $e');
//       }
//     }
//   }
//
//   // جلب الوجبات المولدة
//   static Future<List<Map<String, dynamic>>> getGeneratedMeals() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       try {
//         final today = DateTime.now();
//         final dateStr = DateFormat('yyyy-MM-dd').format(today);
//
//         final doc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .collection('ai_generated_meals')
//             .doc(dateStr)
//             .get();
//
//         if (doc.exists && doc.data() != null) {
//           final data = doc.data()!;
//           final meals = data['meals'] as List<dynamic>;
//           print('📊 Retrieved ${meals.length} AI meals from Firebase');
//           return List<Map<String, dynamic>>.from(meals);
//         }
//       } catch (e) {
//         print('❌ Error getting AI meals: $e');
//       }
//     }
//     return [];
//   }
//
//   // وجبات احتياطية (فقط إذا فشل الـ AI)
//   static List<Map<String, dynamic>> _getFallbackMeals(
//       double dailyCalories,
//       String goal,
//       int mealsPerDay
//       ) {
//     print('⚠️ Using fallback meals');
//
//     final caloriesPerMeal = dailyCalories / mealsPerDay;
//
//     List<Map<String, dynamic>> meals = [];
//
//     // إضافة وجبات متنوعة بناءً على الهدف
//     if (goal == 'lose') {
//       meals.addAll(_getWeightLossMeals(caloriesPerMeal, mealsPerDay));
//     } else if (goal == 'gain') {
//       meals.addAll(_getWeightGainMeals(caloriesPerMeal, mealsPerDay));
//     } else {
//       meals.addAll(_getMaintenanceMeals(caloriesPerMeal, mealsPerDay));
//     }
//
//     return meals;
//   }
//
//   static List<Map<String, dynamic>> _getWeightLossMeals(double caloriesPerMeal, int mealsPerDay) {
//     return [
//       {
//         "mealType": "Breakfast",
//         "name": "High Protein Oatmeal",
//         "description": "Protein-packed oatmeal with berries and almonds for sustained energy",
//         "calories": caloriesPerMeal * 0.25,
//         "protein": 20,
//         "carbs": 40,
//         "fat": 8,
//         "ingredients": ["Rolled oats", "Protein powder", "Mixed berries", "Almonds", "Cinnamon"],
//         "preparationTime": "10 minutes",
//         "difficulty": "Easy"
//       },
//       {
//         "mealType": "Lunch",
//         "name": "Grilled Chicken & Quinoa Bowl",
//         "description": "Lean protein with complex carbs and fresh vegetables",
//         "calories": caloriesPerMeal * 0.35,
//         "protein": 35,
//         "carbs": 30,
//         "fat": 10,
//         "ingredients": ["Chicken breast", "Quinoa", "Broccoli", "Bell peppers", "Avocado"],
//         "preparationTime": "25 minutes",
//         "difficulty": "Medium"
//       },
//       {
//         "mealType": "Dinner",
//         "name": "Baked Salmon with Asparagus",
//         "description": "Omega-3 rich salmon with roasted vegetables",
//         "calories": caloriesPerMeal * 0.30,
//         "protein": 30,
//         "carbs": 15,
//         "fat": 18,
//         "ingredients": ["Salmon fillet", "Asparagus", "Sweet potato", "Lemon", "Dill"],
//         "preparationTime": "30 minutes",
//         "difficulty": "Medium"
//       },
//     ];
//   }
//
//   static List<Map<String, dynamic>> _getWeightGainMeals(double caloriesPerMeal, int mealsPerDay) {
//     return [
//       {
//         "mealType": "Breakfast",
//         "name": "Mass Gainer Smoothie",
//         "description": "Calorie-dense smoothie with protein, healthy fats, and complex carbs",
//         "calories": caloriesPerMeal * 0.30,
//         "protein": 25,
//         "carbs": 60,
//         "fat": 15,
//         "ingredients": ["Banana", "Oats", "Peanut butter", "Protein powder", "Milk", "Honey"],
//         "preparationTime": "5 minutes",
//         "difficulty": "Easy"
//       },
//       {
//         "mealType": "Lunch",
//         "name": "Beef & Rice Power Bowl",
//         "description": "High-calorie meal with lean beef and complex carbohydrates",
//         "calories": caloriesPerMeal * 0.40,
//         "protein": 40,
//         "carbs": 70,
//         "fat": 20,
//         "ingredients": ["Lean ground beef", "Brown rice", "Mixed vegetables", "Cheese", "Guacamole"],
//         "preparationTime": "30 minutes",
//         "difficulty": "Medium"
//       },
//       {
//         "mealType": "Dinner",
//         "name": "Protein Pasta with Meatballs",
//         "description": "High-protein pasta dish with homemade turkey meatballs",
//         "calories": caloriesPerMeal * 0.30,
//         "protein": 35,
//         "carbs": 55,
//         "fat": 15,
//         "ingredients": ["Protein pasta", "Ground turkey", "Tomato sauce", "Parmesan", "Spinach"],
//         "preparationTime": "35 minutes",
//         "difficulty": "Medium"
//       },
//     ];
//   }
//
//   static List<Map<String, dynamic>> _getMaintenanceMeals(double caloriesPerMeal, int mealsPerDay) {
//     return [
//       {
//         "mealType": "Breakfast",
//         "name": "Avocado Toast with Eggs",
//         "description": "Balanced breakfast with healthy fats, protein, and complex carbs",
//         "calories": caloriesPerMeal * 0.25,
//         "protein": 18,
//         "carbs": 35,
//         "fat": 20,
//         "ingredients": ["Whole grain bread", "Avocado", "Eggs", "Cherry tomatoes", "Feta cheese"],
//         "preparationTime": "15 minutes",
//         "difficulty": "Easy"
//       },
//       {
//         "mealType": "Lunch",
//         "name": "Mediterranean Chicken Wrap",
//         "description": "Fresh and balanced Mediterranean-style wrap",
//         "calories": caloriesPerMeal * 0.35,
//         "protein": 30,
//         "carbs": 40,
//         "fat": 15,
//         "ingredients": ["Whole wheat wrap", "Grilled chicken", "Hummus", "Cucumber", "Olives", "Lettuce"],
//         "preparationTime": "20 minutes",
//         "difficulty": "Easy"
//       },
//       {
//         "mealType": "Dinner",
//         "name": "Stir-fry with Tofu",
//         "description": "Vegetable-packed stir-fry with protein-rich tofu",
//         "calories": caloriesPerMeal * 0.30,
//         "protein": 25,
//         "carbs": 30,
//         "fat": 12,
//         "ingredients": ["Tofu", "Mixed vegetables", "Brown rice", "Soy sauce", "Ginger", "Garlic"],
//         "preparationTime": "25 minutes",
//         "difficulty": "Medium"
//       },
//     ];
//   }
// }