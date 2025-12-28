import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _weightHistory = [];
  double _currentWeight = 70.0;
  double _targetWeight = 65.0;
  String _goal = 'lose';
  double _weightToGo = 5.0;
  double _totalChange = 0.0;
  double _weeklyGoal = 0.75;
  DateTime? _startDate;
  bool _isLoading = true;
  double? _initialWeight;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Load user data
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          setState(() {
            _userData = data;
            _currentWeight = (data['weight'] as num?)?.toDouble() ?? 70.0;
            _targetWeight = (data['targetWeight'] as num?)?.toDouble() ?? 65.0;
            _goal = data['goal']?.toString() ?? 'lose';
            _weeklyGoal = (data['weeklyGoal'] as num?)?.toDouble() ?? 0.75;
            if (data['createdAt'] != null) {
              _startDate = (data['createdAt'] as Timestamp).toDate();
            }
          });
        }

        // Load weight history
        await _loadWeightHistory();
      } catch (e) {
        print('Error Loading Data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error Loading Data'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWeightHistory() async {
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
          final List<Map<String, dynamic>> history = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            history.add({
              'id': doc.id,
              'date': (data['date'] as Timestamp).toDate(),
              'weight': (data['weight'] as num).toDouble(),
              'note': data['note']?.toString() ?? '',
            });
          }

          setState(() {
            _weightHistory = history;

            if (history.isNotEmpty) {
              _currentWeight = history.last['weight'];
              _initialWeight = history.first['weight'];

              // Calculate total change
              if (_initialWeight != null) {
                _totalChange = _goal == 'lose'
                    ? _initialWeight! - _currentWeight
                    : _currentWeight - _initialWeight!;
              }

              // Calculate weight to go
              _weightToGo = _goal == 'lose'
                  ? _currentWeight - _targetWeight
                  : _targetWeight - _currentWeight;

              if (_weightToGo < 0) _weightToGo = 0.0;
            }
          });
        }
      } catch (e) {
        print('Error Loading Weight Record: $e');
      }
    }
  }

  Future<void> _saveWeightToFirebase(double weight, String note) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final now = DateTime.now();

        // Save to weight log
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('weight_logs')
            .add({
          'weight': weight,
          'note': note,
          'date': Timestamp.fromDate(now),
          'createdAt': Timestamp.now(),
        });

        // Update current weight in user data
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'weight': weight,
          'lastWeightUpdate': Timestamp.now(),
        });

        // Reload data
        await _loadWeightHistory();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weight updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Error saving weight: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving weight: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateWeeklyGoal(double goal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'weeklyGoal': goal,
        });

        setState(() {
          _weeklyGoal = goal;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weekly goal updated!'),
            backgroundColor: AppColors.lightPurple,
          ),
        );
      } catch (e) {
        print('Error updating weekly goal: $e');
      }
    }
  }

  Widget _buildWeightCard() {
    // Calculate progress percentage
    double progress = 0.0;

    if (_initialWeight != null) {
      final totalChangeNeeded = _goal == 'lose'
          ? _initialWeight! - _targetWeight
          : _targetWeight - _initialWeight!;

      if (totalChangeNeeded > 0) {
        progress = _totalChange / totalChangeNeeded;
      }
    }

    if (progress.isNaN || progress.isInfinite) progress = 0.0;
    progress = progress.clamp(0.0, 1.0);

    final progressPercent = (progress * 100).toInt();
    final isGoalAchieved = _goal == 'lose'
        ? _currentWeight <= _targetWeight
        : _currentWeight >= _targetWeight;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Goal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_weeklyGoal.toStringAsFixed(2)} kg per week',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.lightPurple),
                  onPressed: _showWeeklyGoalDialog,
                ),
              ],
            ),
            SizedBox(height: 20),

            // Current weight
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Weight',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${_currentWeight.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: isGoalAchieved ? Colors.green : Colors.black87,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (_weightHistory.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Last update: ${DateFormat('M/d/yyyy').format(_weightHistory.last['date'])}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddWeightDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: Icon(Icons.add, size: 20),
                  label: Text('Log Weight'),
                ),
              ],
            ),

            if (isGoalAchieved)
              Container(
                margin: EdgeInsets.only(top: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🎉 Congratulations! You have reached your goal!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Progress section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                if (!isGoalAchieved)
                  Text(
                    '${_weightToGo.abs().toStringAsFixed(1)} kg ${_goal == 'lose' ? 'to lose' : 'to gain'} remaining',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  )
                else
                  Text(
                    'Goal achieved! Maintain your weight',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                SizedBox(height: 16),

                // Progress bar
                Stack(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: isGoalAchieved ? Colors.green : AppColors.lightPurple,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    if (progressPercent > 0)
                      Positioned(
                        left: '${progressPercent}%'.length * 5,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            '$progressPercent%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Start: ${_initialWeight?.toStringAsFixed(1) ?? "--"} kg',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Target: ${_targetWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 24),

            // Statistics
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total ${_goal == 'lose' ? 'Lost' : 'Gained'}',
                    '${_totalChange.abs().toStringAsFixed(1)} kg',
                    _totalChange > 0 ? (_goal == 'lose' ? Colors.green : Colors.red) :
                    _totalChange < 0 ? (_goal == 'lose' ? Colors.red : Colors.green) : Colors.grey,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildStatItem(
                    '10-Day Avg',
                    '${_calculate10DayAvg().toStringAsFixed(1)} kg',
                    Colors.black87,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildStatItem(
                    'Est. Date',
                    _calculateEstimateDate(),
                    isGoalAchieved ? Colors.green : AppColors.lightPurple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _calculate10DayAvg() {
    if (_weightHistory.isEmpty) return _currentWeight;

    final recentWeights = _weightHistory
        .take(10)
        .map((entry) => entry['weight'] as double)
        .toList();

    if (recentWeights.isEmpty) return _currentWeight;

    final sum = recentWeights.reduce((a, b) => a + b);
    return sum / recentWeights.length;
  }

  String _calculateEstimateDate() {
    if (_weightToGo <= 0) return 'Achieved!';

    final weeksNeeded = _weightToGo / _weeklyGoal;
    if (weeksNeeded <= 0) return 'Achieved!';

    final estDate = DateTime.now().add(Duration(days: (weeksNeeded * 7).round()));
    return DateFormat('M/d').format(estDate);
  }

  void _showWeeklyGoalDialog() {
    TextEditingController controller = TextEditingController(
      text: _weeklyGoal.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Weekly Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How many kg do you want to ${_goal == 'lose' ? 'lose' : 'gain'} per week?'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'kg per week',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.scale),
              ),
            ),
            SizedBox(height: 8),
            Text(
              _goal == 'lose'
                  ? 'Recommended: 0.5-1 kg per week for healthy loss'
                  : 'Recommended: 0.25-0.5 kg per week for healthy gain',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
              final newGoal = double.tryParse(controller.text);
              if (newGoal != null && newGoal > 0 && newGoal <= 2) {
                _updateWeeklyGoal(newGoal);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a value between 0.1 and 2.0'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightPurple,
              foregroundColor: Colors.white,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog() {
    TextEditingController weightController = TextEditingController(
      text: _currentWeight.toStringAsFixed(1),
    );
    TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.scale, color: AppColors.lightPurple),
                SizedBox(width: 8),
                Text('Log Weight'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                      hintText: 'Enter your current weight',
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                      hintText: 'How do you feel? Any changes?',
                    ),
                  ),
                  SizedBox(height: 16),
                  if (_weightHistory.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(),
                        SizedBox(height: 8),
                        Text(
                          'Last log: ${_weightHistory.last['weight']} kg',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Date: ${DateFormat('M/d/yyyy').format(_weightHistory.last['date'])}',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        DateFormat('M/d/yyyy - hh:mm a').format(DateTime.now()),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final weight = double.tryParse(weightController.text);
                  if (weight != null && weight > 0 && weight <= 300) {
                    Navigator.pop(context);
                    await _saveWeightToFirebase(weight, noteController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a valid weight (0-300 kg)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightPurple,
                  foregroundColor: Colors.white,
                ),
                child: Text('Save Weight'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeightChart() {
    if (_weightHistory.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          height: 200,
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  'Log your first weight to see the chart',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: _showAddWeightDialog,
                  child: Text('Add First Weight'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<FlSpot> spots = [];
    final List<String> dates = [];

    for (var i = 0; i < _weightHistory.length; i++) {
      final entry = _weightHistory[i];
      spots.add(FlSpot(i.toDouble(), entry['weight']));
      dates.add(DateFormat('M/d').format(entry['date']));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weight Tracker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_weightHistory.length > 1)
                  Text(
                    '${_totalChange >= 0 ? '+' : ''}${_totalChange.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _totalChange > 0
                          ? (_goal == 'lose' ? Colors.green : Colors.red)
                          : _totalChange < 0
                          ? (_goal == 'lose' ? Colors.red : Colors.green)
                          : Colors.grey,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.white,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index >= 0 && index < _weightHistory.length) {
                            final entry = _weightHistory[index];
                            return LineTooltipItem(
                              '${entry['weight']} kg\n${DateFormat('M/d/yyyy').format(entry['date'])}',
                              TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (_weightHistory.length / 4).ceil().toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _weightHistory.length && index % ((_weightHistory.length / 4).ceil()) == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('M/d').format(_weightHistory[index]['date']),
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  minX: 0,
                  maxX: _weightHistory.length > 1 ? _weightHistory.length - 1 : 1,
                  minY: _calculateMinY(),
                  maxY: _calculateMaxY(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.lightPurple,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.lightPurple,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.lightPurple.withOpacity(0.3),
                            AppColors.lightPurple.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMinY() {
    if (_weightHistory.isEmpty) return _currentWeight - 5;
    final weights = _weightHistory.map((e) => e['weight'] as double).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    return minWeight - 2;
  }

  double _calculateMaxY() {
    if (_weightHistory.isEmpty) return _currentWeight + 5;
    final weights = _weightHistory.map((e) => e['weight'] as double).toList();
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    return maxWeight + 2;
  }

  Widget _buildHistoryCard() {
    if (_weightHistory.isEmpty) {
      return SizedBox();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: _weightHistory.reversed.take(5).map((entry) {
                final date = entry['date'] as DateTime;
                final weight = entry['weight'] as double;
                final note = entry['note'] as String;
                final previousIndex = _weightHistory.indexOf(entry) - 1;
                double change = 0.0;

                if (previousIndex >= 0) {
                  final previousWeight = _weightHistory[previousIndex]['weight'] as double;
                  change = weight - previousWeight;
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.lightPurple.withOpacity(0.1),
                    child: Icon(
                      Icons.scale,
                      color: AppColors.lightPurple,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '${weight.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('M/d/yyyy - hh:mm a').format(date)),
                      if (note.isNotEmpty)
                        Text(
                          note,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: change != 0
                      ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: change > 0
                          ? (_goal == 'lose' ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1))
                          : (_goal == 'lose' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: change > 0
                              ? (_goal == 'lose' ? Colors.red : Colors.green)
                              : (_goal == 'lose' ? Colors.green : Colors.red),
                        ),
                        SizedBox(width: 2),
                        Text(
                          '${change.abs().toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: change > 0
                                ? (_goal == 'lose' ? Colors.red : Colors.green)
                                : (_goal == 'lose' ? Colors.green : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  )
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'Progress Tracking',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadUserData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Refreshing data...'),
                  backgroundColor: AppColors.lightPurple,
                ),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppColors.lightPurple,
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildWeightCard(),
              SizedBox(height: 20),
              _buildWeightChart(),
              SizedBox(height: 20),
              _buildHistoryCard(),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWeightDialog,
        backgroundColor: AppColors.lightPurple,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Log Weight'),
        elevation: 4,
      ),
    );
  }
}