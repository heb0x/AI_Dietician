import 'package:ai_dietician/screens2/main_layout_screen.dart';
import 'package:ai_dietician/screens2/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens2/splash_screen.dart';
import 'screens2/auth_screen2.dart';
import 'screens2/dashboard_screen.dart';
import 'screens2/onboarding2_screen.dart';

import 'firebase_options.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Dietician',
      theme: ThemeData(
        primaryColor: Color(0xFFE18BE4),
        scaffoldBackgroundColor: Color(0xFFF8F9FF),
        fontFamily: 'Poppins',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/auth': (context) => AuthScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/main': (context) => const MainLayout(),
        '/progress': (context) => ProgressScreen(),



      },
      debugShowCheckedModeBanner: false,
    );
  }
}