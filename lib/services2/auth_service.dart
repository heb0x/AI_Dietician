
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login with email and password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Create new account with email and password
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Password is too weak');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email is already registered');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format');
      } else {
        throw Exception('Registration failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // For web platform
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      }

      // For mobile platforms
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception('Google sign in failed: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred during Google sign in: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email');
      } else {
        throw Exception('Failed to send reset email: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
        await user.reload();
      }
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Update user email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to update email: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to update password: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to send verification email: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Reload user data
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in with Google
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }

      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to sign out: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Please re-authenticate before deleting account');
      }
      throw Exception('Failed to delete account: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Get user info
  String? get userEmail => _auth.currentUser?.email;
  String? get userName => _auth.currentUser?.displayName;
  String? get userPhotoUrl => _auth.currentUser?.photoURL;
  String? get userId => _auth.currentUser?.uid;
  String? get userPhone => _auth.currentUser?.phoneNumber;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Get creation time
  DateTime? get userCreatedAt => _auth.currentUser?.metadata.creationTime;

  // Get last sign in time
  DateTime? get userLastSignIn => _auth.currentUser?.metadata.lastSignInTime;
}