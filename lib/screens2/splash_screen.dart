import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_dietician/screens2/onboarding2_screen.dart';
import 'dart:async';

import 'main_layout_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;


    if (user == null) {
      Navigator.pushReplacementNamed(context, '/auth');
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null || data['onboardingCompleted'] != true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OnboardingScreen()),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => const MainLayout()
      ),
    );
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFCDEE0),
              Color(0xFFC1E2F5),
              Color(0xFFCEF9A2),
            ],
            stops: [0.1, 0.5, 0.9],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFE18BE4).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFCEF9A2).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFE18BE4),
                                    Color(0xFFBADEFF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFE18BE4).withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),


                            Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 50,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),
                      Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  Color(0xFFE18BE4),
                                  Color(0xFFBADEFF),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              'AI DIETICIAN',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Montserrat',
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),

                          SizedBox(height: 10),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Your Personal Health Companion',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 60),
                      Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: _isCheckingAuth
                                ? CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                                : Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),

                          SizedBox(height: 20),

                          Text(
                            _isCheckingAuth
                                ? 'Preparing your experience...'
                                : 'Ready!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 40),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          'Flutter University Project • 2025',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}