import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const background = Color(0xFF181A20); // screen ka main dark background
  static const surface = Color(0xFF1F222A);    // cards, input fields
  static const card = Color(0xFF35383F);       // product image ke piche ka grey box
  static const border = Color(0xFF35383F);     // input aur card border

  // Text
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9E9E9E);
  static const textHint = Color(0xFF757575);

  // Buttons
  static const primary = Colors.white;         // white pill button
  static const onPrimary = Colors.black;       // button ke andar ka text
  static const disabled = Color(0xFF35383F);   // grey disabled button

  // Status
  static const success = Color(0xFF07BD74);
  static const error = Color(0xFFF75555);
  static const warning = Color(0xFFFACC15);

  // Product color swatches (detail screen)
  static const swatchBrown = Color(0xFFA0624A);
  static const swatchBlue = Color(0xFF7A9CC6);
  static const swatchPurple = Color(0xFFB026FF);
  static const swatchGrey = Color(0xFF808080);
  static const swatchTeal = Color(0xFF0FB5A6);
  static const swatchOrange = Color(0xFFFF9F1C);
}