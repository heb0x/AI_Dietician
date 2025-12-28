import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import 'main_layout_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;

  // User data with default values
  String _gender = 'male';
  double _age = 25.0;
  double _height = 170.0;
  double _weight = 70.0;
  String _activityLevel = 'moderate';
  String _goal = 'lose';
  double _targetWeight = 40.0;
  List<String> _dietaryRestrictions = [];
  String _dietType = 'balanced';

  final List<Map<String, dynamic>> _activityLevels = [
    {'key': 'sedentary', 'title': 'Sedentary', 'subtitle': 'Office job, little exercise', 'icon': Icons.chair},
    {'key': 'light', 'title': 'Lightly Active', 'subtitle': 'Exercise 1-3 times/week', 'icon': Icons.directions_walk},
    {'key': 'moderate', 'title': 'Moderately Active', 'subtitle': 'Exercise 3-5 times/week', 'icon': Icons.directions_run},
    {'key': 'active', 'title': 'Very Active', 'subtitle': 'Exercise 6-7 times/week', 'icon': Icons.fitness_center},
    {'key': 'very_active', 'title': 'Extremely Active', 'subtitle': 'Physical job or athlete', 'icon': Icons.sports},
  ];

  final List<Map<String, dynamic>> _goals = [
    {'key': 'lose', 'title': 'Lose Weight', 'subtitle': 'Reduce body fat', 'icon': Icons.trending_down, 'color': Colors.green},
    {'key': 'maintain', 'title': 'Maintain Weight', 'subtitle': 'Stay at current weight', 'icon': Icons.trending_flat, 'color': Colors.blue},
    {'key': 'gain', 'title': 'Gain Muscle', 'subtitle': 'Build muscle mass', 'icon': Icons.trending_up, 'color': Colors.orange},
  ];

  final List<Map<String, dynamic>> _dietTypes = [
    {'key': 'balanced', 'title': 'Balanced', 'icon': Icons.restaurant_menu},
    {'key': 'vegetarian', 'title': 'Vegetarian', 'icon': Icons.eco},
    {'key': 'keto', 'title': 'Keto', 'icon': Icons.local_fire_department},
    {'key': 'vegan', 'title': 'Vegan', 'icon': Icons.eco},
    {'key': 'mediterranean', 'title': 'Mediterranean', 'icon': Icons.food_bank},
  ];

  final List<Map<String, dynamic>> _allergies = [
    {'key': 'dairy', 'title': 'Dairy'},
    {'key': 'gluten', 'title': 'Gluten'},
    {'key': 'nuts', 'title': 'Nuts'},
    {'key': 'seafood', 'title': 'Seafood'},
    {'key': 'eggs', 'title': 'Eggs'},
    {'key': 'soy', 'title': 'Soy'},
  ];

  @override
  void initState() {
    super.initState();
    _updateTargetWeightBounds();
    _checkIfGuest();
  }
  Future<void> _checkIfGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('is_guest') ?? false;

    if (isGuest && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Guest Mode'),
            content: Text(
              'You are using the app as a guest. '
                  'Your data will be saved locally but not synced across devices. '
                  'Create an account to save your progress permanently.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Got it'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/auth');
                },
                child: Text('Create Account'),
              ),
            ],
          ),
        );
      });
    }
  }
  void _updateTargetWeightBounds() {
    if (_goal == 'lose') {
      if (_targetWeight < 40) _targetWeight = 40;
      if (_targetWeight > _weight) _targetWeight = _weight - 1;
    } else if (_goal == 'gain') {
      if (_targetWeight < _weight) _targetWeight = _weight + 1;
      if (_targetWeight > 150) _targetWeight = 150;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Create Your Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            height: 4,
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentStep ? AppColors.lightPurple : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: _nextStep,
              onStepCancel: _previousStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              controlsBuilder: (context, details) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(120, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text('Back'),
                        ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightPurple,
                          foregroundColor: Colors.white,
                          minimumSize: Size(120, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(_currentStep == 3 ? 'Finish' : 'Continue'),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Basic Information
                Step(
                  title: Text('Basic Info'),
                  content: _buildBasicInfoStep(),
                  isActive: _currentStep >= 0,
                ),

                // Step 2: Activity Level
                Step(
                  title: Text('Activity Level'),
                  content: _buildActivityStep(),
                  isActive: _currentStep >= 1,
                ),

                // Step 3: Goals
                Step(
                  title: Text('Goals'),
                  content: _buildGoalsStep(),
                  isActive: _currentStep >= 2,
                ),

                // Step 4: Dietary Preferences
                Step(
                  title: Text('Dietary Preferences'),
                  content: _buildDietaryStep(),
                  isActive: _currentStep >= 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),

          // Gender Selection
          Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildGenderButton('Male', Icons.male, 'male'),
              ),
              SizedBox(width: 20),
              Expanded(
                child: _buildGenderButton('Female', Icons.female, 'female'),
              ),
            ],
          ),

          SizedBox(height: 30),

          // Age
          _buildSliderCard(
            title: 'Age',
            value: _age,
            min: 10,
            max: 80,
            unit: 'years',
            onChanged: (value) => setState(() => _age = value),
          ),

          SizedBox(height: 20),

          // Height
          _buildSliderCard(
            title: 'Height',
            value: _height,
            min: 120,
            max: 220,
            unit: 'cm',
            onChanged: (value) => setState(() => _height = value),
          ),

          SizedBox(height: 20),

          // Weight
          _buildSliderCard(
            title: 'Weight',
            value: _weight,
            min: 40,
            max: 150,
            unit: 'kg',
            onChanged: (value) {
              setState(() {
                _weight = value;
                _updateTargetWeightBounds();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String label, IconData icon, String value) {
    final bool isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightPurple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.lightPurple : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.white : AppColors.lightPurple),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                Text('${value.round()} $unit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.lightPurple)),
              ],
            ),
            SizedBox(height: 15),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              label: '${value.round()} $unit',
              activeColor: AppColors.lightPurple,
              inactiveColor: Colors.grey[300],
              onChanged: onChanged,
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${min.round()}', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('${max.round()}', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 10),
          Text(
            'Select your activity level',
            style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),

          ..._activityLevels.map((activity) {
            final bool isSelected = _activityLevel == activity['key'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: isSelected ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: isSelected ? AppColors.lightPurple : Colors.transparent,
                    width: isSelected ? 2 : 0,
                  ),
                ),
                child: ListTile(
                  onTap: () => setState(() => _activityLevel = activity['key']),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.lightPurple.withOpacity(0.2) : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      activity['icon'],
                      color: isSelected ? AppColors.lightPurple : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  title: Text(
                    activity['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.lightPurple : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(activity['subtitle'], style: TextStyle(fontSize: 14)),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppColors.lightPurple)
                      : null,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalsStep() {
    _updateTargetWeightBounds();

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 10),
          Text(
            'What is your primary goal?',
            style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),

          ..._goals.map((goal) {
            final bool isSelected = _goal == goal['key'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: isSelected ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: isSelected ? goal['color'] as Color : Colors.transparent,
                    width: isSelected ? 2 : 0,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    setState(() {
                      _goal = goal['key'];
                      _updateTargetWeightBounds();
                    });
                  },
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? (goal['color'] as Color).withOpacity(0.2) : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      goal['icon'],
                      color: isSelected ? goal['color'] as Color : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  title: Text(
                    goal['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? goal['color'] as Color : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(goal['subtitle'], style: TextStyle(fontSize: 14)),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: goal['color'] as Color)
                      : null,
                ),
              ),
            );
          }).toList(),

          if (_goal != 'maintain') ...[
            SizedBox(height: 30),
            _buildSliderCard(
              title: _goal == 'lose' ? 'Target Weight (Lose)' : 'Target Weight (Gain)',
              value: _targetWeight,
              min: _goal == 'lose' ? 40 : (_weight + 1),
              max: _goal == 'lose' ? (_weight - 0.1) : 150,
              unit: 'kg',
              onChanged: (value) => setState(() => _targetWeight = value),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                _goal == 'lose'
                    ? 'Set a realistic target weight between 40kg and ${_weight.round()}kg'
                    : 'Set your target weight between ${_weight.round()}kg and 150kg',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDietaryStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),

          // Diet Type
          Text('Preferred Diet Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _dietTypes.map((diet) {
              final bool isSelected = _dietType == diet['key'];
              return ChoiceChip(
                label: Text(diet['title']),
                selected: isSelected,
                onSelected: (selected) => setState(() => _dietType = diet['key']),
                selectedColor: AppColors.lightPurple,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                avatar: Icon(diet['icon'], size: 18),
              );
            }).toList(),
          ),

          SizedBox(height: 30),

          // Allergies & Restrictions
          Text('Food Allergies & Restrictions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 10),
          Text('Select any that apply:', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allergies.map((allergy) {
              final bool isSelected = _dietaryRestrictions.contains(allergy['key']);
              return FilterChip(
                label: Text(allergy['title']),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _dietaryRestrictions.add(allergy['key']);
                    } else {
                      _dietaryRestrictions.remove(allergy['key']);
                    }
                  });
                },
                selectedColor: AppColors.lightPurple.withOpacity(0.3),
                checkmarkColor: AppColors.lightPurple,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.lightPurple : Colors.black,
                  fontSize: 14,
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 30),

          // Cooking Time Preference
          Text('Maximum Cooking Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              '30 min',
              '45 min',
              '60+ min'
            ].asMap().entries.map((entry) {
              final int index = entry.key;
              final String time = entry.value;
              final bool isSelected = index == 0;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.lightPurple.withOpacity(0.2) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.lightPurple : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(time,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.lightPurple : Colors.black,
                    )),
              );
            }).toList(),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _finishOnboarding() async {
    _updateTargetWeightBounds();

    final nutritionPlan = _calculateNutrition();

    final userData = {
      'gender': _gender,
      'age': _age.round(),
      'height': _height.round(),
      'weight': _weight.round(),
      'activityLevel': _activityLevel,
      'goal': _goal,
      'targetWeight': _targetWeight.round(),
      'dietType': _dietType,
      'dietaryRestrictions': _dietaryRestrictions,
      'nutritionPlan': nutritionPlan,
      'caloriesConsumed': 0,
      'waterConsumed': 0,
      'proteinConsumed': 0,
      'carbsConsumed': 0,
      'fatConsumed': 0,
      'onboardingCompleted': true,

    };

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
    }


    print('ONBOARDING FINISHED - GOING TO DASHBOARD');
    Navigator.pushAndRemoveUntil(

      context,
      MaterialPageRoute(

        builder: (_) => const MainLayout(),
      ),
          (route) => false,
    );

  }



  Map<String, dynamic> _calculateNutrition() {
    // BMR Calculation
    double bmr;
    if (_gender == 'male') {
      bmr = (10 * _weight) + (6.25 * _height) - (5 * _age) + 5;
    } else {
      bmr = (10 * _weight) + (6.25 * _height) - (5 * _age) - 161;
    }

    // Activity Multiplier
    double activityMultiplier = 1.2;
    switch (_activityLevel) {
      case 'sedentary': activityMultiplier = 1.2; break;
      case 'light': activityMultiplier = 1.375; break;
      case 'moderate': activityMultiplier = 1.55; break;
      case 'active': activityMultiplier = 1.725; break;
      case 'very_active': activityMultiplier = 1.9; break;
    }

    double tdee = bmr * activityMultiplier;

    // Adjust for goal
    double targetCalories = tdee;
    switch (_goal) {
      case 'lose': targetCalories = tdee - 500; break;
      case 'gain': targetCalories = tdee + 500; break;
    }

    // Ensure minimum calories
    if (targetCalories < 1200) targetCalories = 1200;

    // Adjust for diet type
    double protein, carbs, fat;

    if (_dietType == 'keto') {
      protein = (targetCalories * 0.25) / 4;
      carbs = (targetCalories * 0.05) / 4;
      fat = (targetCalories * 0.70) / 9;
    } else if (_dietType == 'vegetarian' || _dietType == 'vegan') {
      protein = (targetCalories * 0.25) / 4;
      carbs = (targetCalories * 0.55) / 4;
      fat = (targetCalories * 0.20) / 9;
    } else {
      protein = (targetCalories * 0.30) / 4;
      carbs = (targetCalories * 0.40) / 4;
      fat = (targetCalories * 0.30) / 9;
    }

    return {
      'bmr': bmr.round(),
      'tdee': tdee.round(),
      'dailyCalories': targetCalories.round(),
      'protein': protein.round(),
      'carbs': carbs.round(),
      'fat': fat.round(),
      'planName': '${_dietType == 'vegan' ? 'Vegan' :
      _dietType == 'keto' ? 'Keto' :
      _dietType == 'vegetarian' ? 'Vegetarian' : 'Balanced'} Plan',
    };
  }
}