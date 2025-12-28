import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
class AppColors {

  static const Color pinkPastel = Color(0xFFFCDEE0);
  static const Color lightPurple = Color(0xFFE18BE4);
  static const Color lightGreen = Color(0xFFCEF9A2);
  static const Color lightBlue = Color(0xFFC1E2F5);
  static const Color softPink = Color(0xFFBADEFF);


  static const Color white = Color(0xFFFFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white50 = Color(0x80FFFFFF);


  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);


  static List<Color> get mainGradient => [
    pinkPastel,
    lightBlue,
    lightGreen,
  ];

  static List<Color> get logoGradient => [
    lightPurple,
    softPink,
  ];
}