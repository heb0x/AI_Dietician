import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  /// إنشاء/تحديث بيانات المستخدم
  Future<void> saveUserData(Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  /// جلب بيانات المستخدم
  Future<Map<String, dynamic>?> getUserData() async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }
}
