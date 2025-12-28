import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/colors.dart';
import 'package:ai_dietician/screens2/onboarding2_screen.dart';
import 'package:ai_dietician/screens2/splash_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _nutritionPlan;
  String _name = '';
  String _email = '';
  File? _profileImage;
  String _profileImageUrl = '';
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _waterReminders = true;
  bool _mealReminders = true;
  List<Map<String, dynamic>> _achievements = [];
  int _totalDaysLogged = 0;
  double _completionRate = 0.0;
  int _currentStreak = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAchievements();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _email = user.email ?? '';
      _name = user.displayName ?? 'User';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userData = data;
          _nutritionPlan = data['nutritionPlan'];
          _profileImageUrl = data['profileImageUrl'] ?? '';
          _notificationsEnabled = data['notificationsEnabled'] ?? true;
          _waterReminders = data['waterReminders'] ?? true;
          _mealReminders = data['mealReminders'] ?? true;
          _currentStreak = data['streak'] ?? 0;
        });
      }
    }
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _achievements = [
        {
          'title': 'First Week',
          'description': 'Logged meals for 7 consecutive days',
          'icon': Icons.emoji_events,
          'color': Colors.amber,
          'unlocked': true,
          'date': '2024-01-15',
        },
        {
          'title': 'Weight Goal',
          'description': 'Lost 5kg towards your target',
          'icon': Icons.flag,
          'color': Colors.green,
          'unlocked': _userData?['weight'] != null &&
              _userData?['targetWeight'] != null &&
              ((_userData!['weight'] - _userData!['targetWeight']) >= 5),
          'date': '2024-01-20',
        },
        {
          'title': 'Hydration Master',
          'description': 'Drank 2L of water for 30 days',
          'icon': Icons.water_drop,
          'color': Colors.blue,
          'unlocked': false,
          'date': null,
        },
        {
          'title': 'Consistency King',
          'description': '30 day streak',
          'icon': Icons.star,
          'color': Colors.purple,
          'unlocked': _currentStreak >= 30,
          'date': _currentStreak >= 30 ? '2024-02-01' : null,
        },
      ];
    });
  }

  Future<void> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_logs')
          .get();

      final totalDays = snapshot.docs.length;
      final completedDays = snapshot.docs.where((doc) =>
      (doc.data()['isCompleted'] ?? false)).length;

      setState(() {
        _totalDaysLogged = totalDays;
        _completionRate = totalDays > 0 ? (completedDays / totalDays) * 100 : 0;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      _updateProfileImage(pickedFile.path);
    }
  }

  Future<void> _updateProfileImage(String imagePath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profileImageUrl': imagePath,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _updateNotificationSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'notificationsEnabled': _notificationsEnabled,
        'waterReminders': _waterReminders,
        'mealReminders': _mealReminders,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showEditProfileDialog() {
    TextEditingController nameController = TextEditingController(text: _name);
    TextEditingController emailController = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.lightPurple.withOpacity(0.2),
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (_profileImageUrl.isNotEmpty
                      ? NetworkImage(_profileImageUrl) as ImageProvider
                      : null),
                  child: _profileImage == null && _profileImageUrl.isEmpty
                      ? Icon(Icons.camera_alt, size: 30, color: AppColors.lightPurple)
                      : null,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12),
              Text(
                'Note: Changing email may require re-authentication',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
              // Update profile in Firebase
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'name': nameController.text,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                // Update email if changed
                if (emailController.text != _email) {
                  try {
                    await user.updateEmail(emailController.text);
                  } catch (e) {
                    print('Error updating email: $e');
                  }
                }

                setState(() {
                  _name = nameController.text;
                  _email = emailController.text;
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: AppColors.lightPurple,
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text('Push Notifications'),
                    subtitle: Text('Receive daily reminders'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    activeColor: AppColors.lightPurple,
                  ),
                  SwitchListTile(
                    title: Text('Water Reminders'),
                    subtitle: Text('Remind me to drink water'),
                    value: _waterReminders,
                    onChanged: (value) {
                      setState(() {
                        _waterReminders = value;
                      });
                    },
                    activeColor: AppColors.lightPurple,
                  ),
                  SwitchListTile(
                    title: Text('Meal Reminders'),
                    subtitle: Text('Remind me to log meals'),
                    value: _mealReminders,
                    onChanged: (value) {
                      setState(() {
                        _mealReminders = value;
                      });
                    },
                    activeColor: AppColors.lightPurple,
                  ),
                  SwitchListTile(
                    title: Text('Dark Mode'),
                    subtitle: Text('Use dark theme'),
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                    },
                    activeColor: AppColors.lightPurple,
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.language, color: AppColors.lightPurple),
                    title: Text('Language'),
                    subtitle: Text('English'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // Change language
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.accessibility, color: AppColors.lightPurple),
                    title: Text('Units'),
                    subtitle: Text('Metric (kg, cm)'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // Change units
                    },
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
                onPressed: () {
                  _updateNotificationSettings();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Settings saved!'),
                      backgroundColor: AppColors.lightPurple,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightPurple,
                  foregroundColor: Colors.white,
                ),
                child: Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNutritionGoalsDialog() {
    if (_nutritionPlan == null) return;

    TextEditingController caloriesController = TextEditingController(
      text: _nutritionPlan!['dailyCalories'].toString(),
    );
    TextEditingController proteinController = TextEditingController(
      text: _nutritionPlan!['protein'].toString(),
    );
    TextEditingController carbsController = TextEditingController(
      text: _nutritionPlan!['carbs'].toString(),
    );
    TextEditingController fatController = TextEditingController(
      text: _nutritionPlan!['fat'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Nutrition Goals'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Daily Calories',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_fire_department),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: proteinController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Protein (g)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: carbsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Carbs (g)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bakery_dining),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: fatController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Fat (g)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.water_drop),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Note: These values are calculated based on your profile. '
                    'Manual changes may affect accuracy.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'nutritionPlan.dailyCalories': int.parse(caloriesController.text),
                  'nutritionPlan.protein': int.parse(proteinController.text),
                  'nutritionPlan.carbs': int.parse(carbsController.text),
                  'nutritionPlan.fat': int.parse(fatController.text),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                _loadUserData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nutrition goals updated!'),
                    backgroundColor: AppColors.lightPurple,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightPurple,
              foregroundColor: Colors.white,
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAchievementsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 8),
            Text('Achievements'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _achievements.length,
            itemBuilder: (context, index) {
              final achievement = _achievements[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                color: achievement['unlocked'] ? Colors.grey[50] : Colors.grey[100],
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: achievement['unlocked']
                          ? achievement['color'].withOpacity(0.2)
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      achievement['icon'],
                      color: achievement['unlocked']
                          ? achievement['color']
                          : Colors.grey[500],
                    ),
                  ),
                  title: Text(
                    achievement['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: achievement['unlocked'] ? Colors.black : Colors.grey,
                    ),
                  ),
                  subtitle: Text(achievement['description']),
                  trailing: achievement['unlocked']
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Unlocked',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        achievement['date'] ?? '',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  )
                      : Icon(Icons.lock, size: 20, color: Colors.grey),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAppFeedbackDialog() {
    double rating = 4.0;
    TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Rate Our App'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RatingBar.builder(
                    initialRating: rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (newRating) {
                      setState(() {
                        rating = newRating;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Your feedback (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Tell us what you think...',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your feedback helps us improve the app!',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
                onPressed: () {
                  // Save feedback to Firebase or send to server
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thank you for your feedback!'),
                      backgroundColor: AppColors.lightPurple,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightPurple,
                  foregroundColor: Colors.white,
                ),
                child: Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _shareApp() async {
    final url = 'https://play.google.com/store/apps/details?id=com.yourapp';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_guest');

    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => SplashScreen()),
          (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete your account? '
              'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                // Delete user data from Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .delete();

                // Delete user from Firebase Auth
                await user.delete();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => SplashScreen()),
                      (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Account deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete Account'),
          ),
        ],
      ),
    );
  }
  Widget _buildProfileHeader() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          children: [

            Stack(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: screenWidth * 0.15,
                    backgroundColor: AppColors.lightPurple.withOpacity(0.2),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_profileImageUrl.isNotEmpty
                        ? NetworkImage(_profileImageUrl) as ImageProvider
                        : null),
                    child: _profileImage == null && _profileImageUrl.isEmpty
                        ? Icon(Icons.person, size: screenWidth * 0.12, color: AppColors.lightPurple)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt, size: screenWidth * 0.045, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.05),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _name,
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              _email,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenWidth * 0.05),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                _buildResponsiveButton(
                  onPressed: _showEditProfileDialog,
                  icon: Icons.edit,
                  label: 'Edit Profile',
                  isOutlined: false,
                  screenWidth: screenWidth,
                ),
                _buildResponsiveButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OnboardingScreen()),
                    );
                  },
                  icon: Icons.refresh,
                  label: 'Recalculate',
                  isOutlined: true,
                  screenWidth: screenWidth,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildResponsiveButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isOutlined,
    required double screenWidth,
  }) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: isOutlined ? Colors.white : AppColors.lightPurple,
      foregroundColor: isOutlined ? AppColors.lightPurple : Colors.white,
      elevation: isOutlined ? 0 : 2,
      side: isOutlined ? BorderSide(color: AppColors.lightPurple) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: 12
      ),
    );

    return isOutlined
        ? OutlinedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 18),
      label: Text(label, style: TextStyle(fontSize: screenWidth * 0.035)),
    )
        : ElevatedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 18),
      label: Text(label, style: TextStyle(fontSize: screenWidth * 0.035)),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCircle('Days Logged', '$_totalDaysLogged', Icons.calendar_today),
                _buildStatCircle('Current Streak', '$_currentStreak', Icons.flash_on),
                _buildStatCircle('Completion', '${_completionRate.round()}%', Icons.check_circle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCircle(String label, String value, IconData icon) {
    return SizedBox(
      width: 85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.lightPurple.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.lightPurple.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: FittedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.lightPurple, size: 22),
                    SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard() {
    final unlockedCount = _achievements.where((a) => a['unlocked']).length;

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
                  'Achievements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _showAchievementsDialog,
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '$unlockedCount/${_achievements.length} unlocked',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: unlockedCount / _achievements.length,
              backgroundColor: Colors.grey[200],
              color: AppColors.lightPurple,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _achievements.take(3).map((achievement) {
                return Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: achievement['unlocked']
                            ? achievement['color'].withOpacity(0.2)
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        achievement['icon'],
                        color: achievement['unlocked']
                            ? achievement['color']
                            : Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      achievement['title'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
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
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications, color: AppColors.lightPurple),
              ),
              title: Text('Notifications'),
              subtitle: Text('Manage your notification preferences'),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _updateNotificationSettings();
                },
                activeColor: AppColors.lightPurple,
              ),
            ),
            Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.restaurant, color: AppColors.lightPurple),
              ),
              title: Text('Nutrition Goals'),
              subtitle: Text('Adjust your daily targets'),
              trailing: Icon(Icons.chevron_right),
              onTap: _showNutritionGoalsDialog,
            ),
            Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.settings, color: AppColors.lightPurple),
              ),
              title: Text('App Settings'),
              subtitle: Text('Customize your experience'),
              trailing: Icon(Icons.chevron_right),
              onTap: _showSettingsDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard() {
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
              'Support & About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.help, color: AppColors.lightPurple),
              ),
              title: Text('Help & Support'),
              subtitle: Text('Get help using the app'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to help screen
              },
            ),
            Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star, color: AppColors.lightPurple),
              ),
              title: Text('Rate App'),
              subtitle: Text('Share your feedback'),
              trailing: Icon(Icons.chevron_right),
              onTap: _showAppFeedbackDialog,
            ),
            Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.share, color: AppColors.lightPurple),
              ),
              title: Text('Share App'),
              subtitle: Text('Tell your friends'),
              trailing: Icon(Icons.chevron_right),
              onTap: _shareApp,
            ),
            Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.privacy_tip, color: AppColors.lightPurple),
              ),
              title: Text('Privacy Policy'),
              subtitle: Text('Read our privacy policy'),
              trailing: Icon(Icons.chevron_right),
              onTap: () async {
                final url = 'https://yourapp.com/privacy';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              },
            ),
            Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.description, color: AppColors.lightPurple),
              ),
              title: Text('Terms of Service'),
              subtitle: Text('Read our terms and conditions'),
              trailing: Icon(Icons.chevron_right),
              onTap: () async {
                final url = 'https://yourapp.com/terms';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      color: Colors.red.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout, color: Colors.red),
              ),
              title: Text('Logout'),
              subtitle: Text('Sign out of your account'),
              trailing: Icon(Icons.chevron_right),
              onTap: _logout,
            ),
            Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_forever, color: Colors.red),
              ),
              title: Text('Delete Account'),
              subtitle: Text('Permanently delete your account and data'),
              trailing: Icon(Icons.chevron_right),
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAppInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'AI Dietician Pro',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            '© 2025 FitLife Inc.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.stars, color: Colors.amber),
            SizedBox(width: 8),
            Text('Go Premium'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upgrade to Premium for:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              _buildPremiumFeature('Unlimited meal plans', Icons.restaurant),
              _buildPremiumFeature('Advanced analytics', Icons.insights),
              _buildPremiumFeature('Personalized coaching', Icons.person),
              _buildPremiumFeature('No ads', Icons.block),
              _buildPremiumFeature('Export data', Icons.download),
              SizedBox(height: 16),
              Card(
                color: AppColors.lightPurple.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Monthly: \$9.99',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightPurple,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Yearly: \$59.99 (Save 50%)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '7-day free trial',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle subscription purchase
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightPurple,
              foregroundColor: Colors.white,
            ),
            child: Text('Start Free Trial'),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.lightPurple),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Icon(Icons.check_circle, size: 16, color: Colors.green),
        ],
      ),
    );
  }

  void _showBackupRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Backup & Restore'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.cloud_upload, color: AppColors.lightPurple),
                title: Text('Backup to Cloud'),
                subtitle: Text('Save your data to the cloud'),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  // Backup logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backup started...'),
                      backgroundColor: AppColors.lightPurple,
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.cloud_download, color: AppColors.lightPurple),
                title: Text('Restore from Cloud'),
                subtitle: Text('Restore your saved data'),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  // Restore logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Restoring data...'),
                      backgroundColor: AppColors.lightPurple,
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.download, color: AppColors.lightPurple),
                title: Text('Export Data'),
                subtitle: Text('Download your data as CSV'),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  // Export logic
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.upload, color: AppColors.lightPurple),
                title: Text('Import Data'),
                subtitle: Text('Import data from other apps'),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  // Import logic
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.amber.withOpacity(0.3), width: 1),
      ),
      color: Colors.amber.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Premium Features',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'FREE TRIAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Unlock advanced features and personalized insights',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showSubscriptionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
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
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionButton(
                  'Backup',
                  Icons.backup,
                  Colors.blue,
                  _showBackupRestoreDialog,
                ),
                _buildQuickActionButton(
                  'Export',
                  Icons.download,
                  Colors.green,
                      () {},
                ),
                _buildQuickActionButton(
                  'Goals',
                  Icons.flag,
                  Colors.orange,
                  _showNutritionGoalsDialog,
                ),
                _buildQuickActionButton(
                  'Help',
                  Icons.help,
                  Colors.purple,
                      () {},
                ),
                _buildQuickActionButton(
                  'Invite',
                  Icons.person_add,
                  Colors.teal,
                  _shareApp,
                ),
                _buildQuickActionButton(
                  'Feedback',
                  Icons.feedback,
                  Colors.pink,
                  _showAppFeedbackDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    if (_userData == null) return const SizedBox();

    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenWidth * 0.05),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: screenWidth < 320 ? 1 : 2,
              childAspectRatio: screenWidth < 380 ? 2.2 : 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildInfoItem('Age', '${_userData!['age']} years', Icons.cake),
                _buildInfoItem('Height', '${_userData!['height']} cm', Icons.height),
                _buildInfoItem('Weight', '${_userData!['weight']} kg', Icons.monitor_weight),
                _buildInfoItem('Target', '${_userData!['targetWeight']} kg', Icons.flag),
                _buildInfoItem('Gender', _userData!['gender'] == 'male' ? 'Male' : 'Female', Icons.person),
                _buildInfoItem('Activity', _userData!['activityLevel'], Icons.directions_run),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.lightBlue),
      ),
      child: Row(
        children: [
          Icon(icon, size: 10, color: AppColors.lightPurple),
          SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) {
              switch (value) {
                case 'premium':
                  _showSubscriptionDialog();
                  break;
                case 'backup':
                  _showBackupRestoreDialog();
                  break;
                case 'export':
                // Export data
                  break;
                case 'theme':
                // Change theme
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'premium',
                child: Row(
                  children: [
                    Icon(Icons.stars, size: 20, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Go Premium'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    Icon(Icons.backup, size: 20),
                    SizedBox(width: 8),
                    Text('Backup & Restore'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.palette, size: 20),
                    SizedBox(width: 8),
                    Text('Change Theme'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(),
              SizedBox(height: 20),
              _buildStatsCard(),
              SizedBox(height: 20),
              _buildPersonalInfoCard(),
              SizedBox(height: 20),
              _buildAchievementsCard(),
              SizedBox(height: 20),
              _buildSubscriptionCard(),
              SizedBox(height: 20),
              _buildQuickActions(),
              SizedBox(height: 20),
              _buildSettingsCard(),
              SizedBox(height: 20),
              _buildSupportCard(),
              SizedBox(height: 20),
              _buildDangerZone(),
              SizedBox(height: 20),
              _buildAppInfo(),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}