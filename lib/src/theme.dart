import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const cream = Color(0xFFF4F1E8);
const creamGlow = Color(0xFFF6E6C8);
const ink = Color(0xFF1A2B22);
const green = Color(0xFF1E4A34);
const forest = Color(0xFF1A5C40);
const forestCard = Color(0xFF206848);
const sage = Color(0xFF6E8A74);
const card = Color(0xFFFBF9F4);
const line = Color(0xFFE4DDD0);
const muted = Color(0xFF5C665E);
const selectedFill = Color(0xFFE7F0E4);
const idleFill = Color(0xFFE7E5DF);
const gold = Color(0xFFE6B325);
const night = Color(0xFF101812);
const nightRaised = Color(0xFF1A231C);
const nightLine = Color(0xFF2C382E);

TextStyle displayStyle({double size = 56, Color color = ink, FontStyle style = FontStyle.normal}) {
  return GoogleFonts.fraunces(
    color: color,
    fontSize: size,
    height: 1.05,
    fontWeight: FontWeight.w500,
    fontStyle: style,
    letterSpacing: -0.8,
  );
}

TextStyle bodyStyle({double size = 16, Color color = muted, FontWeight weight = FontWeight.w400}) {
  return GoogleFonts.sourceSans3(
    color: color,
    fontSize: size,
    height: 1.5,
    fontWeight: weight,
  );
}

ThemeData vaidyaTheme() {
  final body = GoogleFonts.sourceSans3(color: ink);
  final display = GoogleFonts.fraunces(color: ink);
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      surface: card,
      onSurface: ink,
    ),
    dividerColor: line,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink).copyWith(
          headlineLarge: display.copyWith(fontSize: 56, height: 1.05, fontWeight: FontWeight.w500, letterSpacing: -0.8),
          headlineMedium: display.copyWith(fontSize: 44, height: 1.08, fontWeight: FontWeight.w500, letterSpacing: -0.6),
          headlineSmall: display.copyWith(fontSize: 28, height: 1.15, fontWeight: FontWeight.w500),
          titleLarge: display.copyWith(fontSize: 22, fontWeight: FontWeight.w500),
          bodyLarge: body.copyWith(fontSize: 16, height: 1.55, color: muted),
          bodyMedium: body.copyWith(fontSize: 15, height: 1.45, color: ink),
          labelLarge: body.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: bodyStyle(size: 15, color: const Color(0xFF9AA198)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: green)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: pillButtonStyle()),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: pillButtonStyle(filled: false),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: line),
      ),
    ),
  );
}

ButtonStyle pillButtonStyle({bool filled = true, Color background = green, Color foreground = Colors.white}) {
  return ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(filled ? background : Colors.transparent),
    foregroundColor: WidgetStatePropertyAll(filled ? foreground : green),
    elevation: const WidgetStatePropertyAll(0),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
    textStyle: WidgetStatePropertyAll(bodyStyle(size: 15, color: filled ? foreground : green, weight: FontWeight.w600)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
    side: WidgetStatePropertyAll(BorderSide(color: filled ? background : const Color(0xFFD9D3C6))),
  );
}
