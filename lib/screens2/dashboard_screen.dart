import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _dailyCalorieGoal = 2000;
  int _currentStreak = 0;
  double _waterConsumed = 0;
  List<Map<String, dynamic>> _todayMeals = [];
  double _todayTotalCalories = 0;
  double _todayTotalProtein = 0;
  double _todayTotalCarbs = 0;
  double _todayTotalFat = 0;
  double _currentWeight = 70.0;
  double _weightChange = 0.0;
  String _weightChangePeriod = 'Since 18 Apr';
  double _weight10DayAvg = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTodayMeals();
    _loadWeightData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _dailyCalorieGoal = (data['nutritionPlan']?['dailyCalories'] as num?)?.toDouble() ?? 2000;
            _currentStreak = (data['streak'] as int?) ?? 0;
            _waterConsumed = (data['waterConsumed'] as num?)?.toDouble() ?? 0;
            _currentWeight = (data['weight'] as num?)?.toDouble() ?? 70.0;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _loadWeightData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('weight_logs')
            .orderBy('date', descending: false)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final weightHistory = snapshot.docs.map((doc) {
            final data = doc.data();
            return data['weight'] as double;
          }).toList();

          if (weightHistory.length >= 2) {
            final oldestWeight = weightHistory.first;
            final latestWeight = weightHistory.last;
            _weightChange = latestWeight - oldestWeight;

            // حساب متوسط 10 أيام
            final recentWeights = weightHistory.take(10).toList();
            if (recentWeights.isNotEmpty) {
              final sum = recentWeights.reduce((a, b) => a + b);
              _weight10DayAvg = sum / recentWeights.length;
            }

            // حساب الفترة الزمنية
            final oldestDate = (snapshot.docs.first.data()['date'] as Timestamp).toDate();
            final now = DateTime.now();
            final difference = now.difference(oldestDate);

            if (difference.inDays == 1) {
              _weightChangePeriod = 'Since yesterday';
            } else if (difference.inDays < 30) {
              _weightChangePeriod = 'Since ${difference.inDays} days ago';
            } else if (difference.inDays < 365) {
              _weightChangePeriod = 'Since ${(difference.inDays / 30).round()} months ago';
            } else {
              _weightChangePeriod = DateFormat('dd MMM').format(oldestDate);
            }
          }
        }
      } catch (e) {
        print('Error loading weight data: $e');
      }
    }
  }

  Future<void> _loadTodayMeals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('daily_logs')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .orderBy('date', descending: true)
            .get();

        if (snapshot.docs.isNotEmpty) {
          double totalCalories = 0;
          double totalProtein = 0;
          double totalCarbs = 0;
          double totalFat = 0;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            totalCalories += (data['calories'] as num?)?.toDouble() ?? 0;
            totalProtein += (data['protein'] as num?)?.toDouble() ?? 0;
            totalCarbs += (data['carbs'] as num?)?.toDouble() ?? 0;
            totalFat += (data['fat'] as num?)?.toDouble() ?? 0;
          }

          setState(() {
            _todayTotalCalories = totalCalories;
            _todayTotalProtein = totalProtein;
            _todayTotalCarbs = totalCarbs;
            _todayTotalFat = totalFat;
            _isLoading = false;
          });
        } else {
          setState(() {
            _todayTotalCalories = 0;
            _todayTotalProtein = 0;
            _todayTotalCarbs = 0;
            _todayTotalFat = 0;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading meals: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double get _remainingCalories {
    return _dailyCalorieGoal - _todayTotalCalories;
  }

  Map<String, double> _getMacroPercentages() {
    final total = _todayTotalProtein * 4 + _todayTotalCarbs * 4 + _todayTotalFat * 9;
    if (total == 0) return {'protein': 0, 'carbs': 0, 'fat': 0};

    return {
      'protein': (_todayTotalProtein * 4 / total * 100),
      'carbs': (_todayTotalCarbs * 4 / total * 100),
      'fat': (_todayTotalFat * 9 / total * 100),
    };
  }

  Widget _buildCaloriesCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CALORIES',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _remainingCalories.round().toString(),
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'UNDER',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: _todayTotalCalories / _dailyCalorieGoal,
              backgroundColor: Colors.grey[200],
              color: AppColors.lightPurple,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Consumed: ${_todayTotalCalories.round()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Goal: ${_dailyCalorieGoal.round()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacrosCard() {
    final percentages = _getMacroPercentages();
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        // استخدام Padding متناسب مع الشاشة
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MACROS',
              style: TextStyle(
                fontSize: screenWidth * 0.03, // حجم خط مرن
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 16),
            // الصف العلوي (النسب المئوية)
            Row(
              children: [
                Expanded(child: _buildMacroColumn('Fat', percentages['fat']?.round() ?? 0, Colors.orange)),
                Expanded(child: _buildMacroColumn('Carbs', percentages['carbs']?.round() ?? 0, Colors.green)),
                Expanded(child: _buildMacroColumn('Protein', percentages['protein']?.round() ?? 0, Colors.blue)),
              ],
            ),
            SizedBox(height: 20),
            // الحاوية الرمادية السفلية (الجرامات)
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildGramStat('Fat', '${_todayTotalFat.round()}g'),
                  _buildGramStat('Carbs', '${_todayTotalCarbs.round()}g'),
                  _buildGramStat('Protein', '${_todayTotalProtein.round()}g'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildGramStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMacroColumn(String label, int percent, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$percent%',
            style: TextStyle(
              fontSize: screenWidth * 0.045, // حجم خط مرن
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    // استخدام MediaQuery للحصول على عرض الشاشة
    final screenWidth = MediaQuery.of(context).size.width;
    int currentDayOfWeek = DateTime.now().weekday;
    List<String> weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        // استخدام Padding نسبي بدلاً من الثابت
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STREAK',
              style: TextStyle(
                fontSize: screenWidth * 0.035, // حجم خط مرن
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_currentStreak',
                  style: TextStyle(
                    fontSize: screenWidth * 0.09, // حجم خط مرن للرقم
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _currentStreak == 1 ? 'Day' : 'Days',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  bool isToday = (index + 1 == currentDayOfWeek);

                  // استخدام Expanded أو Flexible لضمان توزيع الأيام بالتساوي دون Overflow
                  return Expanded(
                    child: _buildDay(weekDays[index], isToday),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDay(String day, bool isActive) {
    final screenWidth = MediaQuery.of(context).size.width;

    double circleSize = screenWidth * 0.075;
    if (circleSize > 35) circleSize = 35;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: isActive ? AppColors.lightPurple : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.lightPurple : Colors.grey[300]!,
              width: 1.5, // زدت السمك قليلاً ليكون أوضح
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  day,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[600],
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightCard() {
    final weightChangeColor = _weightChange > 0 ? Colors.red : Colors.green;
    final weightChangeIcon = _weightChange > 0 ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WEIGHT',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weightChangePeriod,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Icon(weightChangeIcon, size: 24, color: weightChangeColor),
                        SizedBox(width: 4),
                        Text(
                          '${_weightChange.abs().toStringAsFixed(1)} kgs',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: weightChangeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'all time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${_weight10DayAvg.toStringAsFixed(1)} kgs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '10 Day Avg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${_currentWeight.toStringAsFixed(1)} kg',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${_weightChange >= 0 ? '+' : ''}${_weightChange.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: weightChangeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WATER',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, size: 40, color: Colors.blue),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(_waterConsumed / 1000).toStringAsFixed(1)}L',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: AppColors.lightPurple, size: 32),
                  onPressed: _showWaterDialog,
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: _waterConsumed / 3000,
              backgroundColor: Colors.grey[200],
              color: Colors.blue,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  void _showWaterDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Water'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How much water did you drink?'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (ml)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.water_drop),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                _saveWaterConsumed(amount);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightPurple,
              foregroundColor: Colors.white,
            ),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWaterConsumed(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final newWater = _waterConsumed + amount;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'waterConsumed': newWater,
          'lastWaterUpdate': Timestamp.now(),
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('water_logs')
            .add({
          'amount': amount,
          'date': Timestamp.now(),
        });

        setState(() {
          _waterConsumed = newWater;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${amount}ml water'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error saving water: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.lightPurple),
            onPressed: () {
              _loadUserData();
              _loadTodayMeals();
              _loadWeightData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Refreshing data...'),
                  backgroundColor: AppColors.lightPurple,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCaloriesCard(),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMacrosCard()),
                  SizedBox(width: 16),
                  Expanded(child: _buildStreakCard()),
                ],
              ),
              SizedBox(height: 16),
              _buildWeightCard(),
              SizedBox(height: 16),
              _buildWaterCard(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),

    );
  }
}