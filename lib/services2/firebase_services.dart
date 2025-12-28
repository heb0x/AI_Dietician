import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Get user document
  static Future<DocumentSnapshot> getUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    return await _firestore.collection('users').doc(user.uid).get();
  }

  // Update user profile
  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore.collection('users').doc(user.uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Upload profile image
  static Future<String> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profile_images/$fileName');

      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update user profile with image URL
      await updateUserProfile({'profileImageUrl': downloadUrl});

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Save daily meal log
  static Future<void> saveDailyLog({
    required DateTime date,
    required Map<String, dynamic> breakfast,
    required Map<String, dynamic> lunch,
    required Map<String, dynamic> dinner,
    required Map<String, dynamic> snacks,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('daily_logs')
        .doc(dateStr)
        .set({
      'date': Timestamp.fromDate(date),
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
      'snacks': snacks,
      'totalCalories': (breakfast['calories'] ?? 0) +
          (lunch['calories'] ?? 0) +
          (dinner['calories'] ?? 0) +
          (snacks['calories'] ?? 0),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get today's log
  static Future<Map<String, dynamic>?> getTodayLog() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_logs')
          .doc(dateStr)
          .get();

      return doc.data();
    } catch (e) {
      print('Error getting today log: $e');
      return null;
    }
  }

  // Add weight entry
  static Future<void> addWeightEntry(double weight, {String note = ''}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weight_logs')
        .add({
      'weight': weight,
      'note': note,
      'date': Timestamp.now(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update current weight in user profile
    await updateUserProfile({'weight': weight});
  }

  // Get weight history
  static Future<List<Map<String, dynamic>>> getWeightHistory({int limit = 30}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weight_logs')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'weight': (data['weight'] as num).toDouble(),
          'note': data['note'] ?? '',
          'date': (data['date'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error getting weight history: $e');
      return [];
    }
  }

  // Logout
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Delete account
  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user from Firebase Auth
      await user.delete();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }
}