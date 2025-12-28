// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_dietician/main.dart';

void main() {
  testWidgets('Splash Screen loads correctly', (WidgetTester tester) async {
    // 1. بناء تطبيقنا
    await tester.pumpWidget( MyApp());

    // 2. التحقق من وجود عناصر شاشة Splash
    expect(find.text('HealthPal'), findsOneWidget);
    expect(find.text('Your Personal Health Companion'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    // 3. التحقق من وجود الأيقونة
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('App has correct theme', (WidgetTester tester) async {
    await tester.pumpWidget( MyApp());

    // التحقق من وجود MaterialApp
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    // التحقق من الثيم
    expect(materialApp.theme!.primaryColor, Color(0xFFE18BE4));
    expect(materialApp.theme!.scaffoldBackgroundColor, Color(0xFFF8F9FF));
  });
}