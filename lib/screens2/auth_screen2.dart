import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'main_layout_screen.dart';
import 'package:ai_dietician/services2/firestore_services.dart';
import 'onboarding2_screen.dart';


class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Container(
                child: Stack(
                  children: [

                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.pinkPastel.withOpacity(0.4),
                              AppColors.lightBlue.withOpacity(0.3),
                              Colors.white,
                            ],
                          ),
                        ),
                      ),
                    ),


                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        children: [
                          SizedBox(height: 40),


                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: AppColors.logoGradient,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.lightPurple.withOpacity(0.3),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),

                          SizedBox(height: 20),


                          Text(
                            'AI DIETICIAN',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightPurple,
                              letterSpacing: 1.2,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Your Health Journey Starts Here',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          SizedBox(height: 30),


                          Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                _buildToggleButton('Login', _isLogin),
                                _buildToggleButton('Sign Up', !_isLogin),
                              ],
                            ),
                          ),

                          SizedBox(height: 30),


                          Expanded(
                            child: Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                physics: NeverScrollableScrollPhysics(),
                                child: Column(
                                  children: [
                                    if (!_isLogin)
                                      _buildTextField(
                                        controller: _nameController,
                                        label: 'Full Name',
                                        icon: Icons.person,
                                        validator: _validateName,
                                      ),

                                    if (!_isLogin) SizedBox(height: 15),

                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      icon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: _validateEmail,
                                    ),

                                    SizedBox(height: 15),

                                    _buildTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      icon: Icons.lock,
                                      obscureText: _obscurePassword,
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      validator: _validatePassword,
                                    ),

                                    SizedBox(height: 25),


                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handleSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.lightPurple,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          elevation: 3,
                                        ),
                                        child: _isLoading
                                            ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                            : Text(
                                          _isLogin ? 'Login' : 'Sign Up',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 20),


                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey[300],
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 15),
                                          child: Text(
                                            'Or continue as',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey[300],
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 20),


                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: OutlinedButton(
                                        onPressed: _isLoading ? null : _loginAsGuest,
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: AppColors.lightPurple,
                                            width: 2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          backgroundColor: Colors.white,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              color: AppColors.lightPurple,
                                              size: 20,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Continue as Guest',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.lightPurple,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 15),

                                    // Guest info
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.blue[100]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.blue[700],
                                            size: 18,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Guest mode allows you to try the app without an account. Some features may be limited.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 30),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isLogin = text == 'Login'),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? AppColors.lightPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: AppColors.lightPurple),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.lightPurple, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  String? _validateName(String? value) {
    if (!_isLogin && (value == null || value.isEmpty)) {
      return 'Please enter your name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter email';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Invalid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final firestoreService = FirestoreService();
        final userData = await firestoreService.getUserData();
        final onboardingCompleted =
            userData != null && userData['onboardingCompleted'] == true;
        final hasProfileData = userData != null;

        print('Debug: After login - onboardingCompleted = $onboardingCompleted');
        print('Debug: After login - hasProfileData = $hasProfileData');

        if (onboardingCompleted && hasProfileData) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MainLayout(),
            ),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      } else {

        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );


        if (_nameController.text.trim().isNotEmpty) {
          await userCredential.user!.updateDisplayName(_nameController.text.trim());
        }

        await userCredential.user!
            .updateDisplayName(_nameController.text.trim());
        final firestoreService = FirestoreService();

        await firestoreService.saveUserData({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'uid': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingScreen(),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email already in use';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Try again later';
          break;
        default:
          errorMessage = e.message ?? 'Authentication failed';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginAsGuest() async {
    setState(() => _isLoading = true);

    try {

      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user == null) throw Exception('Guest login failed');


      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'isGuest': true,
        'onboardingCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guest login failed: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to login as guest: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}