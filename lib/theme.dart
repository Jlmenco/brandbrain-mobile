import 'package:flutter/material.dart';

const kPrimaryColor = Color(0xFF6366F1);
const kPrimaryDark = Color(0xFF4338CA);
const kBgColor = Color(0xFFF9FAFB);
const kCardColor = Colors.white;
const kTextColor = Color(0xFF111827);
const kTextSecondary = Color(0xFF6B7280);
const kTextMuted = Color(0xFF9CA3AF);
const kBorderColor = Color(0xFFE5E7EB);
const kSuccessColor = Color(0xFF059669);
const kErrorColor = Color(0xFFEF4444);
const kWarningBg = Color(0xFFFEF9C3);
const kWarningText = Color(0xFF854D0E);

ThemeData appTheme() => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: kPrimaryColor,
      scaffoldBackgroundColor: kBgColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: kCardColor,
        foregroundColor: kTextColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: kTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: kCardColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
